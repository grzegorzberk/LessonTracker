//
//  CalendarView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @ObservedObject var viewModel: LessonViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var upcomingEvents: [EKEvent] = []
    @State private var showingCalendarPermissionAlert = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Kalendarz lekcji")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Odśwież") {
                    refreshCalendarData()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            HStack {
                // Calendar section
                VStack(alignment: .leading) {
                    // Month navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                        }
                        
                        Text(dateFormatter.string(from: currentMonth))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        // Weekday headers
                        ForEach(["Nd", "Pn", "Wt", "Śr", "Cz", "Pt", "Sb"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        
                        // Calendar days
                        ForEach(calendarDays, id: \.self) { date in
                            CalendarDayView(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                hasLessons: hasLessonsOn(date: date),
                                lessons: lessonsFor(date: date)
                            ) {
                                selectedDate = date
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Upcoming lessons sidebar
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nadchodzące lekcje")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if upcomingEvents.isEmpty {
                        VStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("Brak nadchodzących lekcji")
                                .foregroundColor(.gray)
                            
                            Button("Sprawdź uprawnienia kalendarza") {
                                checkCalendarPermissions()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(upcomingEvents, id: \.eventIdentifier) { event in
                                    UpcomingLessonCard(event: event)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(width: 300)
            }
            .frame(maxHeight: .infinity)
        }
        .onAppear {
            refreshCalendarData()
        }
        .alert("Uprawnienia kalendarza", isPresented: $showingCalendarPermissionAlert) {
            Button("OK") {}
        } message: {
            Text("Aplikacja potrzebuje dostępu do kalendarza, aby wyświetlać nadchodzące lekcje. Sprawdź ustawienia prywatności w Preferencjach Systemowych.")
        }
    }
    
    private var calendarDays: [Date] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        var date = startOfWeek
        
        for _ in 0..<42 { // 6 weeks * 7 days
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func hasLessonsOn(date: Date) -> Bool {
        return !lessonsFor(date: date).isEmpty
    }
    
    private func lessonsFor(date: Date) -> [Lesson] {
        return viewModel.lessons.filter { lesson in
            guard let lessonDate = lesson.date else { return false }
            return calendar.isDate(lessonDate, inSameDayAs: date)
        }
    }
    
    private func refreshCalendarData() {
        Task { @MainActor in
            if await viewModel.requestCalendarAccess() {
                upcomingEvents = viewModel.getUpcomingLessons()
            } else {
                showingCalendarPermissionAlert = true
            }
        }
    }
    
    private func checkCalendarPermissions() {
        Task { @MainActor in
            let hasAccess = await viewModel.requestCalendarAccess()
            if !hasAccess {
                showingCalendarPermissionAlert = true
            } else {
                upcomingEvents = viewModel.getUpcomingLessons()
            }
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasLessons: Bool
    let lessons: [Lesson]
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(textColor)
                
                if hasLessons {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 32, height: 32)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if hasLessons {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
}

struct UpcomingLessonCard: View {
    let event: EKEvent
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM • HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(dateFormatter.string(from: event.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}