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

@MainActor
final class LessonViewModel: ObservableObject {
    private let viewContext = PersistenceController.shared.container.viewContext
    private let calendarService = CalendarService.shared
    
    @Published var students: [Student] = []
    @Published var lessons: [Lesson] = []
    @Published var upcomingLessons: [Lesson] = []
    @Published var calendarAccessGranted = false
    
    init() {
        fetchStudents()
        fetchLessons()
        fetchUpcomingLessons()
        
        Task {
            await checkCalendarAccess()
        }
    }
    
    func checkCalendarAccess() async {
        print("Sprawdzanie dostępu do kalendarza...")
        calendarAccessGranted = await calendarService.requestAccess()
        print("Status dostępu do kalendarza: \(calendarAccessGranted)")
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
    
    func fetchUpcomingLessons() {
        upcomingLessons = Lesson.fetchUpcomingLessons(context: viewContext)
    }
    
    func fetchLessonsByMonth(year: Int, month: Int) async -> [Lesson] {
        return Lesson.fetchLessonsForMonth(year: year, month: month, context: viewContext)
    }
    
    func addStudent(name: String, firstName: String = "", lastName: String = "",
                    phone: String = "", email: String = "",
                    billingId: String = "", lessonLink: String = "") {
        let newStudent = Student(context: viewContext)
        newStudent.id = UUID()
        newStudent.name = name
        newStudent.firstName = firstName
        newStudent.lastName = lastName
        newStudent.phoneNumber = phone
        newStudent.email = email
        newStudent.billingId = billingId
        newStudent.lessonLink = lessonLink
        
        PersistenceController.shared.save()
        fetchStudents()
    }
    
    func updateStudent(student: Student, name: String, firstName: String, lastName: String,
                       phone: String, email: String, billingId: String, lessonLink: String) {
        student.name = name
        student.firstName = firstName
        student.lastName = lastName
        student.phoneNumber = phone
        student.email = email
        student.billingId = billingId
        student.lessonLink = lessonLink
        
        PersistenceController.shared.save()
        fetchStudents()
    }
    
    func addLesson(studentId: UUID, date: Date, duration: Double, hourlyRate: Double, notes: String = "") async {
        guard let student = students.first(where: { $0.id == studentId }) else { 
            print("Nie znaleziono studenta o ID: \(studentId)")
            return 
        }
        
        let newLesson = Lesson(context: viewContext)
        newLesson.id = UUID()
        newLesson.date = date
        newLesson.duration = duration
        newLesson.hourlyRate = hourlyRate
        newLesson.isPaid = false
        newLesson.notes = notes
        newLesson.student = student
        newLesson.syncedWithCalendar = false
        
        PersistenceController.shared.save()
        print("Lekcja została zapisana w Core Data")
        
        fetchLessons()
        fetchUpcomingLessons()
        
        // Dodaj do kalendarza systemowego
        if calendarAccessGranted {
            print("Próba dodania lekcji do kalendarza...")
            if let eventId = await calendarService.addLessonToCalendar(lesson: newLesson) {
                newLesson.calendarEventId = eventId
                newLesson.syncedWithCalendar = true
                PersistenceController.shared.save()
                print("Lekcja została dodana do kalendarza z ID: \(eventId)")
            } else {
                print("Nie udało się dodać lekcji do kalendarza")
            }
        } else {
            print("Brak dostępu do kalendarza - lekcja nie zostanie dodana do kalendarza")
        }
        
        // Wyślij notyfikację o dodaniu nowej lekcji
        NotificationCenter.default.post(name: Notification.Name("NewLesson"), object: nil)
    }
    
    func updateLesson(lesson: Lesson, studentId: UUID, date: Date,
                      duration: Double, hourlyRate: Double, notes: String = "") async {
        guard let student = students.first(where: { $0.id == studentId }) else { return }
        
        lesson.date = date
        lesson.duration = duration
        lesson.hourlyRate = hourlyRate
        lesson.notes = notes
        lesson.student = student
        
        PersistenceController.shared.save()
        fetchLessons()
        fetchUpcomingLessons()
        
        // Aktualizuj w kalendarzu systemowym
        if calendarAccessGranted {
            if lesson.syncedWithCalendar && lesson.calendarEventId != nil {
                if await calendarService.updateLessonInCalendar(lesson: lesson) {
                    // Już zaktualizowano
                } else {
                    // Jeśli aktualizacja się nie powiodła, spróbuj utworzyć nowe wydarzenie
                    if let eventId = await calendarService.addLessonToCalendar(lesson: lesson) {
                        lesson.calendarEventId = eventId
                        lesson.syncedWithCalendar = true
                        PersistenceController.shared.save()
                    }
                }
            } else {
                // Jeśli wcześniej nie było w kalendarzu, dodaj
                if let eventId = await calendarService.addLessonToCalendar(lesson: lesson) {
                    lesson.calendarEventId = eventId
                    lesson.syncedWithCalendar = true
                    PersistenceController.shared.save()
                }
            }
        }
    }
    
    func toggleLessonPaid(lesson: Lesson) {
        lesson.isPaid.toggle()
        PersistenceController.shared.save()
        fetchLessons()
    }
    
    func deleteLesson(lesson: Lesson) async {
        // Jeśli lekcja jest w kalendarzu, usuń ją stamtąd
        if let eventId = lesson.calendarEventId, lesson.syncedWithCalendar {
            _ = await calendarService.removeLessonFromCalendar(eventId: eventId)
        }
        
        viewContext.delete(lesson)
        PersistenceController.shared.save()
        fetchLessons()
        fetchUpcomingLessons()
    }
    
    func deleteStudent(student: Student) async {
        // Najpierw usuwamy wszystkie lekcje powiązane ze studentem
        if let lessons = student.lessons as? Set<Lesson> {
            for lesson in lessons {
                await deleteLesson(lesson: lesson)
            }
        }
        
        viewContext.delete(student)
        PersistenceController.shared.save()
        fetchStudents()
        fetchLessons()
        fetchUpcomingLessons()
    }
    
    // Metody do pracy z kalendarzem
    func syncLessonWithCalendar(lesson: Lesson) async -> Bool {
        if lesson.syncedWithCalendar, let _ = lesson.calendarEventId {
            return await calendarService.updateLessonInCalendar(lesson: lesson)
        } else {
            if let eventId = await calendarService.addLessonToCalendar(lesson: lesson) {
                lesson.calendarEventId = eventId
                lesson.syncedWithCalendar = true
                PersistenceController.shared.save()
                return true
            }
            return false
        }
    }
    
    func removeLessonFromCalendar(lesson: Lesson) async -> Bool {
        if let eventId = lesson.calendarEventId, lesson.syncedWithCalendar {
            let success = await calendarService.removeLessonFromCalendar(eventId: eventId)
            if success {
                lesson.syncedWithCalendar = false
                lesson.calendarEventId = nil
                PersistenceController.shared.save()
            }
            return success
        }
        return false
    }
    
    func openLessonLink(student: Student) {
        guard let linkString = student.lessonLink, 
              !linkString.isEmpty else {
            print("Brak linku do zajęć dla ucznia: \(student.name ?? "nieznany")")
            return
        }
        
        // Sprawdź, czy URL ma odpowiedni protokół
        var urlString = linkString
        if !linkString.lowercased().hasPrefix("http://") && !linkString.lowercased().hasPrefix("https://") {
            urlString = "https://" + linkString
        }
        
        guard let url = URL(string: urlString) else {
            print("Nieprawidłowy URL: \(linkString)")
            return
        }
        
        // Otwórz link w domyślnej przeglądarce
        NSWorkspace.shared.open(url)
        print("Otwarto link: \(url.absoluteString)")
    }
}
