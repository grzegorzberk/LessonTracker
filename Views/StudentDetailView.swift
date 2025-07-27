//
//  StudentDetailView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct StudentDetailView: View {
    @ObservedObject var viewModel: LessonViewModel
    let student: Student
    @State private var isEditing = false
    
    // Temporary state for editing
    @State private var editName = ""
    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var editPhoneNumber = ""
    @State private var editEmail = ""
    @State private var editBillingId = ""
    @State private var editLessonLink = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(student.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if !student.displayName.isEmpty && student.displayName != (student.name ?? "") {
                        Text(student.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(isEditing ? "Zapisz" : "Edytuj") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                    isEditing.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                if isEditing {
                    Button("Anuluj") {
                        isEditing = false
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Divider()
            
            if isEditing {
                editingView
            } else {
                displayView
            }
            
            Divider()
            
            // Lessons section
            VStack(alignment: .leading, spacing: 10) {
                Text("Lekcje")
                    .font(.headline)
                
                HStack {
                    StatCard(title: "Liczba lekcji", value: "\(student.lessonArray.count)")
                    StatCard(title: "Suma godzin", value: String(format: "%.1f h", student.totalHours))
                    StatCard(title: "Wartość ogółem", value: String(format: "%.2f PLN", student.totalValue))
                    StatCard(title: "Do zapłaty", value: String(format: "%.2f PLN", student.totalUnpaid))
                }
                
                // Recent lessons
                if !student.lessonArray.isEmpty {
                    Text("Ostatnie lekcje")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    ForEach(student.lessonArray.prefix(5), id: \.id) { lesson in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(lesson.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(lesson.duration, specifier: "%.1f") h • \(lesson.hourlyRate, specifier: "%.0f") PLN/h")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            Text(lesson.isPaid ? "Opłacone" : "Nieopłacone")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(lesson.isPaid ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundColor(lesson.isPaid ? .green : .orange)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var displayView: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !student.firstName!.isEmpty || !student.lastName!.isEmpty {
                InfoRow(label: "Imię i nazwisko", value: student.fullName)
            }
            
            if let phone = student.phoneNumber, !phone.isEmpty {
                InfoRow(label: "Telefon", value: phone)
            }
            
            if let email = student.email, !email.isEmpty {
                InfoRow(label: "Email", value: email, isLink: true)
            }
            
            if let billingId = student.billingId, !billingId.isEmpty {
                InfoRow(label: "ID rozliczeń", value: billingId)
            }
            
            if let lessonLink = student.lessonLink, !lessonLink.isEmpty {
                InfoRow(label: "Link do lekcji", value: lessonLink, isLink: true)
            }
        }
    }
    
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Group {
                LabeledTextField(label: "Nazwa wyświetlana", text: $editName)
                LabeledTextField(label: "Imię", text: $editFirstName)
                LabeledTextField(label: "Nazwisko", text: $editLastName)
                LabeledTextField(label: "Telefon", text: $editPhoneNumber)
                LabeledTextField(label: "Email", text: $editEmail)
                LabeledTextField(label: "ID rozliczeń", text: $editBillingId)
                LabeledTextField(label: "Link do lekcji", text: $editLessonLink)
            }
        }
    }
    
    private func startEditing() {
        editName = student.name ?? ""
        editFirstName = student.firstName ?? ""
        editLastName = student.lastName ?? ""
        editPhoneNumber = student.phoneNumber ?? ""
        editEmail = student.email ?? ""
        editBillingId = student.billingId ?? ""
        editLessonLink = student.lessonLink ?? ""
    }
    
    private func saveChanges() {
        viewModel.updateStudent(
            student,
            name: editName,
            firstName: editFirstName,
            lastName: editLastName,
            phoneNumber: editPhoneNumber,
            email: editEmail,
            billingId: editBillingId,
            lessonLink: editLessonLink
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let isLink: Bool
    
    init(label: String, value: String, isLink: Bool = false) {
        self.label = label
        self.value = value
        self.isLink = isLink
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            if isLink {
                if value.contains("@") {
                    // Email link
                    Link(value, destination: URL(string: "mailto:\(value)") ?? URL(string: "")!)
                        .foregroundColor(.blue)
                } else {
                    // Web link
                    Link(value, destination: URL(string: value.hasPrefix("http") ? value : "https://\(value)") ?? URL(string: "")!)
                        .foregroundColor(.blue)
                }
            } else {
                Text(value)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
    }
}

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}