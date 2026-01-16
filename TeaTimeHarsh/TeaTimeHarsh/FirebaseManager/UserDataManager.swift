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
        user = loadUserFromUserDefaults()
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
            print("✅ UserDataManager Network Fetch Success User Id found: \(uid)")

            // 4. Save to Local Cache (UserDefaults)
            // This ensures next time app opens, data is available instantly.
            saveUserToUserDefaults(fetchedUser)

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
    func saveUserToUserDefaults(_ user: User) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            UserDefaults.standard.set(data, forKey: kUserProfileCacheKey)
            print("✅ UserDefaults saved Cache Updated: User data saved to UserDefaults.")
        } catch {
            print("❌ UserDefaults : Cache Save Failed: \(error.localizedDescription)")
        }
    }

    /// Loads the User object from UserDefaults.
    func loadUserFromUserDefaults() -> User? {
        guard let data = UserDefaults.standard.data(forKey: kUserProfileCacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let cachedUser = try decoder.decode(User.self, from: data)
            print("✅ Successfully get data from user default ")
            return cachedUser
        } catch {
            print("⚠️ decoding from user default userdata Failed: Could not decode data.")
            return nil
        }
    }

    // MARK: - ☁️ Upload Profile Image

    func uploadProfileImage(_ image: UIImage) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("user_profile_images/\(filename)")

        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
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
            saveUserToUserDefaults(user)
            self.user = user

            print("✅ User Profile updated Firestore & Cache Saved Update Success.")

        } catch {
            print("❌ Update Error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 🔄 Smart Retry Logic

    /// Called when Internet connection is restored.
    func fetchUserProfileIfNeeded() {
        // Check if we already have fresh network data for this session
        print("🔴 isUserUpdatedAtCurrentAppLaunch : \(isUserUpdatedAtCurrentAppLaunch)")
        if isUserUpdatedAtCurrentAppLaunch {
            print("✅ Data is already fresh. Do not need to fetch new user data ❌ skipping fetchUserProfileIfNeeded retry.")
            return
        }

        print("🔄 Internet back! Syncing latest data...")

        Task {
            do {
                let _ = try await fetchCurrentUser()
                // 'fetchCurrentUser' automatically updates self.user and saves to cache
                UserDataManager.shared.isUserUpdatedAtCurrentAppLaunch = true
                print("🔴 isUserUpdatedAtCurrentAppLaunch : \(isUserUpdatedAtCurrentAppLaunch)")
            } catch {
                print("🔴 User not found : \(error.localizedDescription)")
                let _ = AuthManager.shared.signOut()
                UtilsProject.logoutAndNavigateToLoginVC()
            }
        }
    }
}
