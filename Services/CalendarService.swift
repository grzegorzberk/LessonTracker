//
//  CalendarService.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import EventKit
import SwiftUI

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        let status = await eventStore.requestFullAccessToEvents()
        await MainActor.run {
            authorizationStatus = status
        }
        return status == .fullAccess
    }
    
    @MainActor
    func addLessonToCalendar(lesson: Lesson, student: Student) async -> Bool {
        guard authorizationStatus == .fullAccess else {
            print("Brak dostępu do kalendarza")
            return false
        }
        
        guard let lessonDate = lesson.date else {
            print("Brak daty lekcji")
            return false
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Lekcja - \(student.displayName)"
        event.startDate = lessonDate
        event.endDate = Calendar.current.date(byAdding: .minute, value: Int(lesson.duration * 60), to: lessonDate) ?? lessonDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Dodaj szczegóły w notatce
        var notes = "Czas trwania: \(lesson.duration) h\nStawka godzinowa: \(lesson.hourlyRate) PLN"
        
        if let email = student.email, !email.isEmpty {
            notes += "\nEmail: \(email)"
        }
        
        if let phone = student.phoneNumber, !phone.isEmpty {
            notes += "\nTelefon: \(phone)"
        }
        
        if let link = student.lessonLink, !link.isEmpty {
            notes += "\nLink do zajęć: \(link)"
        }
        
        event.notes = notes
        
        // Dodaj przypomnienie 15 minut przed
        let alarm = EKAlarm(relativeOffset: -15 * 60) // 15 minut w sekundach
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Lekcja dodana do kalendarza")
            return true
        } catch {
            print("Błąd zapisywania wydarzenia do kalendarza: \(error)")
            return false
        }
    }
    
    func getUpcomingLessons(for student: Student? = nil, limit: Int = 10) -> [EKEvent] {
        guard authorizationStatus == .fullAccess else { return [] }
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? Date()
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        var filteredEvents = events.filter { event in
            return event.title.contains("Lekcja")
        }
        
        if let student = student {
            filteredEvents = filteredEvents.filter { event in
                return event.title.contains(student.displayName)
            }
        }
        
        return Array(filteredEvents.prefix(limit))
    }
    
    func deleteLessonFromCalendar(eventId: String) -> Bool {
        guard authorizationStatus == .fullAccess else { return false }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            print("Nie znaleziono wydarzenia o podanym ID")
            return false
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("Wydarzenie usunięte z kalendarza")
            return true
        } catch {
            print("Błąd usuwania wydarzenia z kalendarza: \(error)")
            return false
        }
    }
}