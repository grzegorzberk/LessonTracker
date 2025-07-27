//
//  EditLessonView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct EditLessonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LessonViewModel
    let lesson: Lesson
    
    @State private var selectedStudentId: UUID?
    @State private var date = Date()
    @State private var duration: Double = 1.0
    @State private var hourlyRate: Double = 50.0
    @State private var notes = ""
    @State private var isPaid = false
    
    init(viewModel: LessonViewModel, lesson: Lesson) {
        self.viewModel = viewModel
        self.lesson = lesson
        
        // Inicjalizuj wartości z istniejącej lekcji
        _selectedStudentId = State(initialValue: lesson.student?.id)
        _date = State(initialValue: lesson.date ?? Date())
        _duration = State(initialValue: lesson.duration)
        _hourlyRate = State(initialValue: lesson.hourlyRate)
        _notes = State(initialValue: lesson.notes ?? "")
        _isPaid = State(initialValue: lesson.isPaid)
    }
    
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
                Text("Edytuj lekcję")
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
                            Text("Brak uczniów w systemie.")
                                .foregroundColor(.red)
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
                    
                    // Status płatności
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status płatności")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("Opłacone", isOn: $isPaid)
                            .toggleStyle(.switch)
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
                
                Button("Zapisz zmiany") {
                    if let studentId = selectedStudentId {
                        Task {
                            await viewModel.updateLesson(
                                lesson: lesson,
                                studentId: studentId,
                                date: date,
                                duration: duration,
                                hourlyRate: hourlyRate,
                                notes: notes
                            )
                            
                            if isPaid != lesson.isPaid {
                                viewModel.toggleLessonPaid(lesson: lesson)
                            }
                            
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
    }
}
