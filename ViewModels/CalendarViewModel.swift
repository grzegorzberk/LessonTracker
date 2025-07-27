//
//  CalendarViewModel.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
@preconcurrency import EventKit
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {
    private let calendarService = CalendarService.shared
    private let lessonViewModel = LessonViewModel()
    
    @Published var availableCalendars: [EKCalendar] = []
    @Published var selectedCalendarId: String?
    @Published var upcomingEvents: [EKEvent] = []
    @Published var calendarAccessGranted = false
    @Published var selectedDate = Date()
    @Published var lessons: [Lesson] = []
    
    init() {
        Task {
            await loadCalendarData()
        }
    }
    
    func loadCalendarData() async -> Bool {
        print("Ładowanie danych kalendarza...")
        calendarAccessGranted = await calendarService.requestAccess()
        print("Dostęp do kalendarza: \(calendarAccessGranted)")
        
        if calendarAccessGranted {
            availableCalendars = calendarService.availableCalendars
            print("Dostępne kalendarze: \(availableCalendars.count)")
            
            selectedCalendarId = UserDefaults.standard.string(forKey: "lessonCalendarId")
            if selectedCalendarId == nil, let firstCalendar = availableCalendars.first {
                // Automatycznie wybierz pierwszy dostępny kalendarz
                setSelectedCalendar(firstCalendar)
            }
            
            await fetchUpcomingEvents()
            return true
        } else {
            print("Brak dostępu do kalendarza")
            return false
        }
    }
    
    func setSelectedCalendar(_ calendar: EKCalendar) {
        selectedCalendarId = calendar.calendarIdentifier
        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: "lessonCalendarId")
        calendarService.setDefaultCalendar(calendar)
        
        Task {
            await fetchUpcomingEvents()
        }
    }
    
    func fetchUpcomingEvents() async {
        upcomingEvents = await calendarService.fetchUpcomingLessons(daysAhead: 14)
    }
    
    func fetchLessonsForSelectedDate() {
        let calendar = Calendar.current
        
        // Początek i koniec wybranego dnia
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedDate),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) else {
            lessons = []
            return
        }
        
        let request = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            lessons = try PersistenceController.shared.container.viewContext.fetch(request)
        } catch {
            print("Błąd pobierania lekcji dla wybranego dnia: \(error)")
            lessons = []
        }
    }
    
    func groupLessonsByDay(for date: Date) -> [Date: [Lesson]] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let request = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        
        var groupedLessons: [Date: [Lesson]] = [:]
        
        do {
            let lessons = try PersistenceController.shared.container.viewContext.fetch(request)
            for lesson in lessons {
                guard let lessonDate = lesson.date else { continue }
                let startOfDay = calendar.startOfDay(for: lessonDate)
                
                if groupedLessons[startOfDay] == nil {
                    groupedLessons[startOfDay] = []
                }
                groupedLessons[startOfDay]?.append(lesson)
            }
        } catch {
            print("Błąd pobierania lekcji dla miesiąca: \(error)")
        }
        
        return groupedLessons
    }
    
    func getWeekDays() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Usunięto nieużywaną zmienną dayOfWeek
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        
        let days = (weekdays.lowerBound..<weekdays.upperBound).compactMap { weekday -> Date? in
            let daysFromStartOfWeek = weekday - calendar.firstWeekday
            return calendar.date(byAdding: .day, value: daysFromStartOfWeek, to: today)
        }
        
        return days
    }
    
    func getMonthDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let startDayOfWeek = calendar.component(.weekday, from: startOfMonth)
        let endDayOfWeek = calendar.component(.weekday, from: endOfMonth)
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)!.count
        
        var days: [Date] = []
        
        // Dodaj dni z poprzedniego miesiąca, żeby wypełnić początek tygodnia
        for day in 0..<(startDayOfWeek - calendar.firstWeekday) {
            if let date = calendar.date(byAdding: .day, value: -day - 1, to: startOfMonth) {
                days.insert(date, at: 0)
            }
        }
        
        // Dodaj dni bieżącego miesiąca
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Dodaj dni z następnego miesiąca, żeby wypełnić koniec tygodnia
        let remainingDays = (7 - endDayOfWeek + calendar.firstWeekday - 1) % 7
        for day in 0..<remainingDays {
            if let date = calendar.date(byAdding: .day, value: day + 1, to: endOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}
