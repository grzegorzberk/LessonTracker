//
//  StudentListView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct StudentListView: View {
    @ObservedObject var viewModel: LessonViewModel
    @State private var newStudentName = ""
    @State private var showingDeleteAlert = false
    @State private var studentToDelete: Student? = nil
    @State private var showingAddStudentSheet = false
    @State private var selectedStudent: Student? = nil
    @State private var showingStudentDetail = false
    
    var body: some View {
        VStack {
            HStack {
                TextField("Imię i nazwisko nowego ucznia", text: $newStudentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                
                Button("Dodaj ucznia") {
                    if !newStudentName.isEmpty {
                        viewModel.addStudent(name: newStudentName)
                        newStudentName = ""
                    }
                }
                .disabled(newStudentName.isEmpty)
                
                Button("Dodaj szczegółowo") {
                    showingAddStudentSheet = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding([.horizontal, .top])
            
            if viewModel.students.isEmpty {
                VStack {
                    Spacer()
                    Text("Brak uczniów do wyświetlenia")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.students, id: \.id) { student in
                        StudentRowView(
                            student: student,
                            lessons: lessonsForStudent(student),
                            onDelete: {
                                studentToDelete = student
                                showingDeleteAlert = true
                            },
                            onTap: {
                                selectedStudent = student
                                showingStudentDetail = true
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.fetchStudents()
            viewModel.fetchLessons()
        }
        .sheet(isPresented: $showingAddStudentSheet) {
            AddStudentView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingStudentDetail) {
            if let student = selectedStudent {
                StudentDetailView(viewModel: viewModel, student: student)
            }
        }
        .alert("Usunąć ucznia?", isPresented: $showingDeleteAlert) {
            Button("Anuluj", role: .cancel) {}
            Button("Usuń", role: .destructive) {
                if let student = studentToDelete {
                    viewModel.deleteStudent(student: student)
                }
            }
        } message: {
            if let student = studentToDelete {
                Text("Czy na pewno chcesz usunąć ucznia \(student.name ?? "") oraz wszystkie jego lekcje? Tej operacji nie można cofnąć.")
            }
        }
    }
    
    private func lessonsForStudent(_ student: Student) -> [Lesson] {
        guard let studentLessons = student.lessons as? Set<Lesson> else { return [] }
        return Array(studentLessons).sorted { $0.date! > $1.date! }
    }
}

struct StudentRowView: View {
    let student: Student
    let lessons: [Lesson]
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let email = student.email, !email.isEmpty {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let phone = student.phoneNumber, !phone.isEmpty {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Lekcje: \(lessons.count)")
                        Text("Godziny: \(totalHours, specifier: "%.1f") h")
                        Text("Wartość: \(totalValue, specifier: "%.2f") PLN")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var totalHours: Double {
        lessons.reduce(0) { $0 + $1.duration }
    }
    
    var totalValue: Double {
        lessons.reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
}
