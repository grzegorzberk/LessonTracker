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
}
