//
//  CalendarView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject var lessonViewModel: LessonViewModel
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var selectedMonth = Date()
    @State private var selectedWeek = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Nagłówek kalendarza
            HStack {
                Picker("Widok", selection: $calendarViewMode) {
                    Text("Miesiąc").tag(CalendarViewMode.month)
                    Text("Tydzień").tag(CalendarViewMode.week)
                    Text("Dzień").tag(CalendarViewMode.day)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 250)
                
                Spacer()
                
                Button(action: {
                    selectedMonth = Date()
                    selectedWeek = Date()
                    viewModel.selectedDate = Date()
                    viewModel.fetchLessonsForSelectedDate()
                }) {
                    Text("Dzisiaj")
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            if !viewModel.calendarAccessGranted {
                CalendarPermissionView(viewModel: viewModel)
                    .onAppear {
                        // Sprawdź status przy każdym pojawieniu się widoku
                        Task {
                            print("Sprawdzanie statusu kalendarza przy pojawieniu się widoku...")
                            await viewModel.loadCalendarData()
                        }
                    }
            } else {
                switch calendarViewMode {
                case .month:
                    MonthCalendarView(
                        viewModel: viewModel,
                        lessonViewModel: lessonViewModel,
                        currentMonth: $selectedMonth,
                        calendarViewMode: $calendarViewMode
                    )
                case .week:
                    WeekCalendarView(
                        viewModel: viewModel,
                        lessonViewModel: lessonViewModel,
                        currentWeek: $selectedWeek,
                        calendarViewMode: $calendarViewMode
                    )
                case .day:
                    DayCalendarView(
                        viewModel: viewModel,
                        lessonViewModel: lessonViewModel,
                        selectedDate: $viewModel.selectedDate
                    )
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadCalendarData()
                viewModel.fetchLessonsForSelectedDate()
            }
        }
    }
}

enum CalendarViewMode {
    case month, week, day
}

struct CalendarPermissionView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var isRequestingPermission = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Brak dostępu do kalendarza")
                .font(.title)
            
            Text("Aplikacja potrzebuje dostępu do kalendarza, aby móc wyświetlać i zarządzać terminami zajęć.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            VStack(spacing: 12) {
                Button("Udziel dostępu") {
                    print("Przycisk 'Udziel dostępu' został naciśnięty")
                    isRequestingPermission = true
                    Task { @MainActor in
                        print("Rozpoczęcie ładowania danych kalendarza...")
                        let granted = await viewModel.loadCalendarData()
                        print("Wynik ładowania danych kalendarza: \(granted)")
                        isRequestingPermission = false
                        
                        if !granted {
                            alertMessage = "Dostęp do kalendarza został odrzucony. Przejdź do Ustawień systemowych > Prywatność i bezpieczeństwo > Kalendarz i włącz dostęp dla aplikacji LessonTracker."
                            showingAlert = true
                        }
                    }
                }
                .disabled(isRequestingPermission)
                
                Button("Otwórz ustawienia systemowe") {
                    print("Przycisk 'Otwórz ustawienia systemowe' został naciśnięty")
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        print("Otwieranie URL: \(url)")
                        NSWorkspace.shared.open(url)
                    } else {
                        print("Nie udało się utworzyć URL do ustawień")
                    }
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
            }
            
            if isRequestingPermission {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Proszę o dostęp...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .alert("Problem z dostępem do kalendarza", isPresented: $showingAlert) {
            Button("OK") {}
            Button("Otwórz ustawienia") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
}

struct MonthCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject var lessonViewModel: LessonViewModel
    @Binding var currentMonth: Date
    @Binding var calendarViewMode: CalendarViewMode
    @State private var lessonsByDay: [Date: [Lesson]] = [:]
    
    let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    let calendar = Calendar.current
    
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        updateLessonsByDay()
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(monthTitle)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        updateLessonsByDay()
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            // Dni tygodnia
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Siatka dni
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(viewModel.getMonthDays(for: currentMonth), id: \.self) { date in
                    DayCell(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        lessons: lessonsByDay[calendar.startOfDay(for: date)] ?? [],
                        onSelect: {
                            viewModel.selectedDate = date
                            viewModel.fetchLessonsForSelectedDate()
                            withAnimation {
                                calendarViewMode = .day
                            }
                        }
                    )
                }
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            updateLessonsByDay()
        }
    }
    
    private func updateLessonsByDay() {
        lessonsByDay = viewModel.groupLessonsByDay(for: currentMonth)
    }
}

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let lessons: [Lesson]
    let onSelect: () -> Void
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 26, height: 26)
                            .opacity(0.9)
                    }
                    
                    Text(dayNumber)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .gray))
                }
                .padding(.vertical, 2)
                
                if !lessons.isEmpty {
                    ForEach(lessons.prefix(3), id: \.id) { lesson in
                        VStack(spacing: 1) {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color(lesson.lessonStatus.color))
                                    .frame(width: 4, height: 4)
                                
                                Text(lesson.student?.name ?? "")
                                    .font(.system(size: 8))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if let startTime = lesson.date {
                                HStack {
                                    Text(timeFormatter.string(from: startTime))
                                        .font(.system(size: 7))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if lessons.count > 3 {
                        Text("+\(lessons.count - 3)")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .frame(height: 80)
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(lessons.isEmpty ? Color.clear : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct WeekCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject var lessonViewModel: LessonViewModel
    @Binding var currentWeek: Date
    @Binding var calendarViewMode: CalendarViewMode
    @State private var lessonsByDay: [Date: [Lesson]] = [:]
    @State private var showingAddSheet = false
    
    let calendar = Calendar.current
    
    var weekTitle: String {
        let weekDays = getWeekDays()
        guard let firstDay = weekDays.first, let lastDay = weekDays.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        
        if calendar.isDate(firstDay, equalTo: lastDay, toGranularity: .month) {
            formatter.dateFormat = "d - d MMMM yyyy"
            let startDay = calendar.component(.day, from: firstDay)
            let endDay = calendar.component(.day, from: lastDay)
            formatter.dateFormat = "MMMM yyyy"
            return "\(startDay) - \(endDay) \(formatter.string(from: firstDay))"
        } else {
            formatter.dateFormat = "d MMM"
            let startString = formatter.string(from: firstDay)
            let endString = formatter.string(from: lastDay)
            formatter.dateFormat = "yyyy"
            return "\(startString) - \(endString) \(formatter.string(from: firstDay))"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Nagłówek tygodnia
            HStack {
                Button(action: {
                    withAnimation {
                        currentWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
                        updateLessonsByDay()
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(weekTitle)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                
                Button(action: {
                    withAnimation {
                        currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
                        updateLessonsByDay()
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            // Nagłówki dni
            HStack(spacing: 0) {
                // Kolumna godzin
                Text("")
                    .frame(width: 60)
                
                ForEach(getWeekDays(), id: \.self) { date in
                    WeekDayHeader(date: date)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Siatka tygodniowa z godzinami
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(generateHours(), id: \.self) { hour in
                        HStack(spacing: 0) {
                            // Kolumna godzin
                            Text(formatHour(hour))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                                .padding(.trailing, 8)
                            
                            // Kolumny dni
                            ForEach(getWeekDays(), id: \.self) { date in
                                WeekDayColumn(
                                    date: date,
                                    hour: hour,
                                    lessons: getLessonsForHour(date: date, hour: hour),
                                    onTap: {
                                        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                                        dateComponents.hour = hour
                                        if let selectedDateTime = calendar.date(from: dateComponents) {
                                            viewModel.selectedDate = selectedDateTime
                                            viewModel.fetchLessonsForSelectedDate()
                                            withAnimation {
                                                calendarViewMode = .day
                                            }
                                        }
                                    }
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .border(Color.gray.opacity(0.2), width: 0.5)
                            }
                        }
                        .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal)
            
            // Przycisk dodawania lekcji
            HStack {
                Spacer()
                Button("Dodaj lekcję") {
                    showingAddSheet = true
                }
                .padding()
            }
        }
        .onAppear {
            updateLessonsByDay()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddLessonView(viewModel: lessonViewModel)
                .onDisappear {
                    updateLessonsByDay()
                }
        }
    }
    
    private func getWeekDays() -> [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentWeek)?.start ?? currentWeek
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func updateLessonsByDay() {
        let weekDays = getWeekDays()
        guard let startDate = weekDays.first, let endDate = weekDays.last else { return }
        
        let request = Lesson.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Lesson.date, ascending: true)]
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", 
                                      calendar.startOfDay(for: startDate) as NSDate,
                                      calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)! as NSDate)
        
        do {
            let lessons = try PersistenceController.shared.container.viewContext.fetch(request)
            var grouped: [Date: [Lesson]] = [:]
            
            for lesson in lessons {
                guard let lessonDate = lesson.date else { continue }
                let dayKey = calendar.startOfDay(for: lessonDate)
                
                if grouped[dayKey] == nil {
                    grouped[dayKey] = []
                }
                grouped[dayKey]?.append(lesson)
            }
            
            lessonsByDay = grouped
        } catch {
            print("Błąd pobierania lekcji dla tygodnia: \(error)")
            lessonsByDay = [:]
        }
    }
    
    private func generateHours() -> [Int] {
        return Array(8...22) // Godziny od 8:00 do 22:00
    }
    
    private func formatHour(_ hour: Int) -> String {
        return String(format: "%02d:00", hour)
    }
    
    private func getLessonsForHour(date: Date, hour: Int) -> [Lesson] {
        let dayKey = calendar.startOfDay(for: date)
        guard let dayLessons = lessonsByDay[dayKey] else { return [] }
        
        return dayLessons.filter { lesson in
            guard let lessonDate = lesson.date else { return false }
            let lessonHour = calendar.component(.hour, from: lessonDate)
            return lessonHour == hour
        }
    }
}

struct WeekDayHeader: View {
    let date: Date
    
    private let calendar = Calendar.current
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 28, height: 28)
                }
                
                Text(dayNumber)
                    .font(.headline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : .primary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WeekDayColumn: View {
    let date: Date
    let hour: Int
    let lessons: [Lesson]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                if !lessons.isEmpty {
                    ForEach(lessons, id: \.id) { lesson in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(lesson.lessonStatus.color))
                                .frame(width: 4, height: 4)
                            
                            Text(lesson.student?.name ?? "")
                                .font(.system(size: 9))
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(lesson.lessonStatus.color).opacity(0.2))
                        )
                    }
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject var lessonViewModel: LessonViewModel
    @Binding var selectedDate: Date
    @State private var showingAddSheet = false
    
    let calendar = Calendar.current
    
    var dayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation {
                        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        viewModel.fetchLessonsForSelectedDate()
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(dayTitle)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                
                Button(action: {
                    withAnimation {
                        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        viewModel.fetchLessonsForSelectedDate()
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            if viewModel.lessons.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Brak zajęć w tym dniu")
                        .font(.title2)
                    
                    Button("Dodaj lekcję") {
                        showingAddSheet = true
                    }
                    .padding()
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.lessons.sorted(by: {
                        ($0.date ?? Date()) < ($1.date ?? Date())
                    }), id: \.id) { lesson in
                        DayLessonRow(lesson: lesson, lessonViewModel: lessonViewModel)
                    }
                }
                .listStyle(PlainListStyle())
                
                Button("Dodaj lekcję") {
                    showingAddSheet = true
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.fetchLessonsForSelectedDate()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddLessonView(viewModel: lessonViewModel)
                .onDisappear {
                    viewModel.fetchLessonsForSelectedDate()
                }
        }
    }
}

struct DayLessonRow: View {
    let lesson: Lesson
    let lessonViewModel: LessonViewModel
    
    var formattedTime: String {
        guard let date = lesson.date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var endTimeFormatted: String {
        guard let startDate = lesson.date else { return "" }
        let endDate = startDate.addingTimeInterval(lesson.duration * 3600)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endDate)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .center) {
                Text(formattedTime)
                    .font(.headline)
                
                Text(endTimeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: lesson.lessonStatus.icon)
                        .foregroundColor(Color(lesson.lessonStatus.color))
                    
                    Text(lesson.student?.fullName ?? "Nieznany uczeń")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(lesson.duration, specifier: "%.1f") h")
                        .font(.callout)
                }
                
                if let notes = lesson.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let student = lesson.student, let link = student.lessonLink, !link.isEmpty {
                    Button(action: {
                        lessonViewModel.openLessonLink(student: student)
                    }) {
                        HStack {
                            Image(systemName: "video")
                            Text("Dołącz do lekcji")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.blue)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
