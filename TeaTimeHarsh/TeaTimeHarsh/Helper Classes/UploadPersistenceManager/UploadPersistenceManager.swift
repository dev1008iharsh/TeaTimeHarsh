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

    // Existing Server URLs (Stored to allow skipping upload if already done)
    let existingImageURL: String?
    let existingVideoURL: String?
    let existingThumbURL: String?
    let existingPDFURL: String?

    // Local File Paths (Saved in Documents Directory)
    let localImagePath: String?
    let localVideoPath: String?
    let localPDFPath: String?

    // State Tracking
    let hasSelectedNewImage: Bool

    // Track uploaded URLs for cleanup on Discard
    var uploadedDraftURLs: [String] = []
}

// MARK: - 2. Manager Class

class UploadPersistenceManager {
    static let shared = UploadPersistenceManager()
    private let kPendingKey = "kPendingUploadData_V1"
    private(set) var kGlobalDraftLinksKey = "kGlobalDraftMediaLinks_V1"

    // Get Documents Directory
    private var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func removeDraftsMediaUserDefaultKey() {
        if UserDefaults.standard.object(forKey: kGlobalDraftLinksKey) != nil {
            UserDefaults.standard.removeObject(forKey: kGlobalDraftLinksKey)
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Save Draft 💾

    func saveUploadState(
        isEditMode: Bool, placeID: String?, name: String, desc: String,
        website: String, phone: String, address: String, rating: Double,
        location: String?, price: String?, open: String?, close: String?, holiday: String?,
        lat: Double?, long: Double?, existingImg: String?, existingVid: String?,
        existingThumb: String?, existingPDF: String?, newImage: UIImage?,
        newVideoURL: URL?, newPDFURL: URL?, hasSelectedNewImage: Bool
    ) {
        // ✅ OPTIMIZATION: Use the stable PlaceID for local filenames too.
        let stableID = placeID ?? UUID().uuidString

        // 1. Save Image to Disk (Overwrite local file)
        var savedImgPath: String?

        // Logic: If user selected NEW image, save it.
        if let img = newImage, let data = img.jpegData(compressionQuality: 0.8) {
            savedImgPath = "\(stableID)_local_img.jpg"
            try? data.write(to: documentsDirectory.appendingPathComponent(savedImgPath!))
        }
        // Logic: If NO new image, keep the old local path from previous draft (if exists)
        else if let oldDraft = getPendingUpload(), let oldPath = oldDraft.localImagePath {
            savedImgPath = oldPath
        }

        // 2. Save Video to Disk (Smart Copy) 🧠
        var savedVidPath: String?
        if let vURL = newVideoURL {
            savedVidPath = "\(stableID)_local_vid.mp4"
            let targetURL = documentsDirectory.appendingPathComponent(savedVidPath!)

            // 🛑 SAFETY CHECK: Don't delete/copy if Source == Target (Fixes "File Not Found" bug on Resume)
            if vURL.absoluteString != targetURL.absoluteString {
                try? FileManager.default.removeItem(at: targetURL) // Remove old before copy
                try? FileManager.default.copyItem(at: vURL, to: targetURL)
                print("💾 Video copied to draft storage.")
            } else {
                print("⏭️ Video already in draft storage. Skipping copy.")
            }
        }

        // 3. Save PDF to Disk (Smart Copy) 🧠
        var savedPDFPath: String?
        if let pURL = newPDFURL {
            savedPDFPath = "\(stableID)_local_menu.pdf"
            let targetURL = documentsDirectory.appendingPathComponent(savedPDFPath!)

            // 🛑 SAFETY CHECK: Don't delete/copy if Source == Target
            if pURL.absoluteString != targetURL.absoluteString {
                try? FileManager.default.removeItem(at: targetURL)
                try? FileManager.default.copyItem(at: pURL, to: targetURL)
                print("💾 PDF copied to draft storage.")
            } else {
                print("⏭️ PDF already in draft storage. Skipping copy.")
            }
        }

        // 4. Create Model
        let model = PendingUploadModel(
            isEditMode: isEditMode, placeID: placeID,
            name: name, desc: desc, website: website, phone: phone, addressLabel: address, rating: rating,
            city: location, priceRange: price, openingTime: open, closingTime: close, holiday: holiday,
            latitude: lat, longitude: long,

            // ✅ FIX HERE: The parameter name is 'existingThumbURL', NOT 'existingThumb'
            existingImageURL: existingImg,
            existingVideoURL: existingVid,
            existingThumbURL: existingThumb, // <-- This was the fix
            existingPDFURL: existingPDF,

            localImagePath: savedImgPath, localVideoPath: savedVidPath, localPDFPath: savedPDFPath,
            hasSelectedNewImage: hasSelectedNewImage
        )

        // Preserve existing tracked URLs if we are just updating text fields
        if let existing = getPendingUpload() {
            var updatedModel = model
            updatedModel.uploadedDraftURLs = existing.uploadedDraftURLs
            saveToUserDefaults(updatedModel)
        } else {
            saveToUserDefaults(model)
        }

        print("💾 Draft Saved Successfully (Local files overwritten safely)")
    }

    // MARK: - Retrieve Draft 🔍

    func getPendingUpload() -> PendingUploadModel? {
        guard let data = UserDefaults.standard.data(forKey: kPendingKey) else { return nil }
        return try? JSONDecoder().decode(PendingUploadModel.self, from: data)
    }

    // MARK: - Clear Draft 🧹 (100% MASTER CLEANUP)

    /// Clears ALL local files (Videos, PDFs, Images, Drafts), current draft, and global tracking lists.
    /// Ensures 0% memory leakage after Success or Discard.
    func clearUploadState() {
        // 1. 🧹 MASTER LOCAL STORAGE CLEANUP LOOP (The "Nuke" Approach)
        // No nitpicking. We find and destroy EVERYTHING created by AddPlaceVC.
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)

            var deletedCount = 0
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent

                // Match 1: Picker Temp Files (Handles BOTH Video and PDF prefixes explicitly)
                let isPickerFile = fileName.hasPrefix("Place_Local_Video_") ||
                    fileName.hasPrefix("Place_Local_Menu_PDF_")

                // Match 2: Draft Temp Files (Created during saveDraftState)
                let isDraftFile = fileName.hasSuffix("_local_img.jpg") ||
                    fileName.hasSuffix("_local_vid.mp4") ||
                    fileName.hasSuffix("_local_menu.pdf")

                // 💥 Nuke it if it matches ANY condition!
                if isPickerFile || isDraftFile {
                    try fileManager.removeItem(at: fileURL)
                    deletedCount += 1
                    print("🗑️ Nuke Cleanup Deleted: \(fileName)")
                }
            }
            print("✅ Disk Cleared: \(deletedCount) temporary files permanently removed from iPhone storage.")

        } catch {
            print("❌ Error during master cleanup: \(error.localizedDescription)")
        }

        // 2. 🧠 WIPE RAM & USER DEFAULTS (100% NIL STATE)
        // Removes the draft data and tracking links completely.
        UserDefaults.standard.removeObject(forKey: kPendingKey)
        UserDefaults.standard.removeObject(forKey: kGlobalDraftLinksKey)
        UserDefaults.standard.synchronize()

        print("🧹 ALL SYSTEMS CLEARED: UploadPersistenceManager is now 100% nil.")
    }

    // MARK: - Helpers 🛠️

    private func saveToUserDefaults(_ model: PendingUploadModel) {
        if let encoded = try? JSONEncoder().encode(model) {
            UserDefaults.standard.set(encoded, forKey: kPendingKey)
        }
        UserDefaults.standard.synchronize()
    }

    func getFullURL(for filename: String?) -> URL? {
        guard let name = filename else { return nil }
        return documentsDirectory.appendingPathComponent(name)
    }

    // MARK: - Asset Tracking 🛡️

    func getUploadedDraftMediaURLs() -> [String] {
        return UserDefaults.standard.stringArray(forKey: kGlobalDraftLinksKey) ?? []
    }

    func addUploadedDraftURLs(_ url: String) {
        guard var currentDraft = getPendingUpload() else { return }

        if !currentDraft.uploadedDraftURLs.contains(url) {
            currentDraft.uploadedDraftURLs.append(url)

            var globalList = UserDefaults.standard.stringArray(forKey: kGlobalDraftLinksKey) ?? []
            if !globalList.contains(url) {
                globalList.append(url)
                UserDefaults.standard.set(globalList, forKey: kGlobalDraftLinksKey)
            }
            saveToUserDefaults(currentDraft)
            print("🔗 Draft URL Tracked: \(url)")
        }
    }
}

// MARK: - Partial Update Helpers (Crucial for Smart Resume) 🔄

extension UploadPersistenceManager {
    func updateDraftImageURL(_ url: String) {
        guard let currentDraft = getPendingUpload() else { return }

        let updatedDraft = PendingUploadModel(
            isEditMode: currentDraft.isEditMode, placeID: currentDraft.placeID,
            name: currentDraft.name, desc: currentDraft.desc, website: currentDraft.website, phone: currentDraft.phone, addressLabel: currentDraft.addressLabel, rating: currentDraft.rating,
            city: currentDraft.city, priceRange: currentDraft.priceRange, openingTime: currentDraft.openingTime, closingTime: currentDraft.closingTime, holiday: currentDraft.holiday,
            latitude: currentDraft.latitude, longitude: currentDraft.longitude,

            existingImageURL: url, // ✅ Updated

            existingVideoURL: currentDraft.existingVideoURL, existingThumbURL: currentDraft.existingThumbURL, existingPDFURL: currentDraft.existingPDFURL,
            localImagePath: currentDraft.localImagePath, localVideoPath: currentDraft.localVideoPath, localPDFPath: currentDraft.localPDFPath,
            hasSelectedNewImage: currentDraft.hasSelectedNewImage,
            uploadedDraftURLs: currentDraft.uploadedDraftURLs
        )
        saveToUserDefaults(updatedDraft)
    }

    func updateDraftVideoURL(videoUrl: String?, thumbUrl: String?) {
        guard let currentDraft = getPendingUpload() else { return }

        let updatedDraft = PendingUploadModel(
            isEditMode: currentDraft.isEditMode, placeID: currentDraft.placeID,
            name: currentDraft.name, desc: currentDraft.desc, website: currentDraft.website, phone: currentDraft.phone, addressLabel: currentDraft.addressLabel, rating: currentDraft.rating,
            city: currentDraft.city, priceRange: currentDraft.priceRange, openingTime: currentDraft.openingTime, closingTime: currentDraft.closingTime, holiday: currentDraft.holiday,
            latitude: currentDraft.latitude, longitude: currentDraft.longitude,

            existingImageURL: currentDraft.existingImageURL,

            existingVideoURL: videoUrl ?? currentDraft.existingVideoURL, // ✅ Updated
            existingThumbURL: thumbUrl ?? currentDraft.existingThumbURL, // ✅ Updated

            existingPDFURL: currentDraft.existingPDFURL,
            localImagePath: currentDraft.localImagePath, localVideoPath: currentDraft.localVideoPath, localPDFPath: currentDraft.localPDFPath,
            hasSelectedNewImage: currentDraft.hasSelectedNewImage,
            uploadedDraftURLs: currentDraft.uploadedDraftURLs
        )
        saveToUserDefaults(updatedDraft)
    }

    func updateDraftPDFURL(_ url: String) {
        guard let currentDraft = getPendingUpload() else { return }

        let updatedDraft = PendingUploadModel(
            isEditMode: currentDraft.isEditMode, placeID: currentDraft.placeID,
            name: currentDraft.name, desc: currentDraft.desc, website: currentDraft.website, phone: currentDraft.phone, addressLabel: currentDraft.addressLabel, rating: currentDraft.rating,
            city: currentDraft.city, priceRange: currentDraft.priceRange, openingTime: currentDraft.openingTime, closingTime: currentDraft.closingTime, holiday: currentDraft.holiday,
            latitude: currentDraft.latitude, longitude: currentDraft.longitude,

            existingImageURL: currentDraft.existingImageURL, existingVideoURL: currentDraft.existingVideoURL, existingThumbURL: currentDraft.existingThumbURL,

            existingPDFURL: url, // ✅ Updated

            localImagePath: currentDraft.localImagePath, localVideoPath: currentDraft.localVideoPath, localPDFPath: currentDraft.localPDFPath,
            hasSelectedNewImage: currentDraft.hasSelectedNewImage,
            uploadedDraftURLs: currentDraft.uploadedDraftURLs
        )
        saveToUserDefaults(updatedDraft)
    }
}
