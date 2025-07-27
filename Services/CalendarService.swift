//
//  CalendarService.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
@preconcurrency import EventKit
import CoreData
import AppKit

@MainActor
final class CalendarService {
    static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    private var calendarAccessGranted = false
    
    // Identyfikator kalendarza, w którym będą zapisywane zajęcia
    private var lessonCalendarId: String? {
        get { UserDefaults.standard.string(forKey: "lessonCalendarId") }
        set { UserDefaults.standard.set(newValue, forKey: "lessonCalendarId") }
    }
    
    private init() {} // Prywatny inicjalizator dla singleton
    
    // Inicjalizacja i prośba o dostęp do kalendarza
    func requestAccess() async -> Bool {
        // Najpierw sprawdzamy aktualny status autoryzacji
        let currentStatus = checkCalendarAuthorizationStatus()
        print("Aktualny status autoryzacji kalendarza: \(currentStatus.rawValue)")
        
        // Jeśli już mamy dostęp, od razu zwracamy true
        if currentStatus == .fullAccess || currentStatus == .authorized {
            calendarAccessGranted = true
            print("Dostęp do kalendarza już przyznany")
            return true
        }
        
        // Jeśli dostęp został odrzucony, informujemy użytkownika
        if currentStatus == .denied || currentStatus == .restricted {
            print("Dostęp do kalendarza został odrzucony. Otwórz Ustawienia systemowe > Prywatność i bezpieczeństwo > Kalendarz, aby zmienić uprawnienia.")
            
            // Otwórz preferencje systemowe
            DispatchQueue.main.async {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            return false
        }
        
        print("Proszę o dostęp do kalendarza...")
        
        // Używamy odpowiedniej metody w zależności od wersji macOS
        if #available(macOS 14.0, *) {
            // Dla macOS 14+ używamy nowszej metody
            return await withCheckedContinuation { continuation in
                eventStore.requestFullAccessToEvents { [weak self] granted, error in
                    if let error = error {
                        print("Błąd dostępu do kalendarza: \(error)")
                    }
                    
                    print("Dostęp do kalendarza: \(granted ? "przyznany" : "odrzucony")")
                    self?.calendarAccessGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        } else {
            // Dla starszych wersji macOS
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    if let error = error {
                        print("Błąd dostępu do kalendarza: \(error)")
                    }
                    
                    print("Dostęp do kalendarza: \(granted ? "przyznany" : "odrzucony")")
                    self?.calendarAccessGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // Pobierz dostępne kalendarze użytkownika
    var availableCalendars: [EKCalendar] {
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }
    
    // Ustaw domyślny kalendarz do zapisywania zajęć
    func setDefaultCalendar(_ calendar: EKCalendar) {
        lessonCalendarId = calendar.calendarIdentifier
    }
    
    // Pobierz domyślny kalendarz (lub pierwszy dostępny, jeśli nie wybrano)
    private func getDefaultCalendar() -> EKCalendar? {
        if let id = lessonCalendarId,
           let calendar = eventStore.calendar(withIdentifier: id) {
            return calendar
        }
        return availableCalendars.first
    }
    
    // Dodaj lekcję do kalendarza systemowego
    func addLessonToCalendar(lesson: Lesson) async -> String? {
        guard await requestAccess(), let calendar = getDefaultCalendar() else {
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        
        // Ustaw podstawowe dane wydarzenia
        event.title = "Lekcja: \(lesson.student?.name ?? "Nieznany uczeń")"
        if let student = lesson.student, let link = student.lessonLink, !link.isEmpty {
            event.notes = "Link do zajęć: \(link)"
            event.url = URL(string: link)
        }
        
        // Ustaw datę i czas trwania
        guard let startDate = lesson.date else { return nil }
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(lesson.duration * 3600) // duration jest w godzinach
        
        // Dodaj przypomnienie 15 minut przed zajęciami
        let alarm = EKAlarm(relativeOffset: -900) // 15 minut przed
        event.addAlarm(alarm)
        
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Błąd zapisywania wydarzenia w kalendarzu: \(error)")
            return nil
        }
    }
    
    // Aktualizuj istniejące wydarzenie w kalendarzu
    func updateLessonInCalendar(lesson: Lesson) async -> Bool {
        guard let eventId = lesson.calendarEventId,
              let event = eventStore.event(withIdentifier: eventId) else {
            return false
        }
        
        // Aktualizuj dane wydarzenia
        event.title = "Lekcja: \(lesson.student?.name ?? "Nieznany uczeń")"
        if let student = lesson.student, let link = student.lessonLink, !link.isEmpty {
            event.notes = "Link do zajęć: \(link)"
            event.url = URL(string: link)
        }
        
        // Ustaw datę i czas trwania
        guard let startDate = lesson.date else { return false }
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(lesson.duration * 3600)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Błąd aktualizacji wydarzenia w kalendarzu: \(error)")
            return false
        }
    }
    
    // Usuń wydarzenie z kalendarza
    func removeLessonFromCalendar(eventId: String) async -> Bool {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            return false
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            return true
        } catch {
            print("Błąd usuwania wydarzenia z kalendarza: \(error)")
            return false
        }
    }
    
    // Pobierz nadchodzące wydarzenia z kalendarza (do wyświetlenia w aplikacji)
    func fetchUpcomingLessons(daysAhead: Int = 7) async -> [EKEvent] {
        guard await requestAccess() else {
            return []
        }
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: startDate) ?? startDate
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [getDefaultCalendar()].compactMap { $0 }
        )
        
        return eventStore.events(matching: predicate)
            .filter { $0.title?.contains("Lekcja") == true }
    }
    
    func checkCalendarAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
}
