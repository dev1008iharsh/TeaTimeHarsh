//
//  FirebaseManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let currentUserId = Constant.currentUserID.rawValue
    
    // Add these functions inside your existing FirebaseManager class

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
                "updatedAt": FieldValue.serverTimestamp()
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
            "updatedAt": FieldValue.serverTimestamp()
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
}
