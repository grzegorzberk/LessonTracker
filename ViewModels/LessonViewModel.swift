//
//  LessonViewModel.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import CoreData
import SwiftUI
import EventKit

class LessonViewModel: ObservableObject {
    private let viewContext = PersistenceController.shared.container.viewContext
    @Published var students: [Student] = []
    @Published var lessons: [Lesson] = []
    @StateObject private var calendarService = CalendarService()
    
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
    
    func addStudent(name: String, firstName: String = "", lastName: String = "", phoneNumber: String = "", email: String = "", billingId: String = "", lessonLink: String = "") {
        let newStudent = Student(context: viewContext)
        newStudent.id = UUID()
        newStudent.name = name
        newStudent.firstName = firstName
        newStudent.lastName = lastName
        newStudent.phoneNumber = phoneNumber
        newStudent.email = email
        newStudent.billingId = billingId
        newStudent.lessonLink = lessonLink
        
        PersistenceController.shared.save()
        fetchStudents()
    }
    
    func updateStudent(_ student: Student, name: String, firstName: String, lastName: String, phoneNumber: String, email: String, billingId: String, lessonLink: String) {
        student.name = name
        student.firstName = firstName
        student.lastName = lastName
        student.phoneNumber = phoneNumber
        student.email = email
        student.billingId = billingId
        student.lessonLink = lessonLink
        
        PersistenceController.shared.save()
        fetchStudents()
    }
    
    func addLesson(studentId: UUID, date: Date, duration: Double, hourlyRate: Double, addToCalendar: Bool = false) {
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
        
        // Dodaj do kalendarza jeśli żądane
        if addToCalendar {
            Task { @MainActor in
                if await calendarService.requestAccess() {
                    await calendarService.addLessonToCalendar(lesson: newLesson, student: student)
                }
            }
        }
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
    
    // MARK: - Calendar Integration
    
    var calendarServiceInstance: CalendarService {
        return calendarService
    }
    
    func requestCalendarAccess() async -> Bool {
        return await calendarService.requestAccess()
    }
    
    func getUpcomingLessons(for student: Student? = nil) -> [EKEvent] {
        return calendarService.getUpcomingLessons(for: student)
    }
}
