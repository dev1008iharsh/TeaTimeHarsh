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

    // MARK: - Fetch Data (Merge Global + User) 📥

    func fetchAllPlaces() async throws -> [TeaPlace] {
        // 1. Fetch ALL Global Places
        let snapshot = try await db.collection("places").getDocuments()
        let globalPlaces = try snapshot.documents.compactMap { try $0.data(as: TeaPlace.self) }

        // 2. Fetch User Specific Actions (Fav/Visited)
        let userSnapshot = try await db.collection("users")
            .document(Constants.Strings.currentUserID)
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
            .document(Constants.Strings.currentUserID)
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
        try await db.collection("users").document(Constants.Strings.currentUserID)
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
        let userActionRef = db.collection("users").document(Constants.Strings.currentUserID)
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
            "userId": Constants.Strings.currentUserID, // Tamo pass karelu ID
            "email": email,
            "description": desc,
            "imageUrl": imageUrlString, // Image URL (kholi hoy to empty)
            "status": "pending", // Extra: Status track karva mate
            "createdAt": FieldValue.serverTimestamp(), // Server no time
        ]

        // 'bugs' naam nu navu collection banshe
        try await db.collection("bugs").addDocument(data: bugData)
    }

    func deleteAllPlacesCreatedByUser() async throws {
        // 1. Get all documents created by current user
        let snapshot = try await db.collection("places")
            .whereField("createdByUserId", isEqualTo: Constants.Strings.currentUserID) // Or Constants.Strings.currentUserID
            .getDocuments()

        // Check if there are places to delete
        guard !snapshot.documents.isEmpty else { return }

        // 2. Create Batch (Performance Optimization) 🚀
        let batch = db.batch()

        for doc in snapshot.documents {
            // --- STEP A: Queue the Place for deletion ---
            batch.deleteDocument(doc.reference)

            // --- STEP B: Queue the User Action for deletion (NEW) ✨ ---
            // Since the document ID in 'user_actions' IS the placeId, we can find it directly!
            let placeId = doc.documentID

            let userActionRef = db.collection("users")
                .document(Constants.Strings.currentUserID)
                .collection("user_actions")
                .document(placeId) // 🎯 Targeting the specific action for this place

            batch.deleteDocument(userActionRef)
        }

        // 3. Commit the batch (Execute all deletes at once) ✅
        try await batch.commit()
    }

    func fetchCurretnUserPlaces() async throws -> [TeaPlace] {
        // 1. Get ALL places (We know this works because you said fetchAllPlaces works)
        let snapshot = try await db.collection("places").getDocuments()

        // 2. Filter in Memory
        let allPlaces = try snapshot.documents.compactMap { try $0.data(as: TeaPlace.self) }

        // 3. Filter manually using Swift
        let myPlaces = allPlaces.filter { place in
            place.createdByUserId == Constants.Strings.currentUserID
        }

        return myPlaces.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // 1. Re-Authentication (We call this FIRST now)
    func reauthenticateWithPassword(_ password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        // This checks if the password is correct
        try await user.reauthenticate(with: credential)
    }

    // 2. Main Delete Function (Called ONLY after re-auth succeeds)
    func deleteEntireAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }

        // Create Batch
        let batch = db.batch()

        // --- STEP A: Gather Data ---
        let placesSnapshot = try await db.collection("places").whereField("createdByUserId", isEqualTo: Constants.Strings.currentUserID).getDocuments()
        let bugsSnapshot = try await db.collection("bugs").whereField("userId", isEqualTo: Constants.Strings.currentUserID).getDocuments()
        let userActionsSnapshot = try await db.collection("users").document(Constants.Strings.currentUserID).collection("user_actions").getDocuments()

        // --- STEP B: Queue Database Deletions ---
        var imageRefsToDelete: [StorageReference] = []

        // Queue Places & their images
        for doc in placesSnapshot.documents {
            batch.deleteDocument(doc.reference)
            
            // 1. Get String
            if let imageUrl = doc.data()["imageURL"] as? String {
                // 2. Create Reference (No 'try?' needed here)
                // Note: This assumes the URL is valid. If your DB has bad URLs, this could crash.
                let storageRef = storage.reference(forURL: imageUrl)
                imageRefsToDelete.append(storageRef)
            }
        }

        for doc in bugsSnapshot.documents { batch.deleteDocument(doc.reference) }
        for doc in userActionsSnapshot.documents { batch.deleteDocument(doc.reference) }

        // Delete User Profile Document
        batch.deleteDocument(db.collection("users").document(Constants.Strings.currentUserID))

        // --- STEP C: Commit Database Changes ---
        try await batch.commit()

        // --- STEP D: Clean Storage ---
        await withTaskGroup(of: Void.self) { group in
            for ref in imageRefsToDelete {
                group.addTask { try? await ref.delete() }
            }
        }

        // --- STEP E: Delete Auth Account ---
        // Since we just re-authenticated, this will succeed 100%
        try await user.delete()
    }
}
