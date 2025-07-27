//
//  AddStudentView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct AddStudentView: View {
    @ObservedObject var viewModel: LessonViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var billingId = ""
    @State private var lessonLink = ""
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Podstawowe informacje") {
                    TextField("Nazwa wyświetlana *", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Imię", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Nazwisko", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Kontakt") {
                    TextField("Numer telefonu", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Adres email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Lekcje") {
                    TextField("ID rozliczeń", text: $billingId)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Link do zajęć online", text: $lessonLink)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Nowy uczeń")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        addStudent()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func addStudent() {
        viewModel.addStudent(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            billingId: billingId.trimmingCharacters(in: .whitespacesAndNewlines),
            lessonLink: lessonLink.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dismiss()
    }
}