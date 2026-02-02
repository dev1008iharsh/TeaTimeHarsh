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
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Fetch Data (Merge Global + User) 📥

    func fetchAllPlaces() async throws -> [TeaPlace] {
        print("\n╔════════════ [ START: fetchAllPlaces ] ════════════╗")
        print("🔍 Step 1: Fetching all global places from 'places' collection...")

        // 1. Fetch ALL Global Places
        let snapshot = try await db.collection("places").getDocuments()

        // Using safe decoding to prevent one bad document from breaking the whole list
        let globalPlaces = snapshot.documents.compactMap { doc -> TeaPlace? in
            do {
                return try doc.data(as: TeaPlace.self)
            } catch {
                print("⚠️ Decoding Error in Place [\(doc.documentID)]: \(error.localizedDescription)")
                return nil
            }
        }
        print("📦 Found \(globalPlaces.count) global places.")

        // 2. Fetch User Specific Actions (Fav/Visited)
        let userID = AppConstants.Strings.currentUserID
        print("👤 Step 2: Fetching user actions for: \(userID)")

        let userSnapshot = try await db.collection("users")
            .document(userID)
            .collection("user_actions")
            .getDocuments()

        // Convert user actions to a Dictionary for fast lookup [O(1) complexity]
        var userActionsMap: [String: [String: Any]] = [:]
        for doc in userSnapshot.documents {
            userActionsMap[doc.documentID] = doc.data()
        }
        print("ℹ️ Found \(userActionsMap.count) user-specific actions (Fav/Visited).")

        // 3. Merge Data (Map Global Places with User State)
        print("🔄 Step 3: Merging global data with user state...")
        var finalPlaces: [TeaPlace] = []
        var mergedCount = 0

        for var place in globalPlaces {
            if let userAction = userActionsMap[place.id] {
                place.isFav = userAction["isFav"] as? Bool ?? false
                place.isVisited = userAction["isVisited"] as? Bool ?? false
                mergedCount += 1
            }
            finalPlaces.append(place)
        }

        print("✅ Merge Complete: \(mergedCount) places personalized. Total: \(finalPlaces.count)")

        // Sort by Newest First
        return finalPlaces.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // MARK: - Update User Action (Fav/Visit) 🔄

    func updateUserAction(placeId: String, isFav: Bool, isVisited: Bool) async throws {
        print("\n╔════════════ [ START: updateUserAction ] ════════════╗")
        let userID = AppConstants.Strings.currentUserID
        print("🔄 Step 1: Updating User Action for PlaceID: \(placeId) (User: \(userID))")

        let userActionRef = db.collection("users")
            .document(userID)
            .collection("user_actions")
            .document(placeId)

        // Preparing the data dictionary
        let data: [String: Any] = [
            "placeId": placeId,
            "isFav": isFav,
            "isVisited": isVisited,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        print("⏳ Step 2: Sending data to Firestore (Merge: True)...")
        print("📊 Status -> isFav: \(isFav), isVisited: \(isVisited)")

        do {
            // merge: true keeps other fields safe if we add more in future
            try await userActionRef.setData(data, merge: true)

            print("✅ Success: User Action updated successfully for [\(placeId)] 🏁")
        } catch {
            print("❌ Error: Failed to update User Action: \(error.localizedDescription)")

            // 💡 Senior Developer Tip:
            // If this fails, verify that the 'users' document exists and Security Rules allow writing to sub-collections.

            throw error
        }
    }

    // MARK: - Image Upload 📸

    func uploadImage(_ image: UIImage, folderName: String, customName: String? = nil, onProgress: @escaping (Double) -> Void) async throws -> String {
        print("\n╔════════════ [ START: uploadImage ] ════════════╗")
        print("📸 Step 1: Preparing \(folderName) image for upload...")

        // ✅ LOGIC CHANGE: Use customName if provided, otherwise random UUID
        let filename = customName ?? UUID().uuidString
        let finalFileName = "\(filename).jpg" // Always .jpg

        let storageRef = storage.reference().child("\(folderName)/\(finalFileName)")

        // Compress image to save bandwidth
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("❌ Error: Image compression failed")
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image compression failed"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("⏳ Step 2: Starting upload task for \(finalFileName)...")

        // Use 'putData' task to observe progress
        let uploadTask = storageRef.putData(imageData, metadata: metadata)

        return try await withCheckedThrowingContinuation { continuation in

            // 1. Observe Progress
            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

                print("📊 Upload Progress: \(Int(percent * 100))%")
                onProgress(percent)
            }

            // 2. Observe Success
            uploadTask.observe(.success) { _ in
                print("✅ Step 3: Image uploaded successfully. Fetching download URL...")

                storageRef.downloadURL { url, error in
                    if let url = url {
                        print("🔗 Success: Download URL: \(url.absoluteString)")
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        let fetchError = error ?? NSError(domain: "UploadError", code: 0)
                        print("❌ Error fetching download URL: \(fetchError.localizedDescription)")
                        continuation.resume(throwing: fetchError)
                    }
                }
            }

            // 3. Observe Failure
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    print("❌ Error: Upload task failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - 🎥 Upload Video

    /// Uploads ONLY the video file. Thumbnail handling is moved to the caller (AddPlaceVC) to avoid duplicate generation.
    /// - Returns: String containing the videoDownloadURL
    func uploadVideo(compressedVideoURL: URL, customName: String? = nil, onProgress: @escaping (Double) -> Void) async throws -> String {
        print("\n╔════════════ [ START: uploadVideo ] ════════════╗")
        print("🎬 Step 1: Initiating Video Upload process for: \(compressedVideoURL.lastPathComponent)")

        // Note: Thumbnail upload logic removed from here as it is now handled in AddPlaceVC.

        // 1. Upload Video File
        // ✅ LOGIC CHANGE: Use customName if provided
        let filename = customName ?? UUID().uuidString
        let finalFileName = "\(filename).mp4" // Always .mp4

        let videoRef = storage.reference().child("place_video/\(finalFileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"

        do {
            let videoData = try Data(contentsOf: compressedVideoURL)
            print("📦 Step 2: Video Data loaded (\(videoData.count / (1024 * 1024)) MB). Starting upload task...")

            let uploadTask = videoRef.putData(videoData, metadata: metadata)

            let videoUrlString: String = try await withCheckedThrowingContinuation { continuation in
                // Observe Progress
                uploadTask.observe(.progress) { snapshot in
                    guard let progress = snapshot.progress else { return }
                    let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

                    // Logging progress
                    print("📊 Video Upload Progress: \(Int(percent * 100))%")
                    onProgress(percent)
                }

                // Observe Success
                uploadTask.observe(.success) { _ in
                    print("✅ Step 3: Video file uploaded successfully. Fetching download URL...")
                    videoRef.downloadURL { url, error in
                        if let url = url {
                            print("🔗 Success: Video URL generated: \(url.absoluteString)")
                            continuation.resume(returning: url.absoluteString)
                        } else {
                            print("❌ Error: Failed to get video download URL: \(error?.localizedDescription ?? "Unknown error")")
                            continuation.resume(throwing: error!)
                        }
                    }
                }

                // Observe Failure
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error {
                        print("❌ Error: Video upload task failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }

            print("🏁 Video Process Complete. Returning Video URL.")
            return videoUrlString

        } catch {
            print("❌ Error: Failed to read local compressed video data: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 📄 Upload PDF (New)

    func uploadPDF(pdfURL: URL, customName: String? = nil, onProgress: @escaping (Double) -> Void) async throws -> String {
        print("\n╔════════════ [ START: uploadPDF ] ════════════╗")
        print("📄 Step 1: Initiating PDF upload for file: \(pdfURL.lastPathComponent)")

        // ✅ LOGIC CHANGE: Use customName if provided
        let filename = customName ?? UUID().uuidString
        let finalFileName = "\(filename).pdf"

        let pdfRef = storage.reference().child("place_menu/\(finalFileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"

        do {
            // 💡 Senior Developer Tip:
            // Always wrap disk I/O in do-catch. If the local file is missing, it will fail here.
            let pdfData = try Data(contentsOf: pdfURL)
            print("⏳ Step 2: PDF Data loaded (\(pdfData.count / 1024) KB). Starting upload task...")

            let uploadTask = pdfRef.putData(pdfData, metadata: metadata)

            return try await withCheckedThrowingContinuation { continuation in
                // Observe Progress
                uploadTask.observe(.progress) { snapshot in
                    guard let progress = snapshot.progress else { return }
                    let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

                    // Logging progress every step
                    print("📊 Upload Progress: \(Int(percent * 100))%")
                    onProgress(percent)
                }

                // Observe Success
                uploadTask.observe(.success) { _ in
                    print("✅ Step 3: PDF uploaded successfully. Fetching download URL...")
                    pdfRef.downloadURL { url, error in
                        if let url = url {
                            print("🔗 Success: Download URL generated: \(url.absoluteString)")
                            continuation.resume(returning: url.absoluteString)
                        } else {
                            print("❌ Error: Failed to get download URL: \(error?.localizedDescription ?? "Unknown error")")
                            continuation.resume(throwing: error!)
                        }
                    }
                }

                // Observe Failure
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error {
                        print("❌ Error: PDF upload task failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            print("❌ Error: Failed to read local PDF data: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Add Place (Create) 💾

    func addNewPlace(place: TeaPlace) async throws {
        print("\n╔════════════ [ START: addNewPlace ] ════════════╗")
        print("🚀 Step 1: Initiating 'Add New Place' for: [\(place.name)]")

        let batch = db.batch()
        let userID = AppConstants.Strings.currentUserID

        // Path definitions
        let placesRef = db.collection("places").document(place.id)
        let userActionRef = db.collection("users").document(userID)
            .collection("user_actions").document(place.id)

        // Prepare User Action Data
        let userActionData: [String: Any] = [
            "placeId": place.id,
            "isVisited": place.isVisited,
            "isFav": place.isFav,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        print("⏳ Step 2: Preparing batch operations for Firestore...")

        do {
            // A. Set Place Document (Encodable support)
            try batch.setData(from: place, forDocument: placesRef)

            // B. Set User Action Document (Dictionary support)
            batch.setData(userActionData, forDocument: userActionRef)

            print("📝 Batch prepared: Place & User Action references added.")

            // C. Commit the transaction
            print("⏳ Step 3: Committing Batch Write to Firestore...")
            try await batch.commit()

            print("✅ Add Success: Place & User Actions saved successfully for User: \(userID) 🏁")
        } catch {
            print("❌ Add Error in addNewPlace: \(error.localizedDescription)")

            // 💡 Senior Developer Tip:
            // If this fails, check if the document ID already exists or if rules allow writing to both paths.

            throw error
        }
    }

    // MARK: - Update Place (Edit) ✏️

    /// Updates ONLY the global place details. Does not touch user favorites/visited.
    func updatePlace(place: TeaPlace) async throws {
        print("\n╔════════════ [ START: updatePlace ] ════════════╗")
        print("🔄 Step 1: Starting update for Place: [\(place.name)] ID: \(place.id)")

        // Logic: We simply overwrite the document in 'places' collection.
        // Since 'place.id' is same, Firestore knows it's an update.
        // Note: We use 'setData' with merge: false (default) to replace data,
        // or we could use 'merge: true' if we only wanted to update partial fields.
        // Here, replacing is fine because 'place' object is complete.

        let placesRef = db.collection("places").document(place.id)

        do {
            print("⏳ Step 2: Sending updated data to Firestore...")

            // 💡 Senior Developer Tip:
            // Using 'setData(from:)' requires the model to conform to Encodable.
            // It's efficient because it handles the mapping for you.
            try placesRef.setData(from: place)

            print("✅ UpdatePlace firebase api Success: [\(place.id)] has been updated. 🏁")
        } catch {
            print("❌ Error UpdatePlace firebase api for [\(place.id)]: \(error.localizedDescription)")

            // 💡 Error Point: Check if the user has permission to edit this specific document
            //

            throw error
        }
    }

    // 📸 Image Upload + 📝 Data Save Function
    func submitBugReport(desc: String, email: String, image: UIImage?) async throws {
        print("\n╔════════════ [ START: submitBugReport ] ════════════╗")
        print("🐞 Step 1: Initiating Bug Report Submission...")
        var imageUrlString = ""

        // 1️⃣ Jo Image hoy, to pehla Storage ma upload karo
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.7) {
            print("📸 Step 1a: Image found. Starting upload to Firebase Storage...")

            // Unique name apiye image ne
            let filename = UUID().uuidString
            let storageRef = storage.reference().child("place_bug_images/\(filename).jpg")

            do {
                // Upload Data
                print("⏳ Uploading image data (\(imageData.count / 1024) KB)...")
                _ = try await storageRef.putDataAsync(imageData)

                // Get Download URL
                let url = try await storageRef.downloadURL()
                imageUrlString = url.absoluteString
                print("✅ Image uploaded successfully. URL: \(imageUrlString)")
            } catch {
                print("❌ Error uploading bug image: \(error.localizedDescription)")
                throw error
            }
        } else {
            print("ℹ️ No image attached to the bug report.")
        }

        // 2️⃣ Have badho data Firestore ma 'bugs' collection ma save karo
        print("📝 Step 2: Preparing Firestore document for 'bugs' collection...")
        let bugData: [String: Any] = [
            "userId": AppConstants.Strings.currentUserID, // Tamo pass karelu ID
            "email": email,
            "description": desc,
            "imageUrl": imageUrlString, // Image URL (kholi hoy to empty)
            "status": "pending", // Extra: Status track karva mate
            "createdAt": FieldValue.serverTimestamp(), // Server no time
        ]

        do {
            // 'bugs' naam nu navu collection banshe
            print("⏳ Writing bug report to Firestore...")
            try await db.collection("bugs").addDocument(data: bugData)
            print("✅ Success: Bug report submitted successfully! 🏁")
        } catch {
            print("❌ Firestore Error: Failed to save bug report: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 🗑️ Global Storage Cleanup Helper (Universal)

    /// Deletes a file from Firebase Storage using its Download URL.
    /// Used for: Draft Discard AND Delete Place Logic.
    func deleteStorageFile(at urlString: String) async {
        print("\n╔════════════ [ START: deleteStorageFile ] ════════════╗")

        // 1. Validation: Ensure it's a valid remote Firebase URL
        guard !urlString.isEmpty, urlString.contains("firebase") else {
            print("⚠️ Cleanup: Invalid or Local URL skipped: \(urlString)")
            return
        }

        // 2. Create Reference
        // Note: storage.reference(forURL:) creates a ref from a full HTTPS URL
        let storageRef = storage.reference(forURL: urlString)

        // 3. Attempt Delete
        do {
            print("⏳ Storage: Attempting to delete file: \(storageRef.name)")
            try await storageRef.delete()
            print("✅ Storage: File deleted successfully.")
        } catch {
            // 4. Error Handling
            // If file doesn't exist (already deleted), we just log it as a warning.
            // We don't throw error because we want the process to continue.
            print("⚠️ Warning: Failed to delete file (might not exist). Reason: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Single Place (Complete Cleanup) 🏚️

    func deletePlace(place: TeaPlace) async throws {
        print("\n╔════════════ [ START: deletePlace ] ════════════╗")
        print("🚀 Step 1: Starting cleanup for place: [\(place.name)] ID: \(place.id)")

        let batch = db.batch()
        var urlsToDelete: [String] = []

        // --- A. Place Media URLs ---
        print("📂 Step A: Gathering main media URLs...")
        if let img = place.imageURL { urlsToDelete.append(img) }
        if let vid = place.videoURL { urlsToDelete.append(vid) }
        if let thumb = place.videoThumbnailURL { urlsToDelete.append(thumb) }
        if let pdf = place.pdfURL { urlsToDelete.append(pdf) }

        print("ℹ️ Found \(urlsToDelete.count) main media files to delete.")

        // --- B. Delete Place Reviews (Subcollection) ---
        print("📂 Step B: Fetching sub-collection reviews for this place...")
        do {
            // Fetch all reviews written on THIS place
            let reviewsSnapshot = try await db.collection("places").document(place.id)
                .collection("reviews").getDocuments()

            print("ℹ️ Found \(reviewsSnapshot.documents.count) reviews to remove.")

            for doc in reviewsSnapshot.documents {
                batch.deleteDocument(doc.reference) // Delete review doc

                // If review has an image, add to delete list
                if let reviewImg = doc.data()["review_image_url"] as? String {
                    urlsToDelete.append(reviewImg)
                    print("🖼️ Review image added to cleanup queue.")
                }
            }
        } catch {
            print("❌ Error fetching reviews: \(error.localizedDescription)")
            throw error
        }

        // --- C. Delete Main Documents ---
        print("📂 Step C: Queuing document deletions in batch...")

        // Delete Place Document
        batch.deleteDocument(db.collection("places").document(place.id))

        // Delete User Action (Visited/Fav status)
        let userActionRef = db.collection("users").document(AppConstants.Strings.currentUserID)
            .collection("user_actions").document(place.id)
        batch.deleteDocument(userActionRef)

        // --- D. Execute ---
        print("⏳ Step D: Committing Firestore Batch Write...")
        do {
            try await batch.commit()
            print("✅ Firestore Batch Commit Successful.")
        } catch {
            print("❌ Firestore Batch Failed: \(error.localizedDescription)")
            throw error
        }

        // --- E. Clean Storage ---
        print("☁️ Step E: Deleting \(urlsToDelete.count) files from Firebase Storage...")
        await withTaskGroup(of: Void.self) { group in
            for url in urlsToDelete {
                group.addTask {
                    print("🗑️ Deleting Storage File: \(url)")
                    // ✅ FIXED: Used the consistent helper name
                    await self.deleteStorageFile(at: url)
                }
            }
        }

        print("✅ Full Place Cleanup Complete! 🏁")
    }

    // MARK: - 🛠️ Helper: Queue Places for Deletion

    /// Prepares batch operations to delete all places created by a user and collects their media URLs.
    /// Also handles sub-collections (reviews) and their images.
    private func queuePlacesDeletion(for userId: String, in batch: WriteBatch) async throws -> [String] {
        print("\n╔════════════ [ START: queuePlacesDeletion ] ════════════╗")
        print("🔎 Helper: Starting cleanup queue for UserID: \(userId)")
        var urlsToDelete: [String] = []

        // 1. Fetch User's Places
        let snapshot = try await db.collection("places")
            .whereField("createdByUserId", isEqualTo: userId)
            .getDocuments()

        print("📂 Helper Step 1: Found \(snapshot.documents.count) places created by this user.")

        for placeDoc in snapshot.documents {
            let placeID = placeDoc.documentID
            print("📍 Processing Place: [\(placeID)]")

            // A. Queue Place Document Delete
            batch.deleteDocument(placeDoc.reference)

            // B. Queue User Action Document Delete (Visited/Fav)
            let userActionRef = db.collection("users").document(userId)
                .collection("user_actions").document(placeID)
            batch.deleteDocument(userActionRef)

            // C. Collect Place Media URLs 📥
            let data = placeDoc.data()
            var mediaCountForThisPlace = 0

            if let img = data["imageURL"] as? String { urlsToDelete.append(img); mediaCountForThisPlace += 1 }
            if let vid = data["videoURL"] as? String { urlsToDelete.append(vid); mediaCountForThisPlace += 1 }
            if let thumb = data["videoThumbnailURL"] as? String { urlsToDelete.append(thumb); mediaCountForThisPlace += 1 }
            if let pdf = data["pdfURL"] as? String { urlsToDelete.append(pdf); mediaCountForThisPlace += 1 }

            print("  🎥 Media files found in place doc: \(mediaCountForThisPlace)")

            // D. Fetch & Delete Reviews inside this Place (Subcollection) 🕵️‍♂️
            print("  🕵️‍♂️ Checking for sub-collection reviews in [\(placeID)]...")
            let reviewsSnapshot = try await db.collection("places").document(placeID)
                .collection("reviews").getDocuments()

            print("  📝 Found \(reviewsSnapshot.documents.count) reviews in this place.")

            for reviewDoc in reviewsSnapshot.documents {
                batch.deleteDocument(reviewDoc.reference)
                // Collect Review Image
                if let reviewImg = reviewDoc.data()["review_image_url"] as? String {
                    urlsToDelete.append(reviewImg)
                    print("  🖼️ Review image added to deletion queue.")
                }
            }
        }

        print("✅ Helper Cleanup: Queueing complete. Total media URLs to delete: \(urlsToDelete.count)")
        return urlsToDelete
    }

    // MARK: - Delete All Places 🧨

    func deleteAllPlacesCreatedByUser() async throws {
        print("\n╔════════════ [ START: deleteAllPlacesCreatedByUser ] ════════════╗")
        print("🧨 Step 1: Initiating 'Delete All Places' for User: \(AppConstants.Strings.currentUserID)")

        // 1. Create Batch
        let batch = db.batch()

        // 2. Use Helper to queue deletions and get URLs 🤝
        // This handles Places, User Actions, Sub-reviews, and all their Images/Videos
        print("⏳ Step 2: Queuing documents for deletion via helper...")
        let urlsToDelete = try await queuePlacesDeletion(for: AppConstants.Strings.currentUserID, in: batch)

        // If no data found, just return
        guard !urlsToDelete.isEmpty else {
            print("ℹ️ No places or media found to delete for this user.")
            return
        }

        print("📦 Found \(urlsToDelete.count) media files and associated documents to remove.")

        // 3. Commit DB Changes
        print("⏳ Step 3: Committing Firestore Batch Write...")
        do {
            try await batch.commit()
            print("✅ Firestore Batch: All document references deleted successfully.")
        } catch {
            print("❌ Firestore Batch Error: \(error.localizedDescription)")
            throw error
        }

        // 4. Clean Storage (Parallel) 🚀
        print("☁️ Step 4: Starting Parallel Cleanup of \(urlsToDelete.count) files from Firebase Storage...")
        await withTaskGroup(of: Void.self) { group in
            for url in urlsToDelete {
                group.addTask {
                    print("🗑️ Deleting Storage File: \(url)")
                    // ✅ FIXED: Used the consistent helper name
                    await self.deleteStorageFile(at: url)
                }
            }
        }

        print("✅ Full Cleanup Complete: All places and media are gone! 🏁")
    }

    // MARK: - Account Deletion Logic 💀

    // 1. Re-Authentication
    func reauthenticateWithPassword(_ password: String) async throws {
        print("\n╔════════════ [ START: reauthenticateWithPassword ] ════════════╗")
        print("🔐 Step 1: Starting Re-authentication process...")

        // Check if user is logged in
        guard let user = Auth.auth().currentUser else {
            print("❌ Error: No current user found for re-authentication")
            return
        }

        // Check if email is available
        guard let email = user.email else {
            print("❌ Error: User email is missing from Auth session")
            return
        }

        print("📧 Re-authenticating user: \(email)")

        // Create credentials using email and the provided password
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        do {
            print("⏳ Verification in progress with Firebase Auth...")

            // 💡 Senior Developer Tip:
            // Re-authentication is a "Sensitive Operation".
            // If this succeeds, the user's session is refreshed for deletion or password change.
            try await user.reauthenticate(with: credential)

            print("✅ Success: User re-authenticated successfully! Proceeding with deletion...")

        } catch {
            // Handle common errors like wrong password or network issues
            print("❌ Re-authentication Failed: \(error.localizedDescription)")

            // Image of Firebase Auth re-authentication flow and security tokens

            throw error
        }
    }

    // 2. Main Delete Function

    // MARK: - Delete Account with Debug Logs 💀

    func deleteEntireAccount() async throws {
        print("\n╔════════════ [ START: deleteEntireAccount ] ════════════╗")
        print("🚀 Starting Account Deletion Process...")
        guard let user = Auth.auth().currentUser else {
            print("❌ Error: No current user found in Auth")
            return
        }

        let userID = AppConstants.Strings.currentUserID
        print("👤 Deleting data for User ID: \(userID)")

        let batch = db.batch()
        var allUrlsToDelete: [String] = []

        // --- STEP A: Places & Reviews ---
        print("📂 Step A: Fetching places and associated media...")
        do {
            // Assuming queuePlacesDeletion takes (userId, batch) or returns URLs
            let placeUrls = try await queuePlacesDeletion(for: userID, in: batch)
            allUrlsToDelete.append(contentsOf: placeUrls)
            print("✅ Places queued. Media count so far: \(allUrlsToDelete.count)")
        } catch {
            print("❌ Error in Step A (Places): \(error.localizedDescription)")
            throw error
        }

        // --- STEP B: Other User Data ---
        print("📂 Step B: Fetching user reviews on other places...")
        do {
            let myReviewsSnapshot = try await db.collectionGroup("reviews")
                .whereField("user_id", isEqualTo: userID).getDocuments()

            print("ℹ️ Found \(myReviewsSnapshot.documents.count) reviews by user on other places.")
            for doc in myReviewsSnapshot.documents {
                batch.deleteDocument(doc.reference)
                if let reviewImg = doc.data()["review_image_url"] as? String {
                    allUrlsToDelete.append(reviewImg)
                }
            }

            // 2. Bugs Reports
            print("📂 Fetching bug reports...")
            let bugsSnapshot = try await db.collection("bugs")
                .whereField("userId", isEqualTo: userID).getDocuments()
            print("ℹ️ Found \(bugsSnapshot.documents.count) bug reports.")
            for doc in bugsSnapshot.documents { batch.deleteDocument(doc.reference) }

            // 3. User Actions (Clean sweep)
            print("📂 Fetching user actions...")
            let userActionsSnapshot = try await db.collection("users").document(userID)
                .collection("user_actions").getDocuments()
            print("ℹ️ Found \(userActionsSnapshot.documents.count) user actions.")
            for doc in userActionsSnapshot.documents { batch.deleteDocument(doc.reference) }

            // 4. User Profile & Profile Image
            print("📂 Fetching user profile info...")
            let userDocRef = db.collection("users").document(userID)
            let userDoc = try await userDocRef.getDocument()

            if let profileImg = userDoc.data()?["profile_image_url"] as? String {
                allUrlsToDelete.append(profileImg)
                print("👤 Profile image found for deletion.")
            }
            batch.deleteDocument(userDocRef)
        } catch {
            print("❌ Error in Step B (Data Gathering): \(error.localizedDescription)")
            throw error
        }

        // --- STEP C: Commit DB Changes ---
        print("⏳ Step C: Committing Firestore Batch Write...")
        do {
            try await batch.commit()
            print("✅ Firestore Batch Commit Successful.")
        } catch {
            print("❌ Firestore Batch Commit Failed: \(error.localizedDescription)")
            throw error
        }

        // --- STEP D: Clean Firebase Storage ---
        print("☁️ Step D: Deleting \(allUrlsToDelete.count) files from Firebase Storage...")
        await withTaskGroup(of: Void.self) { group in
            for url in allUrlsToDelete {
                group.addTask {
                    print("🗑️ Deleting file: \(url)")
                    // ✅ FIXED: Used the consistent helper name
                    await self.deleteStorageFile(at: url)
                }
            }
        }
        print("✅ Firebase Storage Cleanup Finished.")

        // --- STEP E: Delete Auth Account ---
        print("🔐 Step F: Deleting Firebase Auth User...")
        do {
            try await user.delete()
            print("💀 Account deletion complete. User is gone.")
        } catch {
            print("❌ Auth Deletion Failed: \(error.localizedDescription)")
            print("💡 Tip: This often happens if the session is old. Try re-authenticating.")
            throw error
        }
    }

    func fetchCurretnUserPlaces() async throws -> [TeaPlace] {
        print("\n╔════════════ [ START: fetchCurretnUserPlaces ] ════════════╗")
        print("🔍 Step 1: Fetching places from Firestore...")

        // 1. Get ALL places
        let snapshot = try await db.collection("places").getDocuments()
        print("📂 Found \(snapshot.documents.count) total documents in 'places'.")

        // 2. Filter in Memory (Safe Way ✅)
        // We use compactMap without 'try' outside, to handle each document individually.
        let allPlaces = snapshot.documents.compactMap { doc -> TeaPlace? in
            do {
                // Try decoding each document one by one
                let place = try doc.data(as: TeaPlace.self)
                return place
            } catch {
                // If one document fails, we don't crash. We just print and skip it.
                print("⚠️ Decoding Error in Doc ID [\(doc.documentID)]: \(error.localizedDescription)")
                return nil
            }
        }

        print("📦 Step 2: Successfully decoded \(allPlaces.count) out of \(snapshot.documents.count) places.")

        // 3. Filter manually using Swift
        let currentUserID = AppConstants.Strings.currentUserID
        let myPlaces = allPlaces.filter { place in
            place.createdByUserId == currentUserID
        }

        print("✅ Step 3: Final count for User [\(currentUserID)]: \(myPlaces.count) places.")

        return myPlaces.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func fetchUserPersonalDetails(userID: String) async throws -> User {
        print("\n╔════════════ [ START: fetchUserPersonalDetails ] ════════════╗")
        print("👤 Step 1: Fetching user details for ID: \(userID)")

        // 💡 Senior Developer Tip:
        // Always check if the ID is empty before hitting the network.
        guard !userID.isEmpty else {
            print("❌ Error: userID is empty!")
            throw NSError(domain: "AppError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid User ID"])
        }

        do {
            // 1. Fetching document from Firestore
            let docRef = db.collection("users").document(userID)

            // 2. Try to decode the document into our User model
            // We use 'try await' here because network or decoding can fail.
            let user = try await docRef.getDocument(as: User.self)

            print("✅ Success: Fetched user [\(user.email)]")
            return user

        } catch {
            // 3. Detailed Error Handling
            // This will print if the document doesn't exist OR if decoding fails.
            print("❌ Error in fetchUserPersonalDetails: \(error.localizedDescription)")

            // Let's find out if it's a decoding issue (Mismatch between DB and Swift Model)
            if error is DecodingError {
                print("⚠️ Decoding Mismatch: Your 'User' struct doesn't match the Firestore data.")
                // Image of Swift Codable decoding process for JSON/Firestore data
            }

            throw error
        }
    }

    // MARK: - 🌟 Review & Rating System 🌟

    // 1. Upload Review Image
    func uploadReviewImage(_ image: UIImage) async throws -> String {
        print("\n╔════════════ [ START: uploadReviewImage ] ════════════╗")
        //Every user can upload one review to particular place
        print("📸 Step 1: Starting Review Image Upload...")
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("place_review_images/\(filename)")

        // Compress image to save bandwidth
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("❌ Error: Image compression failed")
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        do {
            print("⏳ Uploading \(imageData.count / 1024) KB to Firebase Storage...")
            let _ = try await storageRef.putDataAsync(imageData)
            let url = try await storageRef.downloadURL()
            print("✅ Image Uploaded Successfully. URL: \(url.absoluteString)")
            return url.absoluteString
        } catch {
            print("❌ Firebase Storage Error: \(error.localizedDescription)")
            throw error
        }
    }

    // 2. Submit Review (Main Function)
    /// Logic: Upload Image -> Save Review -> Recalculate Average
    func submitReview(placeId: String, user: User, rating: Double, reviewText: String, reviewImage: UIImage) async throws {
        print("\n╔════════════ [ START: submitReview ] ════════════╗")
        print("🚀 Step 2: Submitting Review for PlaceID: \(placeId)")

        // A. Validation
        guard let userId = user.id else {
            print("❌ Error: user.id is missing")
            return
        }

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
        print("⏳ Step 3: Starting Firestore Transaction for review...")
        _ = try await db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                // Save/Overwrite the review document
                try transaction.setData(from: review, forDocument: reviewRef)
                print("📝 Transaction: Review data set in batch.")
            } catch let nsError as NSError {
                print("❌ Transaction Error: \(nsError.localizedDescription)")
                errorPointer?.pointee = nsError
                return nil
            }
            return nil
        })
        print("✅ Step 4: Transaction Committed.")

        // E. Recalculate Average Rating 🧮
        try await recalculatePlaceAverage(placeId: placeId)
    }

    // 3. Helper to Recalculate & Update Average
    private func recalculatePlaceAverage(placeId: String) async throws {
        print("\n╔════════════ [ START: recalculatePlaceAverage ] ════════════╗")
        print("🧮 Step 5: Recalculating average rating for PlaceID: \(placeId)")
        let reviewsRef = db.collection("places").document(placeId).collection("reviews")

        do {
            let snapshot = try await reviewsRef.getDocuments()
            let documents = snapshot.documents
            print("📂 Found \(documents.count) total reviews for calculation.")

            // Handle case with no reviews
            if documents.isEmpty {
                print("ℹ️ No reviews found. Resetting stats to 0.")
                try await db.collection("places").document(placeId).updateData([
                    "rating": 0,
                    "total_review_count": 0,
                ])
                return
            }

            // Calculate Average
            var totalRating = 0.0
            for doc in documents {
                // Safe casting for Firestore numbers
                if let r = doc.data()["rating"] as? Double {
                    totalRating += r
                } else if let r = doc.data()["rating"] as? Int {
                    totalRating += Double(r)
                }
            }

            let average = totalRating / Double(documents.count)
            let count = documents.count
            print("📈 Calculation Results -> Average: \(average), Total Reviews: \(count)")

            // Update Main Place Document
            try await db.collection("places").document(placeId).updateData([
                "rating": average,
                "total_review_count": count,
            ])
            print("✅ Step 6: Average rating updated in main 'places' collection. Done! 🏁")

        } catch {
            print("❌ Error in recalculatePlaceAverage: \(error.localizedDescription)")
            throw error
        }
    }

    // Fetch all reviews for a specific place (Sorted by Newest)
    func fetchPlaceReviews(for placeId: String) async throws -> [PlaceReview] {
        print("\n╔════════════ [ START: fetchPlaceReviews ] ════════════╗")
        print("📝 Step 1: Fetching reviews for PlaceID: \(placeId)")

        // Safety check: ensure placeId is not empty
        guard !placeId.isEmpty else {
            print("❌ Error: placeId is empty!")
            return []
        }

        // Path: places/{placeId}/reviews
        // 💡 Note: This query requires an index if you are using multiple filters later
        let snapshot = try await db.collection("places")
            .document(placeId)
            .collection("reviews")
            .order(by: "created_at", descending: true) // Sort: Newest First
            .getDocuments()

        print("📂 Step 2: Found \(snapshot.documents.count) review documents.")

        // Convert documents to PlaceReview array (Safe Way ✅)
        let reviews = snapshot.documents.compactMap { doc -> PlaceReview? in
            do {
                // Attempt to decode each review individually
                let review = try doc.data(as: PlaceReview.self)
                return review
            } catch {
                // If one review fails to decode, we print the error and skip it
                print("⚠️ Decoding Error in Review [\(doc.documentID)]: \(error.localizedDescription)")
                return nil
            }
        }

        print("✅ Step 3: Successfully decoded \(reviews.count) reviews for this place.")
        return reviews
    }
}
