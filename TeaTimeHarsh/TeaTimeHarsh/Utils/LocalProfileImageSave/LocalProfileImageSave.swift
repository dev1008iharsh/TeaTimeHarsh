//
//  LocalProfileImageSave.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 09/01/26.
//

import UIKit

final class LocalProfileImageSave {
    
    // 🌍 Singleton: Use one shared instance everywhere
    static let shared = LocalProfileImageSave()
    private init() {}
    
    // 📁 The fixed name of your file
    private let fileName = "my_profile_pic.jpg"
    
    // MARK: - 📍 Helper: Get the Path
    private func getDocumentDirectoryPath() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    // MARK: - 💾 Save Image
    /// call this function and pass your UIImage
    func saveImage(image: UIImage) {
        // 1. Convert Image to Data (JPEG 0.8 is good quality/size balance)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Error: Could not convert image to data.")
            return
        }
        
        // 2. Write to Disk
        do {
            let filePath = getDocumentDirectoryPath()
            try data.write(to: filePath)
            print("✅ Image saved successfully at: \(filePath.path)")
        } catch {
            print("❌ Error saving image: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 📤 Get Image
    /// call this to get the image back. Returns nil if no image is saved.
    func getSavedImage() -> UIImage? {
        let filePath = getDocumentDirectoryPath()
        
        // 1. Check if file exists
        if FileManager.default.fileExists(atPath: filePath.path) {
            // 2. Load it
            return UIImage(contentsOfFile: filePath.path)
        } else {
            print("⚠️ No local profile image found.")
            return nil
        }
    }
    
    // MARK: - 🗑️ Delete Image (Optional)
    /// Useful if user logs out
    func deleteImage() {
        let filePath = getDocumentDirectoryPath()
        try? FileManager.default.removeItem(at: filePath)
        print("🗑️ Local image deleted.")
    }
}
