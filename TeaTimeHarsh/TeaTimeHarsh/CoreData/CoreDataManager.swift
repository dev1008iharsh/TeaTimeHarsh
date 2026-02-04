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
                print("❌ [CoreData] Critical Error loading persistent stores: \(error), \(error.userInfo)")

                // Future Step: Crashlytics or Analytics setup
                // log error to know it's failed
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

    // MARK: - Sync Logic (Save Firebase Data to Local - No Duplication,No same data overwrite)

    func syncPlacesToLocalDB(places: [TeaPlace]) {
        persistentContainer.performBackgroundTask { bgContext in

            // 1. Fetch Existing Data
            let fetchRequest: NSFetchRequest<CDTeaPlace> = CDTeaPlace.fetchRequest()

            do {
                let existingEntities = try bgContext.fetch(fetchRequest)

                // 2. Convert to Structs
                // 'compactMap' removes nil values automatically
                let existingPlaces = existingEntities.compactMap { $0.convertToStruct() }

                // 3. Smart Check: Compare Data
                // Sorting is necessary to compare arrays correctly
                let sortedNewPlaces = places.sorted { $0.id < $1.id }
                let sortedExistingPlaces = existingPlaces.sorted { $0.id < $1.id }

                // Direct comparison using our updated Equatable extension
                if sortedNewPlaces == sortedExistingPlaces {
                    ToastManager.shared.show(message: "Everything is up to date", type: .success)
                    return
                } else {
                    ToastManager.shared.show(message: "Fetching latest places...🥳", type: .appTheme)
                }

                print("🔄 [CoreData] New data detected. Updating local DB...")

                // 4. Wipe Old Data
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                try bgContext.execute(deleteRequest)

                // 5. Insert New Data
                for place in places {
                    let entity = CDTeaPlace(context: bgContext)

                    entity.id = place.id
                    entity.name = place.name
                    entity.desc = place.desc
                    entity.website = place.website
                    entity.phone = place.phone
                    entity.city = place.city
                    entity.address = place.address

                    // Numbers
                    entity.latitude = place.latitude ?? 0.0
                    entity.longitude = place.longitude ?? 0.0
                    entity.rating = place.rating ?? 0.0
                    entity.totalReviewCount = Int64(place.totalReviewCount ?? 0) // Saving Int64

                    // URLs
                    entity.imageURL = place.imageURL
                    entity.videoURL = place.videoURL
                    entity.videoThumbnailURL = place.videoThumbnailURL
                    entity.pdfURL = place.pdfURL

                    // Metadata
                    entity.priceRange = place.priceRange
                    entity.openingTime = place.openingTime
                    entity.closingTime = place.closingTime
                    entity.holiday = place.holiday
                    entity.createdByUserId = place.createdByUserId
                    entity.createdAt = place.createdAt

                    // User State
                    entity.isFav = place.isFav
                    entity.isVisited = place.isVisited
                }

                // 6. Save Changes
                if bgContext.hasChanges {
                    try bgContext.save()
                    print("✅ [CoreData] Database updated successfully.")
                }

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

    func clearAllDataOfCoreData() {
        let context = persistentContainer.viewContext
        let model = persistentContainer.managedObjectModel

        model.entities.forEach { entity in
            guard let entityName = entity.name else { return }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                context.reset()
            } catch {
                print("❌ Failed to clear entity \(entityName): \(error.localizedDescription)")
            }
        }

        print("🧹 All Core Data data cleared")
    }
}
