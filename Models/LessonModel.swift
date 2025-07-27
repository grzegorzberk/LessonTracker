//
//  LessonModel.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import CoreData

extension Lesson {
    var formattedDate: String {
        guard let date = self.date else {
            return "Nieznana data"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    var totalValue: Double {
        return self.duration * self.hourlyRate
    }
    
    var isUpcoming: Bool {
        guard let date = self.date else { return false }
        return date > Date()
    }
    
    var isPast: Bool {
        guard let date = self.date else { return false }
        return date < Date()
    }
    
    var lessonStatus: LessonStatus {
        if isPast {
            return isPaid ? .completed : .unpaid
        } else {
            return .upcoming
        }
    }
    
    static func createFetchRequest() -> NSFetchRequest<Lesson> {
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: false)]
        return request
    }
    
    static func fetchLessonsForMonth(year: Int, month: Int, context: NSManagedObjectContext) -> [Lesson] {
        let calendar = Calendar.current
        
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return []
        }
        
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Błąd pobierania lekcji: \(error)")
            return []
        }
    }
    
    static func fetchUpcomingLessons(context: NSManagedObjectContext, days: Int = 7) -> [Lesson] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", now as NSDate, future as NSDate)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Błąd pobierania nadchodzących lekcji: \(error)")
            return []
        }
    }
}

enum LessonStatus {
    case upcoming
    case completed
    case unpaid
    
    var color: String {
        switch self {
        case .upcoming: return "systemBlue"
        case .completed: return "systemGreen"
        case .unpaid: return "systemOrange"
        }
    }
    
    var icon: String {
        switch self {
        case .upcoming: return "calendar"
        case .completed: return "checkmark.circle"
        case .unpaid: return "exclamationmark.circle"
        }
    }
    
    var label: String {
        switch self {
        case .upcoming: return "Nadchodząca"
        case .completed: return "Zakończona"
        case .unpaid: return "Nieopłacona"
        }
    }
}
