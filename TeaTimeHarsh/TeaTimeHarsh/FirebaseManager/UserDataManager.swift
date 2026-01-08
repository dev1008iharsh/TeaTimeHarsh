//
//  UserDataManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 08/01/26.
//
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

class UserDataManager {
    static let shared = UserDataManager()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
   
    // Returns a User object or throws an error if something fails
    // MARK: - Fetch Current User 📥

    func fetchCurrentUser() async throws -> User {
        // 1. Validation 🔐
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        // 2. Define Reference (Clean & Readable)
        let userRef = db.collection("users").document(uid)

        do {
            // 3. Fetch & Decode ⚡️
            // We use 'getDocument(as:)' inside the do-block to catch decoding errors
            let user = try await userRef.getDocument(as: User.self)
            
            print("✅ Fetch Success: User found for ID: \(uid)")
            return user
            
        } catch {
            // 4. Error Handling
            // This catches "Document does not exist" or "Decoding failed" errors
            print("❌ Fetch Error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 📤 SET / UPDATE User

    // MARK: - Upload Profile Image ☁️

    func uploadProfileImage(_ image: UIImage) async throws -> String {
        // Pro Tip: We use UUID here so every upload is unique.
        let filename = UUID().uuidString + ".jpg"

        // Changing folder to 'profile_images' to keep storage organized
        let storageRef = storage.reference().child("profile_images/\(filename)")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // 1. Upload Data
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // 2. Get Download URL
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    // MARK: - Update User Profile 👤

    func updateUserProfile(user: User) async throws {
        // 1. Validation
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        let userRef = db.collection("users").document(uid)

        do {
            // 2. ⚙️ ENCODE: Convert struct to Dictionary manually
            // This is the specific fix for the "No async operations" warning.
            // It keeps the code clean and prevents the compiler confusion.
            let userData = try Firestore.Encoder().encode(user)

            // 3. ☁️ UPDATE: Save to Firestore
            // matches your style: using try await
            try await userRef.setData(userData, merge: true)

            print("✅ Update Success: User Profile Saved for ID: \(uid)")

        } catch {
            print("❌ Update Error: \(error.localizedDescription)")
            throw error
        }
    }
}
