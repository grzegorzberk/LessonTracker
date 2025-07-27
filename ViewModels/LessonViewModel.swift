//
//  LessonViewModel.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import CoreData
import SwiftUI

class LessonViewModel: ObservableObject {
    private let viewContext = PersistenceController.shared.container.viewContext
    @Published var students: [Student] = []
    @Published var lessons: [Lesson] = []
    
    init() {
        fetchStudents()
        fetchLessons()
    }
    
    func fetchStudents() {
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Student.name, ascending: true)]
        
        do {
            students = try viewContext.fetch(request)
        } catch {
            print("Błąd pobierania studentów: \(error)")
        }
    }
    
    func fetchLessons() {
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: false)]
        
        do {
            lessons = try viewContext.fetch(request)
        } catch {
            print("Błąd pobierania lekcji: \(error)")
        }
    }
    
    func fetchLessonsByMonth(year: Int, month: Int) -> [Lesson] {
        let calendar = Calendar.current
        
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return []
        }
        
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Błąd pobierania lekcji: \(error)")
            return []
        }
    }
    
    func addStudent(name: String) {
        let newStudent = Student(context: viewContext)
        newStudent.id = UUID()
        newStudent.name = name
        
        PersistenceController.shared.save()
        fetchStudents()
    }
    
    func addLesson(studentId: UUID, date: Date, duration: Double, hourlyRate: Double) {
        guard let student = students.first(where: { $0.id == studentId }) else { return }
        
        let newLesson = Lesson(context: viewContext)
        newLesson.id = UUID()
        newLesson.date = date
        newLesson.duration = duration
        newLesson.hourlyRate = hourlyRate
        newLesson.isPaid = false
        newLesson.student = student
        
        PersistenceController.shared.save()
        fetchLessons()
    }
    
    func toggleLessonPaid(lesson: Lesson) {
        lesson.isPaid.toggle()
        PersistenceController.shared.save()
        fetchLessons()
    }
    
    func deleteLesson(lesson: Lesson) {
        viewContext.delete(lesson)
        PersistenceController.shared.save()
        fetchLessons()
    }
    
    func deleteStudent(student: Student) {
        // Najpierw usuwamy wszystkie lekcje powiązane ze studentem
        if let lessons = student.lessons as? Set<Lesson> {
            lessons.forEach { viewContext.delete($0) }
        }
        
        viewContext.delete(student)
        PersistenceController.shared.save()
        fetchStudents()
        fetchLessons()
    }
}
