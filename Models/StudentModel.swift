//
//  StudentModel.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import CoreData

extension Student {
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        if !first.isEmpty && !last.isEmpty {
            return "\(first) \(last)"
        } else if !first.isEmpty {
            return first
        } else if !last.isEmpty {
            return last
        } else {
            return name ?? ""
        }
    }
    
    var displayName: String {
        return fullName.isEmpty ? (name ?? "") : fullName
    }
    
    var lessonArray: [Lesson] {
        let set = lessons as? Set<Lesson> ?? []
        return Array(set).sorted { $0.date! > $1.date! }
    }
    
    var totalHours: Double {
        return lessonArray.reduce(0) { $0 + $1.duration }
    }
    
    var totalValue: Double {
        return lessonArray.reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
    
    var totalPaid: Double {
        return lessonArray.filter { $0.isPaid }.reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
    
    var totalUnpaid: Double {
        return totalValue - totalPaid
    }
    
    var unpaidLessons: [Lesson] {
        return lessonArray.filter { !$0.isPaid }
    }
    
    static func createFetchRequest() -> NSFetchRequest<Student> {
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Student.name, ascending: true)]
        return request
    }
}
