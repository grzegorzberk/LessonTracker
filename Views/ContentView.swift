//
//  ContentView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var lessonViewModel = LessonViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LessonListView(viewModel: lessonViewModel)
                .tabItem {
                    Label("Lekcje", systemImage: "book")
                }
                .tag(0)
            
            StudentListView(viewModel: lessonViewModel)
                .tabItem {
                    Label("Uczniowie", systemImage: "person")
                }
                .tag(1)
            
            CalendarView(viewModel: lessonViewModel)
                .tabItem {
                    Label("Kalendarz", systemImage: "calendar")
                }
                .tag(2)
            
            ReportGeneratorView()
                .tabItem {
                    Label("Raporty", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(3)
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewLesson"))) { _ in
            selectedTab = 0
        }
    }
}
