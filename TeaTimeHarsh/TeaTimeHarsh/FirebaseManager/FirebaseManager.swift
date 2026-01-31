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

    // MARK: - Image Upload 📸

    func uploadImage(_ image: UIImage, onProgress: @escaping (Double) -> Void) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("place_images/\(filename)")

        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image compression failed"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Use 'putData' task to observe progress
        let uploadTask = storageRef.putData(imageData, metadata: metadata)

        return try await withCheckedThrowingContinuation { continuation in
            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                onProgress(percent)
            }

            uploadTask.observe(.success) { _ in
                storageRef.downloadURL { url, error in
                    if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: error ?? NSError(domain: "UploadError", code: 0))
                    }
                }
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - 🎥 Upload Video (New)

    /// - Returns: Tuple containing (videoDownloadURL, thumbnailDownloadURL)
    func uploadVideo(compressedVideoURL: URL, onProgress: @escaping (Double) -> Void) async throws -> (videoUrl: String, thumbUrl: String) {
        // 1. Generate & Upload Thumbnail first (Quick operation)
        guard let thumbImage = VideoHelper.generateThumbnail(from: compressedVideoURL) else {
            throw NSError(domain: "VideoError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not generate thumbnail"])
        }
        // Thumbnail contributes very little to progress, so we just await it.
        let thumbUrlString = try await uploadImage(thumbImage, onProgress: { _ in })

        // 2. Upload Video File
        let filename = UUID().uuidString + ".mp4" // or .mov depending on compression
        let videoRef = storage.reference().child("place_videos/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"

        let videoData = try Data(contentsOf: compressedVideoURL)
        let uploadTask = videoRef.putData(videoData, metadata: metadata)

        let videoUrlString: String = try await withCheckedThrowingContinuation { continuation in
            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                onProgress(percent)
            }

            uploadTask.observe(.success) { _ in
                videoRef.downloadURL { url, error in
                    if let url = url { continuation.resume(returning: url.absoluteString) }
                    else { continuation.resume(throwing: error!) }
                }
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error { continuation.resume(throwing: error) }
            }
        }

        return (videoUrlString, thumbUrlString)
    }

    // MARK: - 📄 Upload PDF (New)

    func uploadPDF(pdfURL: URL, onProgress: @escaping (Double) -> Void) async throws -> String {
        let filename = UUID().uuidString + ".pdf"
        let pdfRef = storage.reference().child("place_docs/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"

        let pdfData = try Data(contentsOf: pdfURL)
        let uploadTask = pdfRef.putData(pdfData, metadata: metadata)

        return try await withCheckedThrowingContinuation { continuation in
            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                onProgress(percent)
            }

            uploadTask.observe(.success) { _ in
                pdfRef.downloadURL { url, error in
                    if let url = url { continuation.resume(returning: url.absoluteString) }
                    else { continuation.resume(throwing: error!) }
                }
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error { continuation.resume(throwing: error) }
            }
        }
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
            print("✅ UpdatePlace firebase api Success")
        } catch {
            print("❌ Error UpdatePlace firebase api  : \(error.localizedDescription)")
            throw error
        }
    }

    // 📸 Image Upload + 📝 Data Save Function
    func submitBugReport(desc: String, email: String, image: UIImage?) async throws {
        var imageUrlString = ""

        // 1️⃣ Jo Image hoy, to pehla Storage ma upload karo
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.7) {
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

    // MARK: - 🗑️ Storage Cleanup Helper

    private func deleteFileFromStorage(url: String?) async {
        guard let urlString = url, !urlString.isEmpty else { return }
        let storageRef = storage.reference(forURL: urlString)
        try? await storageRef.delete()
    }

    // MARK: - Delete Single Place (Complete Cleanup) 🏚️

    func deletePlace(place: TeaPlace) async throws {
        let batch = db.batch()
        var urlsToDelete: [String] = []

        // --- A. Place Media URLs ---
        if let img = place.imageURL { urlsToDelete.append(img) }
        if let vid = place.videoURL { urlsToDelete.append(vid) }
        if let thumb = place.videoThumbnailURL { urlsToDelete.append(thumb) }
        if let pdf = place.pdfURL { urlsToDelete.append(pdf) }

        // --- B. Delete Place Reviews (Subcollection) ---
        // Fetch all reviews written on THIS place
        let reviewsSnapshot = try await db.collection("places").document(place.id)
            .collection("reviews").getDocuments()

        for doc in reviewsSnapshot.documents {
            batch.deleteDocument(doc.reference) // Delete review doc

            // If review has an image, add to delete list
            if let reviewImg = doc.data()["review_image_url"] as? String {
                urlsToDelete.append(reviewImg)
            }
        }

        // --- C. Delete Main Documents ---
        // Delete Place Document
        batch.deleteDocument(db.collection("places").document(place.id))

        // Delete User Action (Visited/Fav status)
        batch.deleteDocument(db.collection("users").document(Constants.Strings.currentUserID)
            .collection("user_actions").document(place.id))

        // --- D. Execute ---
        try await batch.commit()

        // --- E. Clean Storage ---
        await withTaskGroup(of: Void.self) { group in
            for url in urlsToDelete {
                group.addTask { await self.deleteFileFromStorage(url: url) }
            }
        }
    }

    // MARK: - 🛠️ Helper: Queue Places for Deletion

    /// Prepares batch operations to delete all places created by a user and collects their media URLs.
    /// Also handles sub-collections (reviews) and their images.
    private func queuePlacesDeletion(for userId: String, in batch: WriteBatch) async throws -> [String] {
        var urlsToDelete: [String] = []

        // 1. Fetch User's Places
        let snapshot = try await db.collection("places")
            .whereField("createdByUserId", isEqualTo: userId)
            .getDocuments()

        for placeDoc in snapshot.documents {
            // A. Queue Place Document Delete
            batch.deleteDocument(placeDoc.reference)

            // B. Queue User Action Document Delete (Visited/Fav)
            let userActionRef = db.collection("users").document(userId)
                .collection("user_actions").document(placeDoc.documentID)
            batch.deleteDocument(userActionRef)

            // C. Collect Place Media URLs 📥
            let data = placeDoc.data()
            if let img = data["imageURL"] as? String { urlsToDelete.append(img) }
            if let vid = data["videoURL"] as? String { urlsToDelete.append(vid) } // ✅ New
            if let thumb = data["videoThumbnailURL"] as? String { urlsToDelete.append(thumb) } // ✅ New
            if let pdf = data["pdfURL"] as? String { urlsToDelete.append(pdf) } // ✅ New

            // D. Fetch & Delete Reviews inside this Place (Subcollection) 🕵️‍♂️
            // Note: We need to wait here to fetch subcollections
            let reviewsSnapshot = try await db.collection("places").document(placeDoc.documentID)
                .collection("reviews").getDocuments()

            for reviewDoc in reviewsSnapshot.documents {
                batch.deleteDocument(reviewDoc.reference)
                // Collect Review Image
                if let reviewImg = reviewDoc.data()["review_image_url"] as? String {
                    urlsToDelete.append(reviewImg)
                }
            }
        }

        return urlsToDelete
    }

    // MARK: - Delete All Places 🧨

    func deleteAllPlacesCreatedByUser() async throws {
        // 1. Create Batch
        let batch = db.batch()

        // 2. Use Helper to queue deletions and get URLs 🤝
        // This handles Places, User Actions, Sub-reviews, and all their Images/Videos
        let urlsToDelete = try await queuePlacesDeletion(for: Constants.Strings.currentUserID, in: batch)

        // If no data found, just return
        guard !urlsToDelete.isEmpty else { return }

        // 3. Commit DB Changes
        try await batch.commit()

        // 4. Clean Storage (Parallel) 🚀
        await withTaskGroup(of: Void.self) { group in
            for url in urlsToDelete {
                group.addTask { await self.deleteFileFromStorage(url: url) }
            }
        }
    }

    // MARK: - Account Deletion Logic 💀

    // 1. Re-Authentication
    func reauthenticateWithPassword(_ password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    // 2. Main Delete Function
    func deleteEntireAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }

        let batch = db.batch()
        var allUrlsToDelete: [String] = []

        // --- STEP A: Use Helper for Places & their Reviews (No Duplication!) ---
        let placeUrls = try await queuePlacesDeletion(for: Constants.Strings.currentUserID, in: batch)
        allUrlsToDelete.append(contentsOf: placeUrls)

        // --- STEP B: Gather Other User Data ---

        // 1. User Reviews on OTHER places (Where I commented on someone else's place)
        let myReviewsSnapshot = try await db.collectionGroup("reviews")
            .whereField("user_id", isEqualTo: Constants.Strings.currentUserID).getDocuments()

        for doc in myReviewsSnapshot.documents {
            batch.deleteDocument(doc.reference)
            if let reviewImg = doc.data()["review_image_url"] as? String {
                allUrlsToDelete.append(reviewImg)
            }
        }

        // 2. Bugs Reports
        let bugsSnapshot = try await db.collection("bugs")
            .whereField("userId", isEqualTo: Constants.Strings.currentUserID).getDocuments()
        for doc in bugsSnapshot.documents { batch.deleteDocument(doc.reference) }

        // 3. User Actions Collection (Clean sweep)
        let userActionsSnapshot = try await db.collection("users").document(Constants.Strings.currentUserID)
            .collection("user_actions").getDocuments()
        for doc in userActionsSnapshot.documents { batch.deleteDocument(doc.reference) }

        // 4. User Profile & Profile Image
        let userDocRef = db.collection("users").document(Constants.Strings.currentUserID)
        let userDoc = try await userDocRef.getDocument()

        if let profileImg = userDoc.data()?["profile_image_url"] as? String {
            allUrlsToDelete.append(profileImg) // Delete Profile Pic 👤
        }
        batch.deleteDocument(userDocRef)

        // --- STEP C: Commit DB Changes ---
        try await batch.commit()

        // --- STEP D: Clean Storage ---
        await withTaskGroup(of: Void.self) { group in
            for url in allUrlsToDelete {
                group.addTask { await self.deleteFileFromStorage(url: url) }
            }
        }

        // --- STEP E: Delete Auth Account ---
        try await user.delete()
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

    func fetchUserPersonalDetails(userID: String) async throws -> User {
        // We use 'getDocument(as: User.self)' which automatically converts
        // the Firestore JSON into your 'User' struct.
        let user = try await db.collection("users")
            .document(userID)
            .getDocument(as: User.self)

        return user
    }

    // MARK: - 🌟 Review & Rating System 🌟

    // 1. Upload Review Image
    func uploadReviewImage(_ image: UIImage) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("review_images/\(filename)") // Separate folder for reviews

        // Compress image to save bandwidth
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let _ = try await storageRef.putDataAsync(imageData)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    // 2. Submit Review (Main Function)
    /// Logic: Upload Image -> Save Review -> Recalculate Average

    func submitReview(placeId: String, user: User, rating: Double, reviewText: String, reviewImage: UIImage) async throws {
        // A. Validation
        guard let userId = user.id else { return }

        // B. Upload Image First 📸
        let imageUrl = try await uploadReviewImage(reviewImage)

        // C. Prepare Review Object
        let review = PlaceReview(
            userId: userId,
            userName: user.fullName ?? "Tea Lover",
            userImage: user.profileImageUrl,
            rating: rating,
            reviewText: reviewText,
            reviewImageURL: imageUrl, // Mandatory Image
            createdAt: Date()
        )

        let placeRef = db.collection("places").document(placeId)
        let reviewRef = placeRef.collection("reviews").document(userId)

        // D. Transaction for Safe Write 🛡️
        // 👇  Added '_ =' to silence the 'unused result' warning
        _ = try await db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                // Save/Overwrite the review document
                try transaction.setData(from: review, forDocument: reviewRef)
            } catch let nsError as NSError {
                errorPointer?.pointee = nsError
                return nil
            }
            return nil
        })

        // E. Recalculate Average Rating 🧮
        try await recalculatePlaceAverage(placeId: placeId)
    }

    // 3. Helper to Recalculate & Update Average
    private func recalculatePlaceAverage(placeId: String) async throws {
        let reviewsRef = db.collection("places").document(placeId).collection("reviews")
        let snapshot = try await reviewsRef.getDocuments()

        let documents = snapshot.documents

        // Handle case with no reviews
        if documents.isEmpty {
            try await db.collection("places").document(placeId).updateData([
                "rating": 0,
                "total_review_count": 0,
            ])
            return
        }

        // Calculate Average
        var totalRating = 0.0
        for doc in documents {
            if let r = doc.data()["rating"] as? Double {
                totalRating += r
            }
        }

        let average = totalRating / Double(documents.count)
        let count = documents.count

        // Update Main Place Document
        try await db.collection("places").document(placeId).updateData([
            "rating": average,
            "total_review_count": count,
        ])
    }

    // Fetch all reviews for a specific place (Sorted by Newest)
    func fetchPlaceReviews(for placeId: String) async throws -> [PlaceReview] {
        // Path: places/{placeId}/reviews
        let snapshot = try await db.collection("places")
            .document(placeId)
            .collection("reviews")
            .order(by: "created_at", descending: true) // Sort: Newest First
            .getDocuments()

        // Convert documents to PlaceReview array
        return try snapshot.documents.compactMap { try $0.data(as: PlaceReview.self) }
    }
}
