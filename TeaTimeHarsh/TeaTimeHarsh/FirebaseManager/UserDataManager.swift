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
    // MARK: - Singleton

    static let shared = UserDataManager()

    // MARK: - Constants

    /// Key used to store User object in UserDefaults.
    private let kUserProfileCacheKey = "cached_user_profile_data"

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Holds the current user object.
    /// Initially tries to load from UserDefaults (Cache) so UI is not empty.
    var user: User?

    /// Tracks if we have fresh data from the server in this session.
    var isUserUpdatedAtCurrentAppLaunch: Bool = false

    private init() {
        // Load cached data immediately on initialization
        user = loadUserFromLocalCache()
    }

    // MARK: - 📥 Fetch Current User

    /// Fetches user data from Firestore and updates the local cache.
    func fetchCurrentUser() async throws -> User {
        // 1. Validation
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        // 2. Define Reference
        let userRef = db.collection("users").document(uid)

        do {
            // 3. Fetch & Decode from Network
            let fetchedUser = try await userRef.getDocument(as: User.self)
            print("✅ Network Fetch Success: User found for ID: \(uid)")

            // 4. Save to Local Cache (UserDefaults)
            // This ensures next time app opens, data is available instantly.
            saveUserToLocalCache(fetchedUser)

            // 5. Update Memory & Flag
            user = fetchedUser
            isUserUpdatedAtCurrentAppLaunch = true

            return fetchedUser

        } catch {
            print("❌ Fetch Error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 💾 Local Cache (UserDefaults) Helpers

    /// Saves the User object to UserDefaults.
    private func saveUserToLocalCache(_ user: User) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            UserDefaults.standard.set(data, forKey: kUserProfileCacheKey)
            print("💾 Cache Updated: User data saved to UserDefaults.")
        } catch {
            print("⚠️ Cache Save Failed: \(error.localizedDescription)")
        }
    }

    /// Loads the User object from UserDefaults.
    private func loadUserFromLocalCache() -> User? {
        guard let data = UserDefaults.standard.data(forKey: kUserProfileCacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let cachedUser = try decoder.decode(User.self, from: data)
            print("📂 Cache Loaded: Found existing user data in UserDefaults.")
            return cachedUser
        } catch {
            print("⚠️ Cache Load Failed: Could not decode data.")
            return nil
        }
    }

    // MARK: - ☁️ Upload Profile Image

    func uploadProfileImage(_ image: UIImage) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("profile_images/\(filename)")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload & Get URL
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    // MARK: - 👤 Update User Profile

    func updateUserProfile(user: User) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        let userRef = db.collection("users").document(uid)

        do {
            let userData = try Firestore.Encoder().encode(user)
            try await userRef.setData(userData, merge: true)

            // Also update local cache so it remains in sync
            saveUserToLocalCache(user)
            self.user = user

            print("✅ Update Success: User Profile Saved to Firestore & Cache.")

        } catch {
            print("❌ Update Error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 🔄 Smart Retry Logic

    /// Called when Internet connection is restored.
    func fetchUserProfileIfNeeded() {
        // Check if we already have fresh network data for this session
        if isUserUpdatedAtCurrentAppLaunch {
            print("✅ Data is already fresh. Skipping retry.")
            return
        }

        print("🔄 Internet back! Syncing latest data...")

        Task {
            do {
                let _ = try await fetchCurrentUser()
                // 'fetchCurrentUser' automatically updates self.user and saves to cache
            } catch {
                print("❌ Retry failed: \(error.localizedDescription)")
            }
        }
    }
}
