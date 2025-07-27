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
    @State private var searchText = ""
    @State private var showOnlyUnpaid = false
    
    var filteredLessons: [Lesson] {
        viewModel.lessons.filter { lesson in
            let studentName = lesson.student?.displayName ?? lesson.student?.name ?? ""
            let matchesSearch = searchText.isEmpty ||
                               studentName.localizedCaseInsensitiveContains(searchText)
            
            return showOnlyUnpaid ? !lesson.isPaid && matchesSearch : matchesSearch
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Szukaj ucznia...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                
                Toggle("Tylko nieopłacone", isOn: $showOnlyUnpaid)
                
                Spacer()
                
                Button("Dodaj lekcję") {
                    showingAddSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding([.horizontal, .top])
            
            if filteredLessons.isEmpty {
                VStack {
                    Spacer()
                    Text("Brak lekcji do wyświetlenia")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredLessons, id: \.id) { lesson in
                        LessonRowView(lesson: lesson, viewModel: viewModel)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let lesson = filteredLessons[index]
                            viewModel.deleteLesson(lesson: lesson)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.fetchLessons()
            viewModel.fetchStudents()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddLessonView(viewModel: viewModel)
        }
    }
}

struct LessonRowView: View {
    let lesson: Lesson
    @ObservedObject var viewModel: LessonViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(lesson.student?.displayName ?? "Nieznany uczeń")
                    .font(.headline)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(lesson.duration, specifier: "%.1f") h × \(lesson.hourlyRate, specifier: "%.2f") PLN")
                
                Text("\(lesson.duration * lesson.hourlyRate, specifier: "%.2f") PLN")
                    .font(.headline)
            }
            
            Toggle("", isOn: Binding(
                get: { lesson.isPaid },
                set: { _ in viewModel.toggleLessonPaid(lesson: lesson) }
            ))
            .labelsHidden()
            .toggleStyle(CheckboxToggleStyle())
            .help(lesson.isPaid ? "Oznacz jako nieopłacone" : "Oznacz jako opłacone")
        }
        .padding(.vertical, 4)
        .opacity(lesson.isPaid ? 0.6 : 1.0)
    }
    
    var formattedDate: String {
        if let date = lesson.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            return formatter.string(from: date)
        } else {
            return "Nieznana data"
        }
    }
}
