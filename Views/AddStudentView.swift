//
//  AddStudentView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct AddStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LessonViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var billingId = ""
    @State private var lessonLink = ""
    
    var formattedName: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedFirst.isEmpty && !trimmedLast.isEmpty {
            return "\(trimmedFirst) \(trimmedLast)"
        } else if !trimmedFirst.isEmpty {
            return trimmedFirst
        } else if !trimmedLast.isEmpty {
            return trimmedLast
        } else {
            return ""
        }
    }
    
    var isFormValid: Bool {
        !formattedName.isEmpty
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
                Text("Dodaj nowego ucznia")
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Podstawowe informacje")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Imię")
                                    .frame(width: 100, alignment: .trailing)
                                TextField("np. Jan", text: $firstName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            HStack {
                                Text("Nazwisko")
                                    .frame(width: 100, alignment: .trailing)
                                TextField("np. Kowalski", text: $lastName)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dane kontaktowe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Telefon")
                                    .frame(width: 100, alignment: .trailing)
                                TextField("np. +48 123 456 789", text: $phoneNumber)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            HStack {
                                Text("Email")
                                    .frame(width: 100, alignment: .trailing)
                                TextField("np. jan@example.com", text: $email)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor).opacity(0.5)))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Informacje dodatkowe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("ID rozliczeniowe")
                                    .frame(width: 100, alignment: .trailing)
                                TextField("opcjonalne", text: $billingId)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            HStack {
                                Text("Link do zajęć")
                                    .frame(width: 100, alignment: .trailing)
                                TextField("np. https://meet.google.com/...", text: $lessonLink)
                                    .textFieldStyle(.roundedBorder)
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
                
                Button("Dodaj ucznia") {
                    viewModel.addStudent(
                        name: formattedName,
                        firstName: firstName,
                        lastName: lastName,
                        phone: phoneNumber,
                        email: email,
                        billingId: billingId,
                        lessonLink: lessonLink
                    )
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(!isFormValid)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            }
            .frame(width: 500, height: 600)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
            .onTapGesture {
                // Nie rób nic - to zapobiega zamknięciu gdy klikniesz na formularz
            }
        }
    }
}
