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
    @State private var searchText = ""
    @State private var showAddStudentSheet = false
    @State private var showStudentDetailSheet = false
    @State private var selectedStudent: Student? = nil
    
    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return viewModel.students
        } else {
            return viewModel.students.filter { student in
                (student.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (student.firstName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (student.lastName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (student.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Wyszukaj ucznia...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                Button(action: {
                    showAddStudentSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Dodaj ucznia")
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.controlBackgroundColor)))
            .padding([.horizontal, .top])
            
            if filteredStudents.isEmpty {
                VStack {
                    Spacer()
                    
                    if searchText.isEmpty {
                        Text("Brak uczniów do wyświetlenia")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button("Dodaj pierwszego ucznia") {
                            showAddStudentSheet = true
                        }
                        .padding(.top)
                    } else {
                        Text("Brak wyników dla '\(searchText)'")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredStudents, id: \.id) { student in
                        StudentRowView(
                            student: student,
                            lessons: lessonsForStudent(student),
                            onDelete: {
                                studentToDelete = student
                                showingDeleteAlert = true
                            },
                            onTap: {
                                selectedStudent = student
                                showStudentDetailSheet = true
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedStudent = student
                            showStudentDetailSheet = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.fetchStudents()
            viewModel.fetchLessons()
        }
        .sheet(isPresented: $showAddStudentSheet) {
            AddStudentView(viewModel: viewModel)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showStudentDetailSheet, onDismiss: {
            viewModel.fetchStudents() // Odśwież dane po zamknięciu szczegółów
        }) {
            if let student = selectedStudent {
                StudentDetailView(viewModel: viewModel, student: student)
                    .interactiveDismissDisabled(false)
            }
        }
        .alert("Usunąć ucznia?", isPresented: $showingDeleteAlert) {
            Button("Anuluj", role: .cancel) {}
            Button("Usuń", role: .destructive) {
                if let student = studentToDelete {
                    Task {
                        await viewModel.deleteStudent(student: student)
                    }
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
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar z inicjałami
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 50, height: 50)
                
                Text(student.initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(student.fullName)
                    .font(.headline)
                
                HStack(spacing: 15) {
                    if let phoneNumber = student.phoneNumber, !phoneNumber.isEmpty {
                        Label(phoneNumber, systemImage: "phone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let email = student.email, !email.isEmpty {
                        Label(email, systemImage: "envelope")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Liczba lekcji: \(lessons.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Suma godzin: \(totalHours, specifier: "%.1f") h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Wartość: \(totalValue, specifier: "%.2f") PLN")
                    .font(.subheadline)
                
                if totalUnpaid > 0 {
                    Text("Nieopłacone: \(totalUnpaid, specifier: "%.2f") PLN")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    var totalHours: Double {
        lessons.reduce(0) { $0 + $1.duration }
    }
    
    var totalValue: Double {
        lessons.reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
    
    var totalUnpaid: Double {
        lessons.filter { !$0.isPaid }.reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
}
