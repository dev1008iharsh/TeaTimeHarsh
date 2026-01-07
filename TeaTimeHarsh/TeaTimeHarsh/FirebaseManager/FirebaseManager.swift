//
//  FirebaseManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let currentUserId = Constants.Strings.currentUserID

    // MARK: - Fetch Data (Merge Global + User) 📥

    func fetchAllPlaces() async throws -> [TeaPlace] {
        // 1. Fetch ALL Global Places
        let snapshot = try await db.collection("places").getDocuments()
        let globalPlaces = try snapshot.documents.compactMap { try $0.data(as: TeaPlace.self) }

        // 2. Fetch User Specific Actions (Fav/Visited)
        let userSnapshot = try await db.collection("users")
            .document(currentUserId)
            .collection("user_actions")
            .getDocuments()

        // Convert user actions to a Dictionary for fast lookup
        // Key: PlaceID, Value: Data Dictionary
        var userActionsMap: [String: [String: Any]] = [:]
        for doc in userSnapshot.documents {
            userActionsMap[doc.documentID] = doc.data()
        }

        // 3. Merge Data (Map Global Places with User State)
        var finalPlaces: [TeaPlace] = []

        for var place in globalPlaces {
            if let userAction = userActionsMap[place.id] {
                place.isFav = userAction["isFav"] as? Bool ?? false
                place.isVisited = userAction["isVisited"] as? Bool ?? false
            }
            finalPlaces.append(place)
        }

        // Sort by Newest First
        return finalPlaces.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // MARK: - Update User Action (Fav/Visit) 🔄

    func updateUserAction(placeId: String, isFav: Bool, isVisited: Bool) async throws {
        let userActionRef = db.collection("users")
            .document(currentUserId)
            .collection("user_actions")
            .document(placeId)

        let data: [String: Any] = [
            "placeId": placeId,
            "isFav": isFav,
            "isVisited": isVisited,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        // merge: true keeps other fields safe if we add more in future
        try await userActionRef.setData(data, merge: true)
    }

    // MARK: - Delete Place 🗑️

    func deletePlace(placeId: String) async throws {
        // Delete from Global
        try await db.collection("places").document(placeId).delete()
        // Delete from User Actions (Optional, but good for cleanup)
        try await db.collection("users").document(currentUserId)
            .collection("user_actions").document(placeId).delete()
    }

    // MARK: - Image Upload 📸

    func uploadImage(_ image: UIImage) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("place_images/\(filename)")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    // MARK: - Add Place (Create) 💾

    func addNewPlace(place: TeaPlace) async throws {
        let batch = db.batch()

        let placesRef = db.collection("places").document(place.id)
        let userActionRef = db.collection("users").document(currentUserId)
            .collection("user_actions").document(place.id)

        let userActionData: [String: Any] = [
            "placeId": place.id,
            "isVisited": place.isVisited,
            "isFav": place.isFav,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        do {
            try batch.setData(from: place, forDocument: placesRef)
            batch.setData(userActionData, forDocument: userActionRef)
            try await batch.commit()
            print("✅ Add Success: Place & User Actions saved.")
        } catch {
            print("❌ Add Error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Update Place (Edit) ✏️

    /// Updates ONLY the global place details. Does not touch user favorites/visited.
    func updatePlace(place: TeaPlace) async throws {
        // Logic: We simply overwrite the document in 'places' collection.
        // Since 'place.id' is same, Firestore knows it's an update.
        // Note: We use 'setData' with merge: false (default) to replace data,
        // or we could use 'merge: true' if we only wanted to update partial fields.
        // Here, replacing is fine because 'place' object is complete.

        let placesRef = db.collection("places").document(place.id)

        do {
            try placesRef.setData(from: place)
            print("✅ Update Success: Global place details updated.")
        } catch {
            print("❌ Update Error: \(error.localizedDescription)")
            throw error
        }
    }

    // 📸 Image Upload + 📝 Data Save Function
    func submitBugReport(desc: String, email: String, image: UIImage?) async throws {
        var imageUrlString = ""

        // 1️⃣ Jo Image hoy, to pehla Storage ma upload karo
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
            // Unique name apiye image ne
            let filename = UUID().uuidString
            let storageRef = storage.reference().child("bug_images/\(filename).jpg")

            // Upload Data
            _ = try await storageRef.putDataAsync(imageData)

            // Get Download URL
            let url = try await storageRef.downloadURL()
            imageUrlString = url.absoluteString
        }

        // 2️⃣ Have badho data Firestore ma 'bugs' collection ma save karo
        let bugData: [String: Any] = [
            "userId": currentUserId, // Tamo pass karelu ID
            "email": email,
            "description": desc,
            "imageUrl": imageUrlString, // Image URL (kholi hoy to empty)
            "status": "pending", // Extra: Status track karva mate
            "createdAt": FieldValue.serverTimestamp(), // Server no time
        ]

        // 'bugs' naam nu navu collection banshe
        try await db.collection("bugs").addDocument(data: bugData)
    }

    /*
     // 2️⃣ Step 2: Delete Logic (Data + Auth)
     func deleteFullAccount() async throws {
         guard let user = Auth.auth().currentUser else { return }

         // Batch Write: Ek sathe ghana badha delete karva mate (Fast & Safe)
         let batch = db.batch()

         // A. User na banavela badha Places delete list ma nakho
         let placesSnapshot = try await db.collection("places")
             .whereField("userId", isEqualTo: currentUserId)
             .getDocuments()

         for doc in placesSnapshot.documents {
             batch.deleteDocument(doc.reference)
         }

         // B. User ni Profile details delete list ma nakho
         let userDocRef = db.collection("users").document(currentUserId)
         batch.deleteDocument(userDocRef)

         // C. User Actions (Reviews/Favs) delete list ma nakho (Optional)
         // Jo tamare user_actions pan delete karva hoy to ahitya loop feravjo same rite

         // 🚀 D. Firestore Delete Commit karo (Execute)
         try await batch.commit()

         // 🗑️ E. Chele Firebase Auth mathi user ne udado (Login nikal jashe)
         try await user.delete()
     }*/
    func deleteEntireAccount() async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // 1. Create a Batch (To ensure all database deletions happen together)
        let batch = db.batch()

        // --- STEP A: Gather Data to Delete ---

        // A1. Find all Places created by this user
        let placesSnapshot = try await db.collection("places")
            .whereField("userId", isEqualTo: currentUserId)
            .getDocuments()

        // A2. Find all Bugs reported by this user
        let bugsSnapshot = try await db.collection("bugs")
            .whereField("userId", isEqualTo: currentUserId)
            .getDocuments()

        // A3. Find User Actions (Favorites/Visited history)
        // Note: Firestore does not automatically delete subcollections! We must do it manually.
        let userActionsSnapshot = try await db.collection("users")
            .document(currentUserId)
            .collection("user_actions")
            .getDocuments()

        // --- STEP B: Queue Database Deletions in Batch ---

        var imageRefsToDelete: [StorageReference] = []

        // Queue Places for deletion
        for doc in placesSnapshot.documents {
            batch.deleteDocument(doc.reference)

            // Save the image reference to delete from Storage later
            if let imageUrl = doc.data()["imageURL"] as? String {
                let storageRef = storage.reference(forURL: imageUrl)
                imageRefsToDelete.append(storageRef)
            }
        }

        // Queue Bugs for deletion
        for doc in bugsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        // Queue User Actions for deletion
        for doc in userActionsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        // Queue the User Profile itself
        let userProfileRef = db.collection("users").document(currentUserId)
        batch.deleteDocument(userProfileRef)

        // --- STEP C: Execute Database Changes (Atomic) ---
        // If this line fails, NOTHING above gets deleted. Validating your "Stop if failed" rule.
        try await batch.commit()

        // --- STEP D: Clean up Storage (Images) ---
        // We only reach here if the Database delete was successful.

        // Using a TaskGroup to delete images in parallel for speed
        try await withThrowingTaskGroup(of: Void.self) { group in
            for ref in imageRefsToDelete {
                group.addTask {
                    try await ref.delete()
                }
            }
            // Wait for all images to be deleted. If one fails, it throws an error.
            try await group.waitForAll()
        }

        // --- STEP E: Delete Authentication Account ---
        // The final step: Remove the login credentials.
        try await Auth.auth().currentUser?.delete()
    }

    func deleteAllPlacesCreatedByUser() async throws {
        // 1. Get all documents created by current user
        let snapshot = try await db.collection("places")
            .whereField("userId", isEqualTo: currentUserId)
            .getDocuments()

        // Check if there are places to delete
        guard !snapshot.documents.isEmpty else { return }

        // 2. Batch Delete (Performance Optimization)
        let batch = db.batch()

        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        // 3. Commit the batch (Execute delete)
        try await batch.commit()
    }

    func fetchCurretnUserPlaces() async throws -> [TeaPlace] {
        // 1. Get ALL places (We know this works because you said fetchAllPlaces works)
        let snapshot = try await db.collection("places").getDocuments()

        // 2. Filter in Memory
        let allPlaces = try snapshot.documents.compactMap { try $0.data(as: TeaPlace.self) }

        // 3. Filter manually using Swift
        let myPlaces = allPlaces.filter { place in
            place.createdByUserId == currentUserId
        }

        return myPlaces.sorted(by: { $0.createdAt > $1.createdAt })
    }
}
