//
//  PersistenceController.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "LessonTracker")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Nie udało się załadować CoreData: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Nie udało się zapisać zmian: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
