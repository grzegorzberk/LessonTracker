//
//  LessonListView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct LessonListView: View {
    @ObservedObject var viewModel: LessonViewModel
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var searchText = ""
    @State private var showOnlyUnpaid = false
    @State private var selectedLesson: Lesson?
    
    var filteredLessons: [Lesson] {
        viewModel.lessons.filter { lesson in
            let matchesSearch = searchText.isEmpty ||
            (lesson.student?.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (lesson.student?.firstName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (lesson.student?.lastName?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            return showOnlyUnpaid ? !lesson.isPaid && matchesSearch : matchesSearch
        }
    }
    
    var groupedLessons: [(key: Date, value: [Lesson])] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: filteredLessons) { lesson -> Date in
            guard let date = lesson.date else { return Date() }
            return calendar.startOfDay(for: date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Szukaj ucznia...", text: $searchText)
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
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                Toggle("Tylko nieopłacone", isOn: $showOnlyUnpaid)
                
                Spacer()
                
                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Dodaj lekcję")
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.controlBackgroundColor)))
            .padding([.horizontal, .top])
            
            if viewModel.lessons.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Brak lekcji")
                        .font(.title2)
                    
                    Button("Dodaj pierwszą lekcję") {
                        showingAddSheet = true
                    }
                    .padding()
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedLessons, id: \.key) { date, lessons in
                            Section {
                                ForEach(lessons, id: \.id) { lesson in
                                    LessonRow(
                                        lesson: lesson,
                                        viewModel: viewModel,
                                        onEdit: {
                                            selectedLesson = lesson
                                            showingEditSheet = true
                                        }
                                    )
                                    .padding(.horizontal)
                                    
                                    if lesson != lessons.last {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            } header: {
                                LessonSectionHeader(date: date, lessons: lessons)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddLessonView(viewModel: viewModel)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showingEditSheet) {
            if let lesson = selectedLesson {
                EditLessonView(viewModel: viewModel, lesson: lesson)
                    .interactiveDismissDisabled(false)
            }
        }
    }
}

struct LessonSectionHeader: View {
    let date: Date
    let lessons: [Lesson]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter
    }()
    
    private var totalEarnings: Double {
        lessons.reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
    
    private var paidEarnings: Double {
        lessons.filter(\.isPaid).reduce(0) { $0 + ($1.duration * $1.hourlyRate) }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: date).capitalized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(lessons.count) lekcji")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalEarnings, specifier: "%.2f") PLN")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if paidEarnings < totalEarnings {
                    Text("Opłacone: \(paidEarnings, specifier: "%.2f") PLN")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Wszystko opłacone")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
}

struct LessonRow: View {
    let lesson: Lesson
    @ObservedObject var viewModel: LessonViewModel
    let onEdit: () -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private var earnings: Double {
        lesson.duration * lesson.hourlyRate
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Status i czas
            VStack(alignment: .center, spacing: 4) {
                if let date = lesson.date {
                    Text(timeFormatter.string(from: date))
                        .font(.title3)
                        .bold()
                    
                    let endTime = date.addingTimeInterval(lesson.duration * 3600)
                    Text(timeFormatter.string(from: endTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("--:--")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                
                Image(systemName: lesson.isPaid ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(lesson.isPaid ? .green : .orange)
                    .font(.title3)
            }
            .frame(width: 80) // Zwiększona szerokość z 60 na 80
            
            // Informacje o lekcji
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.student?.fullName ?? "Nieznany uczeń")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(lesson.duration, specifier: "%.1f") h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let notes = lesson.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let student = lesson.student, let link = student.lessonLink, !link.isEmpty {
                        Button(action: {
                            viewModel.openLessonLink(student: student)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "video")
                                Text("Dołącz do lekcji")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("\(earnings, specifier: "%.2f") PLN")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(lesson.isPaid ? .green : .primary)
                }
            }
            
            // Przyciski akcji
            VStack(spacing: 8) {
                Button(action: {
                    viewModel.toggleLessonPaid(lesson: lesson)
                }) {
                    Image(systemName: lesson.isPaid ? "minus.circle" : "checkmark.circle")
                        .foregroundColor(lesson.isPaid ? .orange : .green)
                }
                .buttonStyle(.plain)
                .help(lesson.isPaid ? "Oznacz jako nieopłacone" : "Oznacz jako opłacone")
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Edytuj lekcję")
                
                Button(action: {
                    Task {
                        await viewModel.deleteLesson(lesson: lesson)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Usuń lekcję")
            }
        }
        .padding(.vertical, 12)
    }
}
