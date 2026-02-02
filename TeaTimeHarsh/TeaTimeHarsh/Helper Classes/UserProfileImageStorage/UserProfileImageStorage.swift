//
//  UserProfileImageStorage.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 13/01/26.
//

import UIKit

final class UserProfileImageStorage {
    private static let imageFileName = "userprofileimage.png"

    /// Saves user profile image by removing previous image first
    static func saveUserProfileImage(_ image: UIImage) {
        // Remove old image if exists
        clearUserProfileImage()

        guard let data = image.pngData() else { return }

        let url = getImageFileURL()
        do {
            try data.write(to: url, options: .atomic)
            print("📸 User profile image saved successfully to local document-directory saved ✅")
        } catch {
            HapticHelper.error()
            ToastManager.shared.show(message: "⚠️ Failed to save profile image: \(error.localizedDescription)")
            print("⚠️ Failed to save profile image: \(error.localizedDescription)")
        }
    }

    /// Loads user profile image
    static func loadUserProfileImage() -> UIImage? {
        let url = getImageFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    /// Removes user profile image from storage
    static func clearUserProfileImage() {
        let url = getImageFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ Old user profile image removed")
        }
    }

    private static func getImageFileURL() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(imageFileName)
    }

    /// MARK: - Global Cleanup (Used for Logout) 🚪
    /// Wipe every single file from the Documents directory
    static func clearAllStoredFiles() {
        let fileManager = FileManager.default
        // Get the Documents directory URL
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ Documents directory not found")
            return
        }

        do {
            // Get all file URLs inside the Documents folder
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

            for url in fileURLs {
                // Remove each file physically from disk
                try fileManager.removeItem(at: url)
                print("🧹 Deleted from Documents deleting using loop: \(url.lastPathComponent)")
            }
            print("✅ Global Cleanup: Documents folder is now empty.")
        } catch {
            HapticHelper.error()
            ToastManager.shared.show(message: "❌ Global Cleanup Error: \(error.localizedDescription)")
            print("❌ Global Cleanup Error: \(error.localizedDescription)")
        }
    }
}
