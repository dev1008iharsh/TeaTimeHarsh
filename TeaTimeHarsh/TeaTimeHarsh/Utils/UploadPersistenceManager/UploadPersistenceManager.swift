//
//  UploadPersistenceManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/02/26.
//

import UIKit

// MARK: - 1. Data Model (Codable)
struct PendingUploadModel: Codable {
    // Logic Flags
    let isEditMode: Bool
    let placeID: String?
    
    // UI Data (Text)
    let name: String
    let desc: String
    let website: String
    let phone: String
    let addressLabel: String
    let rating: Double
    
    // Dropdowns
    let city: String?
    let priceRange: String?
    let openingTime: String?
    let closingTime: String?
    let holiday: String?
    
    // Map Data
    let latitude: Double?
    let longitude: Double?
    
    // Existing Server URLs (For Edit Mode)
    let existingImageURL: String?
    let existingVideoURL: String?
    let existingThumbURL: String?
    let existingPDFURL: String?
    
    // Local File Paths (Saved in Documents Directory)
    let localImagePath: String? // We save image as file, not Data in UserDefaults
    let localVideoPath: String?
    let localPDFPath: String?
    
    // State Tracking
    let hasSelectedNewImage: Bool
}

// MARK: - 2. Manager Class
class UploadPersistenceManager {
    static let shared = UploadPersistenceManager()
    private let kPendingKey = "kPendingUploadData_V3"
    
    // Get Documents Directory
    private var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Save Draft 💾
    func saveUploadState(
        isEditMode: Bool,
        placeID: String?,
        name: String, desc: String, website: String, phone: String, address: String,rating : Double,
        location: String?, price: String?, open: String?, close: String?, holiday: String?,
        lat: Double?, long: Double?,
        existingImg: String?, existingVid: String?, existingThumb: String?, existingPDF: String?,
        newImage: UIImage?, newVideoURL: URL?, newPDFURL: URL?,
        hasSelectedNewImage: Bool
    ) {
        let id = UUID().uuidString
        
        // 1. Save Image to Disk
        var savedImgPath: String?
        if let img = newImage, let data = img.jpegData(compressionQuality: 0.8) {
            savedImgPath = "\(id)_draft_img.jpg"
            try? data.write(to: documentsDirectory.appendingPathComponent(savedImgPath!))
        }
        
        // 2. Save Video to Disk (Copy from Tmp to Doc)
        var savedVidPath: String?
        if let vURL = newVideoURL {
            savedVidPath = "\(id)_draft_vid.mp4"
            let targetURL = documentsDirectory.appendingPathComponent(savedVidPath!)
            try? FileManager.default.removeItem(at: targetURL) // Clear if exists
            try? FileManager.default.copyItem(at: vURL, to: targetURL)
        }
        
        // 3. Save PDF to Disk
        var savedPDFPath: String?
        if let pURL = newPDFURL {
            savedPDFPath = "\(id)_draft.pdf"
            let targetURL = documentsDirectory.appendingPathComponent(savedPDFPath!)
            try? FileManager.default.removeItem(at: targetURL)
            try? FileManager.default.copyItem(at: pURL, to: targetURL)
        }
         
        // 4. Create Model
        let model = PendingUploadModel(
            isEditMode: isEditMode, placeID: placeID,
            name: name, desc: desc, website: website, phone: phone, addressLabel: address, rating: rating,
            city: location, priceRange: price, openingTime: open, closingTime: close, holiday: holiday,
            latitude: lat, longitude: long,
            existingImageURL: existingImg, existingVideoURL: existingVid, existingThumbURL: existingThumb, existingPDFURL: existingPDF,
            localImagePath: savedImgPath, localVideoPath: savedVidPath, localPDFPath: savedPDFPath,
            hasSelectedNewImage: hasSelectedNewImage
        )
        
        // 5. Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(model) {
            UserDefaults.standard.set(encoded, forKey: kPendingKey)
            UserDefaults.standard.synchronize()
        }
        print("💾 Draft Saved Successfully in Documents Dir!")
    }
    
    // MARK: - Retrieve Draft 🔍
    func getPendingUpload() -> PendingUploadModel? {
        guard let data = UserDefaults.standard.data(forKey: kPendingKey) else { return nil }
        return try? JSONDecoder().decode(PendingUploadModel.self, from: data)
    }
    
    // MARK: - Clear Draft 🧹
    func clearUploadState() {
        guard let model = getPendingUpload() else { return }
        
        // Delete Local Files
        if let p = model.localImagePath { try? FileManager.default.removeItem(at: documentsDirectory.appendingPathComponent(p)) }
        if let p = model.localVideoPath { try? FileManager.default.removeItem(at: documentsDirectory.appendingPathComponent(p)) }
        if let p = model.localPDFPath { try? FileManager.default.removeItem(at: documentsDirectory.appendingPathComponent(p)) }
        
        // Remove Key
        UserDefaults.standard.removeObject(forKey: kPendingKey)
        print("🧹 Draft Cleared.")
    }
    
    // MARK: - Helper to get full URL
    func getFullURL(for filename: String?) -> URL? {
        guard let name = filename else { return nil }
        return documentsDirectory.appendingPathComponent(name)
    }
}
