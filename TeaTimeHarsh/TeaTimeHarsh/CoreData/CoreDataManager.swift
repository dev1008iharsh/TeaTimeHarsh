//
//  CoreDataManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/01/26.
//

import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack (Moved from AppDelegate)

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         Make sure "TeaTimeHarsh" matches your .xcdatamodeld filename exactly.
         */
        let container = NSPersistentContainer(name: "TeaTimeHarsh")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // Production app ma fatalError na vaparvi, pan development mate ok che.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // Main Context (UI mate)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - General Save Function

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("❌ Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Sync Logic (Save Firebase Data to Local)

    func syncPlacesToLocalDB(places: [TeaPlace]) {
        persistentContainer.performBackgroundTask { bgContext in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDTeaPlace.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                // 1. Wipe Old Data
                try bgContext.execute(deleteRequest)

                // 2. Insert New Data
                for place in places {
                    let entity = CDTeaPlace(context: bgContext)

                    entity.id = place.id
                    entity.name = place.name
                    entity.desc = place.desc
                    entity.phone = place.phone
                    entity.location = place.location
                    entity.address = place.address
                    entity.imageURL = place.imageURL
                    entity.priceRange = place.priceRange
                    entity.openingTime = place.openingTime
                    entity.closingTime = place.closingTime
                    entity.holiday = place.holiday
                    entity.createdByUserId = place.createdByUserId
                    entity.createdAt = place.createdAt

                    entity.rating = place.rating ?? 0.0
                    entity.latitude = place.latitude ?? 0.0
                    entity.longitude = place.longitude ?? 0.0
                    entity.isFav = place.isFav
                    entity.isVisited = place.isVisited
                }

                // 3. Save
                try bgContext.save()
                print("✅ [CoreData] Data synced successfully inside Manager")

            } catch {
                print("❌ [CoreData] Sync Error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Logic

    func fetchLocalPlaces() -> [TeaPlace] {
        let request: NSFetchRequest<CDTeaPlace> = CDTeaPlace.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let result = try viewContext.fetch(request)
            return result.compactMap { $0.convertToStruct() }
        } catch {
            print("❌ [CoreData] Fetch Error: \(error.localizedDescription)")
            return []
        }
    }
}
