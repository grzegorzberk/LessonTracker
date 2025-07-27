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
    @State private var hourlyRate: Double = 60.0
    @State private var showAddStudentAlert = false
    @State private var newStudentName = ""
    @State private var addToCalendar = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dodaj nową lekcję")
                .font(.title)
                .padding(.top)
            
            Form {
                if viewModel.students.isEmpty {
                    Text("Brak uczniów. Dodaj ucznia, aby kontynuować.")
                        .foregroundColor(.red)
                } else {
                    Picker("Uczeń", selection: $selectedStudentId) {
                        Text("Wybierz ucznia").tag(nil as UUID?)
                        ForEach(viewModel.students, id: \.id) { student in
                            Text(student.displayName).tag(student.id as UUID?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Button("Dodaj nowego ucznia") {
                    showAddStudentAlert = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
                
                DatePicker("Data i godzina", selection: $date)
                
                HStack {
                    Text("Czas trwania (h)")
                    Slider(value: $duration, in: 0.5...3.0, step: 0.5) {
                        Text("Czas trwania")
                    }
                    Text("\(duration, specifier: "%.1f") h")
                }
                
                HStack {
                    Text("Stawka godzinowa")
                    TextField("", value: $hourlyRate, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("PLN/h")
                }
                
                HStack {
                    Text("Razem:")
                    Text("\(hourlyRate * duration, specifier: "%.2f") PLN")
                        .bold()
                }
                
                Toggle("Dodaj do kalendarza", isOn: $addToCalendar)
            }
            .padding()
            
            HStack {
                Button("Anuluj") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Zapisz") {
                    if let studentId = selectedStudentId {
                        viewModel.addLesson(
                            studentId: studentId,
                            date: date,
                            duration: duration,
                            hourlyRate: hourlyRate,
                            addToCalendar: addToCalendar
                        )
                        dismiss()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(selectedStudentId == nil)
            }
            .padding()
        }
        .frame(width: 400, height: 400)
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
    }
}
