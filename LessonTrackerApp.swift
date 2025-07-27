//
//  LessonTrackerApp.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

@main
struct LessonTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
