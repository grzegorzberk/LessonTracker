//
//  AddLessonView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct AddLessonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LessonViewModel
    
    @State private var selectedStudentId: UUID?
    @State private var date = Date()
    @State private var duration: Double = 1.0
    @State private var hourlyRate: Double = 50.0
    @State private var notes = ""
    @State private var addToCalendar = true
    @State private var showAddStudentAlert = false
    @State private var newStudentName = ""
    
    var body: some View {
        ZStack {
            // Tło które można kliknąć żeby zamknąć
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
            // Nagłówek
            HStack {
                Text("Dodaj nową lekcję")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("✕") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.title3)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Formularz
            ScrollView {
                VStack(spacing: 20) {
                    // Wybór ucznia
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Uczeń")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if viewModel.students.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Brak uczniów. Dodaj ucznia, aby kontynuować.")
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(.orange.opacity(0.1)))
                        } else {
                            Picker("Wybierz ucznia", selection: $selectedStudentId) {
                                Text("Wybierz ucznia").tag(nil as UUID?)
                                ForEach(viewModel.students, id: \.id) { student in
                                    Text(student.fullName).tag(student.id as UUID?)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button("+ Dodaj nowego ucznia") {
                            showAddStudentAlert = true
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                    
                    // Data i czas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Termin")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        DatePicker("Data i godzina", 
                                 selection: $date, 
                                 displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                    
                    // Czas trwania i stawka
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Szczegóły finansowe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Czas trwania")
                                    .frame(width: 120, alignment: .trailing)
                                Slider(value: $duration, in: 0.5...3.0, step: 0.5)
                                Text("\(duration, specifier: "%.1f") h")
                                    .frame(width: 50)
                            }
                            
                            HStack {
                                Text("Stawka godzinowa")
                                    .frame(width: 120, alignment: .trailing)
                                TextField("0.00", value: $hourlyRate, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder)
                                Text("PLN/h")
                                    .frame(width: 50)
                            }
                            
                            HStack {
                                Text("Razem")
                                    .frame(width: 120, alignment: .trailing)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(hourlyRate * duration, specifier: "%.2f") PLN")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                    
                    // Notatki
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notatki")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(.textBackgroundColor)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separatorColor), lineWidth: 1)
                            )
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                    
                    // Kalendarz
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Synchronizacja")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if viewModel.calendarAccessGranted {
                            Toggle("Dodaj do kalendarza", isOn: $addToCalendar)
                        } else {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text("Brak dostępu do kalendarza")
                                        .foregroundColor(.orange)
                                    Button("Udziel dostępu") {
                                        Task {
                                            await viewModel.checkCalendarAccess()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                }
                .padding()
            }
            
            Divider()
            
            // Przyciski
            HStack {
                Button("Anuluj") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Zapisz lekcję") {
                    if let studentId = selectedStudentId {
                        Task {
                            await viewModel.addLesson(
                                studentId: studentId,
                                date: date,
                                duration: duration,
                                hourlyRate: hourlyRate,
                                notes: notes
                            )
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.return)
                .disabled(selectedStudentId == nil)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            }
            .frame(width: 650, height: 700)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
            .onTapGesture {
                // Nie rób nic - to zapobiega zamknięciu gdy klikniesz na formularz
            }
        }
        .alert("Dodaj nowego ucznia", isPresented: $showAddStudentAlert) {
            TextField("Imię i nazwisko", text: $newStudentName)
            
            Button("Anuluj", role: .cancel) {}
            
            Button("Dodaj") {
                if !newStudentName.isEmpty {
                    viewModel.addStudent(name: newStudentName)
                    newStudentName = ""
                    
                    // Automatycznie wybieramy nowo dodanego studenta
                    if let newStudent = viewModel.students.last {
                        selectedStudentId = newStudent.id
                    }
                }
            }
        } message: {
            Text("Podaj imię i nazwisko nowego ucznia")
        }
        .onAppear {
            // Sprawdź dostęp do kalendarza przy pierwszym uruchomieniu
            Task {
                await viewModel.checkCalendarAccess()
            }
            
            // Pobierz wartości domyślne dla nowej lekcji
            if viewModel.students.count == 1 {
                selectedStudentId = viewModel.students.first?.id
            }
            
            if let lastLesson = viewModel.lessons.first {
                hourlyRate = lastLesson.hourlyRate
            }
        }
    }
}
