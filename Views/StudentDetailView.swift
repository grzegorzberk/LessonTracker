//
//  StudentDetailView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct StudentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LessonViewModel
    @State var student: Student
    
    @State private var name: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var billingId: String
    @State private var lessonLink: String
    @State private var isEditing = false
    
    init(viewModel: LessonViewModel, student: Student) {
        self.viewModel = viewModel
        self.student = student
        
        // Inicjalizacja stanu z danymi studenta
        _name = State(initialValue: student.name ?? "")
        _firstName = State(initialValue: student.firstName ?? "")
        _lastName = State(initialValue: student.lastName ?? "")
        _phoneNumber = State(initialValue: student.phoneNumber ?? "")
        _email = State(initialValue: student.email ?? "")
        _billingId = State(initialValue: student.billingId ?? "")
        _lessonLink = State(initialValue: student.lessonLink ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Nagłówek z inicjałami
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 70, height: 70)
                    
                    Text(student.initials)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(student.fullName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if !isEditing, student.hasContactInfo {
                        HStack {
                            if let phone = student.phoneNumber, !phone.isEmpty {
                                Label(phone, systemImage: "phone")
                                    .foregroundColor(.secondary)
                            }
                            
                            if let email = student.email, !email.isEmpty {
                                Label(email, systemImage: "envelope")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(isEditing ? "Zapisz" : "Edytuj") {
                    if isEditing {
                        viewModel.updateStudent(
                            student: student,
                            name: name,
                            firstName: firstName,
                            lastName: lastName,
                            phone: phoneNumber,
                            email: email,
                            billingId: billingId,
                            lessonLink: lessonLink
                        )
                    }
                    isEditing.toggle()
                }
                .keyboardShortcut(.return, modifiers: .command)
                
                if let link = student.lessonLink, !link.isEmpty {
                    Button(action: {
                        viewModel.openLessonLink(student: student)
                    }) {
                        Label("Dołącz do lekcji", systemImage: "video")
                    }
                    .disabled(isEditing)
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            if isEditing {
                Form {
                    Section(header: Text("Podstawowe informacje").font(.headline)) {
                        TextField("Imię", text: $firstName)
                        TextField("Nazwisko", text: $lastName)
                        TextField("Pełna nazwa (wyświetlana)", text: $name)
                    }
                    
                    Section(header: Text("Dane kontaktowe").font(.headline)) {
                        TextField("Telefon", text: $phoneNumber)
                        TextField("Email", text: $email)
                    }
                    
                    Section(header: Text("Informacje dodatkowe").font(.headline)) {
                        TextField("ID rozliczeniowe", text: $billingId)
                        TextField("Link do zajęć", text: $lessonLink)
                    }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Sekcja z podsumowaniem
                        GroupBox(label: Label("Podsumowanie", systemImage: "info.circle")) {
                            VStack(alignment: .leading, spacing: 10) {
                                StudentStatRow(title: "Liczba lekcji", value: "\(student.lessonArray.count)")
                                StudentStatRow(title: "Łączna liczba godzin", value: String(format: "%.1f h", student.totalHours))
                                StudentStatRow(title: "Wartość lekcji", value: String(format: "%.2f PLN", student.totalValue))
                                StudentStatRow(title: "Nieopłacone", value: String(format: "%.2f PLN", student.totalUnpaid))
                            }
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal)
                        
                        // Szczegółowe dane ucznia
                        GroupBox(label: Label("Dane ucznia", systemImage: "person.fill")) {
                            VStack(alignment: .leading, spacing: 10) {
                                if let firstName = student.firstName, !firstName.isEmpty {
                                    InfoRow(label: "Imię", value: firstName)
                                }
                                if let lastName = student.lastName, !lastName.isEmpty {
                                    InfoRow(label: "Nazwisko", value: lastName)
                                }
                                if let phone = student.phoneNumber, !phone.isEmpty {
                                    InfoRow(label: "Telefon", value: phone, iconName: "phone")
                                }
                                if let email = student.email, !email.isEmpty {
                                    InfoRow(label: "Email", value: email, iconName: "envelope")
                                }
                                if let billingId = student.billingId, !billingId.isEmpty {
                                    InfoRow(label: "ID rozliczeniowe", value: billingId, iconName: "creditcard")
                                }
                                if let link = student.lessonLink, !link.isEmpty {
                                    InfoRow(label: "Link do zajęć", value: link, iconName: "link", isLink: true) {
                                        viewModel.openLessonLink(student: student)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal)
                        
                        // Sekcja z nadchodzącymi lekcjami
                        if !student.upcomingLessons.isEmpty {
                            GroupBox(label: Label("Nadchodzące lekcje", systemImage: "calendar")) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(student.upcomingLessons.prefix(5), id: \.id) { lesson in
                                        HStack {
                                            Text(lesson.formattedDate)
                                                .font(.subheadline)
                                            Spacer()
                                            Text("\(lesson.duration, specifier: "%.1f") h")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sekcja z nieopłaconymi lekcjami
                        if !student.unpaidLessons.isEmpty {
                            GroupBox(label: Label("Nieopłacone lekcje", systemImage: "dollarsign.circle")) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(student.unpaidLessons.prefix(5), id: \.id) { lesson in
                                        HStack {
                                            Text(lesson.formattedDate)
                                                .font(.subheadline)
                                            Spacer()
                                            Text("\(lesson.totalValue, specifier: "%.2f") PLN")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct StudentStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var iconName: String? = nil
    var isLink: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .trailing)
            
            if isLink {
                Button(action: { action?() }) {
                    HStack {
                        if let iconName = iconName {
                            Image(systemName: iconName)
                                .foregroundColor(.blue)
                        }
                        Text(value)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                HStack {
                    if let iconName = iconName {
                        Image(systemName: iconName)
                            .foregroundColor(.secondary)
                    }
                    Text(value)
                }
            }
            
            Spacer()
        }
    }
}
