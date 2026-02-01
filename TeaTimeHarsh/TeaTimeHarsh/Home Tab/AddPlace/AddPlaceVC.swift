//
//  AddPlaceVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import AVFoundation // ✅ Required for Video Thumbnail
import AVKit // 🎥 For Video Player
import GoogleMaps
import Kingfisher
// import PDFKit // 📄 For PDF Thumbnail inside View
import PhotosUI // ✅ Required for Video Picker
import QuickLook // 👁️ For Local PDF Preview
import SafariServices // 🌍 For Remote PDF URL
import UIKit
import UniformTypeIdentifiers // ✅ Required for PDF Picker

// MARK: - Enums & Protocols

enum PlaceScreenMode {
    case add
    case edit(TeaPlace) // Pass the existing object for editing
}

class AddPlaceVC: UIViewController, UITextFieldDelegate {
    // MARK: - IBOutlets

    @IBOutlet var lblAddress: UILabel!
    @IBOutlet var imgPlace: UIImageView!

    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtDesc: UITextField!
    @IBOutlet var txtWebsite: UITextField!
    @IBOutlet var txtPhone: UITextField!

    // Dropdown Fields
    @IBOutlet var txtCity: UITextField!
    @IBOutlet var txtPriceRange: UITextField!
    @IBOutlet var txtOpeningTime: UITextField!
    @IBOutlet var txtClosingTime: UITextField!
    @IBOutlet var txtHoliday: UITextField!

    @IBOutlet var mapContainerView: UIView!

    @IBOutlet var imgSelectedVideoThumbnail: UIImageView!
    @IBOutlet var videoContainerView: UIView!

    @IBOutlet var menuContainerView: UIView! // PDF Container
    @IBOutlet var imgSelectedMenu: UIImageView!

    @IBOutlet var btnSubmit: UIButton! // To change title (Submit / Update)

    // MARK: - Properties

    // Public: Set this before pushing VC
    var screenMode: PlaceScreenMode = .add

    // Private Helpers
    private var googleMapView: GMSMapView?
    var onPlaceAdded: ((Bool) -> Void)?

    // State Tracking - Image
    private var hasSelectedNewImage = false // True if user picked a new photo from gallery
    private var existingImageURL: String? // Holds the old URL in Edit mode

    // State Tracking - Video & PDF (✅ NEW)
    private var selectedVideoURL: URL?
    private var existingVideoURL: String?
    private var existingVideoThumbURL: String?

    private var selectedPDFURL: URL?
    private var existingPDFURL: String?

    // Dropdown Selections
    private var selectedCity: String?
    private var selectedPriceRange: String?
    private var selectedOpeningTime: String?
    private var selectedClosingTime: String?
    private var selectedHoliday: String?

    // Location Data
    private var selectedLatitude: Double?
    private var selectedLongitude: Double?

    // Task Management 🧵
    private var uploadTask: Task<Void, Never>?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavBar()
        setupMenuSelection()
        setupImageCofiguration()
        setupMiniMap()
        setupTextFields()
        // Configure UI based on Mode (Add vs Edit)
        configureScreenMode()

        // Setup Tap Gestures for Preview
        setupPreviewGestures()
    }

    deinit {
        print("💀 deinit AddPlaceVC is dead. Memory Free & Temp Files Cleaned!")
    }

    private func setupUI() {
        // Initial Hide (Will show if data exists later)
        videoContainerView.isHidden = true
        menuContainerView.isHidden = true
        mapContainerView.isHidden = true

        videoContainerView.layer.cornerRadius = 20
        videoContainerView.clipsToBounds = true

        menuContainerView.layer.cornerRadius = 20
        menuContainerView.clipsToBounds = true

        mapContainerView.layer.cornerRadius = 20
        mapContainerView.clipsToBounds = true
    }

    // MARK: - Mode Configuration 🛠️

    private func configureScreenMode() {
        switch screenMode {
        case .add:
            title = "Add New Place"
            btnSubmit.setTitle("Submit", for: .normal)
            // mapContainerView remains hidden

        case let .edit(place):
            title = "Edit Place"
            btnSubmit.setTitle("Update", for: .normal)

            // Show map if location exists
            if place.latitude != nil && place.longitude != nil {
                mapContainerView.isHidden = false
            }

            // 🔒 Security Check
            if place.createdByUserId != Constants.Strings.currentUserID {
                AlertHelper.showAlertHandler(
                    title: "Access Denied 🔴",
                    message: "You can only edit places created by you. This place is not created by you ❌",
                    vc: self) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                return
            }

            // Fill Data
            setupDataForEditMode(place: place)
        }
    }

    private func setupDataForEditMode(place: TeaPlace) {
        // 1. Fill Texts
        txtName.text = place.name
        txtDesc.text = place.desc
        txtWebsite.text = place.website
        txtPhone.text = place.phone
        lblAddress.text = place.address

        selectedCity = place.city
        txtCity.text = selectedCity

        selectedPriceRange = place.priceRange
        txtPriceRange.text = selectedPriceRange

        selectedOpeningTime = place.openingTime
        txtOpeningTime.text = selectedOpeningTime

        selectedClosingTime = place.closingTime
        txtClosingTime.text = selectedClosingTime

        selectedHoliday = place.holiday
        txtHoliday.text = selectedHoliday

        // 3. Set Location
        selectedLatitude = place.latitude
        selectedLongitude = place.longitude
        if let lat = place.latitude, let long = place.longitude {
            GoogleMapHelper.updateLocation(mapView: googleMapView, lat: lat, long: long, showMarker: true)
        }

        // 4. Set Image
        existingImageURL = place.imageURL
        ImageManagerKF.setImage(from: place.imageURL, into: imgPlace, placeholderName: "")

        // 5. Set Video Data
        existingVideoURL = place.videoURL
        existingVideoThumbURL = place.videoThumbnailURL

        if let thumbURL = place.videoThumbnailURL, !thumbURL.isEmpty {
            videoContainerView.isHidden = false
            ImageManagerKF.setImage(from: thumbURL, into: imgSelectedVideoThumbnail, placeholderName: "")
        }

        // 6. Set PDF Data
        existingPDFURL = place.pdfURL
        if let pdfString = place.pdfURL, let url = URL(string: pdfString) {
            menuContainerView.isHidden = false
            // Show PDF Thumbnail inside container
            showPDFPreviewInsideContainer(url: url)
        }
    }

    func setupTextFields() {
        txtName.applyDefaultStyle()
        txtDesc.applyDefaultStyle()
        txtWebsite.applyDefaultStyle()
        txtPhone.applyDefaultStyle()
        txtCity.applyDefaultStyle()
        txtPriceRange.applyDefaultStyle()
        txtOpeningTime.applyDefaultStyle()
        txtClosingTime.applyDefaultStyle()
        txtHoliday.applyDefaultStyle()
    }

    // MARK: - Save / Update Logic 🚀

    func savePlaceToFirebase() {
        print("⏳ Process Started...")

        // 1. Validation First 🛡️
        if let errorMsg = validateFields() {
            AlertHelper.showAlert(title: "Invalid Data", message: errorMsg, vc: self)
            return
        }

        // 2. Lock UI & Start Background Task 🔒
        prepareUIForUpload(isUploading: true)

        // 3. Save Draft to Persistence 💾
        saveDraftState()

        // 4. Start Async Process
        uploadTask = Task {
            do {
                // Step A: Upload Media
                let mediaURLs = try await uploadAllMedia()

                // Step B: Save to Database
                try await saveToDatabase(media: mediaURLs)

                // Step C: Success
                await handleUploadSuccess()

            } catch {
                // Step D: Failure
                await handleUploadFailure(error: error)
            }
        }
    }

    // MARK: - Upload Workers 👷‍♂️

    /// 1. Save current state to disk so we can resume if app crashes
    private func saveDraftState() {
        var placeIDValue: String?
        var isEdit = false
        let currentRating: Double
        if case let .edit(cPlace) = screenMode {
            currentRating = cPlace.rating ?? 0.0
            isEdit = true
            placeIDValue = cPlace.id
        } else {
            currentRating = 0.0
            isEdit = false
        }

        UploadPersistenceManager.shared.saveUploadState(
            isEditMode: isEdit,
            placeID: placeIDValue,
            name: txtName.text?.trimmed ?? "",
            desc: txtDesc.text?.trimmed ?? "",
            website: txtWebsite.text?.removeAllSpaces ?? "",
            phone: txtPhone.text?.removeAllSpaces ?? "",
            address: lblAddress.text?.trimmed ?? "",
            rating: currentRating,
            location: selectedCity,
            price: selectedPriceRange,
            open: selectedOpeningTime,
            close: selectedClosingTime,
            holiday: selectedHoliday,
            lat: selectedLatitude,
            long: selectedLongitude,
            existingImg: existingImageURL,
            existingVid: existingVideoURL,
            existingThumb: existingVideoThumbURL,
            existingPDF: existingPDFURL,
            newImage: hasSelectedNewImage ? imgPlace.image : nil,
            newVideoURL: selectedVideoURL,
            newPDFURL: selectedPDFURL,
            hasSelectedNewImage: hasSelectedNewImage
        )
    }

    /// 2. Heavy Lifting: Image -> Video -> PDF Uploads
    private func uploadAllMedia() async throws -> (image: String, video: String?, thumb: String?, pdf: String?) {
        // A. Image (20%)
        UploadProgressHUD.shared.titleLabel.text = "Uploading place cover image... 📸"
        var finalImageURL = existingImageURL ?? ""
        if hasSelectedNewImage, let image = imgPlace.image {
            UploadProgressHUD.shared.updateProgress(0.05)
            finalImageURL = try await FirebaseManager.shared
                .uploadImage(image, folderName: "place_cover") { progress in
                    UploadProgressHUD.shared.updateProgress(0.0 + (progress * 0.2))
                }
            UploadPersistenceManager.shared.addUploadedDraftURLs(finalImageURL)
        } else {
            UploadProgressHUD.shared.updateProgress(0.2)
        }

        // B. Video (60%)
        UploadProgressHUD.shared.titleLabel.text = "Optimising video quality for faster upload... ⚙️🎥"
        var finalVideoURL = existingVideoURL
        var finalThumbURL = existingVideoThumbURL

        if let rawVideoURL = selectedVideoURL {
            print("🎥😬 Compressing Video...")
            // Compression
            let compressedURL = await withCheckedContinuation { continuation in
                VideoHelper.compressTo720p(inputURL: rawVideoURL) { url, _ in
                    continuation.resume(returning: url)
                }
            }

            if let compressed = compressedURL {
                print("☁️⬆️ Uploading Video...")
                UploadProgressHUD.shared.titleLabel.text = "Optimising video and uploading to the cloud...🎥"
                let result = try await FirebaseManager.shared.uploadVideo(compressedVideoURL: compressed) { progress in
                    UploadProgressHUD.shared.updateProgress(0.2 + (progress * 0.6))
                }
                finalVideoURL = result.videoUrl
                finalThumbURL = result.thumbUrl
                UploadPersistenceManager.shared.addUploadedDraftURLs(result.videoUrl)
                UploadPersistenceManager.shared.addUploadedDraftURLs(result.thumbUrl)
            }
        } else {
            UploadProgressHUD.shared.updateProgress(0.8)
        }

        // C. PDF (20%)
        var finalPDFURL = existingPDFURL
        if let pdfURL = selectedPDFURL {
            print("☁️⬆️ Uploading PDF...")
            UploadProgressHUD.shared.titleLabel.text = "Uploading attached pdf document... 📄"
            finalPDFURL = try await FirebaseManager.shared.uploadPDF(pdfURL: pdfURL) { progress in
                UploadProgressHUD.shared.updateProgress(0.8 + (progress * 0.2))
            }
            UploadPersistenceManager.shared.addUploadedDraftURLs(finalPDFURL ?? "")
        } else {
            UploadProgressHUD.shared.updateProgress(1.0)
        }
        UploadProgressHUD.shared.titleLabel.text = "Saving place to server... 🥳🎉"
        return (finalImageURL, finalVideoURL, finalThumbURL, finalPDFURL)
    }

    /// 3. Create Object and Write to Firestore
    private func saveToDatabase(media: (image: String, video: String?, thumb: String?, pdf: String?)) async throws {
        let placeToSave = constructTeaPlaceObject(
            imageURL: media.image,
            videoURL: media.video,
            videoThumbURL: media.thumb,
            pdfURL: media.pdf
        )

        print("*** ⬆️ SENDING TEXT BASED DATA AFTER UPLOAD - Save To Firebase API Params :", placeToSave)
        try await performDatabaseOperation(place: placeToSave)
    }

    // MARK: - Success / Error Handling

    private func handleUploadSuccess() async {
        await MainActor.run {
            // ✅ Success: Clean the draft
            UploadPersistenceManager.shared.clearUploadState()

            prepareUIForUpload(isUploading: false)
            HapticHelper.success()

            AlertHelper.showAlertHandler(title: "Success ✅", message: getSuccessMessage(), vc: self) { _ in
                self.onPlaceAdded?(true)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func handleUploadFailure(error: Error) async {
        await MainActor.run {
            // ❌ Error: Do NOT clear draft (User can retry)
            prepareUIForUpload(isUploading: false)
            HapticHelper.error()
            print("❌ Save Error: \(error.localizedDescription)")
            AlertHelper.showAlert(title: "Error", message: error.localizedDescription, vc: self)
        }
    }

    // UI Locker Helper - Fixed for Background Safety
    private func prepareUIForUpload(isUploading: Bool) {
        if isUploading {
            // 1. Request Background Time with Expiration Handler 🛡️
            backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
                print("⚠️ Background time expired! Cancelling upload task to prevent crash.")
                // Force cancel the async task if OS says time is up
                self?.uploadTask?.cancel()
                self?.endBackgroundTask()
            }

            guard let window = view.window else { return }
            UploadProgressHUD.shared.show(on: window)

            // Lock UI
            navigationItem.hidesBackButton = true
            view.isUserInteractionEnabled = false

        } else {
            // 2. Cleanup: Success or Error
            endBackgroundTask()
            UploadProgressHUD.shared.dismiss()

            // Unlock UI
            navigationItem.hidesBackButton = false
            view.isUserInteractionEnabled = true
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - Public: Restore from Draft

    func restoreFromDraft(model: PendingUploadModel) {
        // 1. Restore Mode 🚩
        if model.isEditMode, let id = model.placeID {
            // Create a dummy TeaPlace object to satisfy the .edit enum case.
            // We use the ID from the draft and current User ID to maintain ownership.
            let dummyPlace = TeaPlace(
                id: id,
                name: model.name,
                desc: model.desc,
                website: model.website,
                phone: model.phone,
                city: model.city,
                address: model.addressLabel,
                latitude: model.latitude,
                longitude: model.longitude,
                imageURL: model.existingImageURL ?? "",
                videoURL: model.existingVideoURL,
                videoThumbnailURL: model.existingThumbURL,
                pdfURL: model.existingPDFURL,
                rating: model.rating,
                totalReviewCount: 0, // Default for dummy
                priceRange: model.priceRange,
                openingTime: model.openingTime,
                closingTime: model.closingTime,
                holiday: model.holiday,
                createdByUserId: Constants.Strings.currentUserID,
                createdAt: Date()
            )
            screenMode = .edit(dummyPlace)

            // UI Update for Edit Mode
            btnSubmit.setTitle("Update", for: .normal)
        } else {
            screenMode = .add
            btnSubmit.setTitle("Submit", for: .normal)
        }

        // 2. Restore UI Text 📝
        txtName.text = model.name
        txtDesc.text = model.desc
        txtWebsite.text = model.website
        txtPhone.text = model.phone
        lblAddress.text = model.addressLabel

        // 3. Restore Dropdowns 🔽
        selectedCity = model.city; txtCity.text = model.city
        selectedPriceRange = model.priceRange; txtPriceRange.text = model.priceRange
        selectedOpeningTime = model.openingTime; txtOpeningTime.text = model.openingTime
        selectedClosingTime = model.closingTime; txtClosingTime.text = model.closingTime
        selectedHoliday = model.holiday; txtHoliday.text = model.holiday

        // 4. Restore Map 📍
        selectedLatitude = model.latitude
        selectedLongitude = model.longitude
        if let lat = selectedLatitude, let long = selectedLongitude {
            mapContainerView.isHidden = false
            GoogleMapHelper.updateLocation(mapView: googleMapView, lat: lat, long: long, showMarker: true)
        }

        // 5. Restore Media 🎥

        // A. Image
        hasSelectedNewImage = model.hasSelectedNewImage
        if let localImgPath = model.localImagePath,
           let fullURL = UploadPersistenceManager.shared.getFullURL(for: localImgPath),
           let img = UIImage(contentsOfFile: fullURL.path) {
            imgPlace.image = img
        } else if let remoteImg = model.existingImageURL {
            existingImageURL = remoteImg

            // Use .forceRefresh to ignore local cache and fetch latest from server
            imgPlace.kf.setImage(
                with: URL(string: remoteImg),
                options: [.forceRefresh]
            )
        }

        // B. Video
        existingVideoURL = model.existingVideoURL
        existingVideoThumbURL = model.existingThumbURL

        if let localVidPath = model.localVideoPath,
           let fullURL = UploadPersistenceManager.shared.getFullURL(for: localVidPath) {
            // Check if the permanent video file actually exists on disk
            if FileManager.default.fileExists(atPath: fullURL.path) {
                // Restore Selection
                selectedVideoURL = fullURL
                videoContainerView.isHidden = false

                // Generate Thumbnail in background
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let thumb = VideoHelper.generateThumbnail(from: fullURL)
                    DispatchQueue.main.async {
                        self?.imgSelectedVideoThumbnail.image = thumb
                    }
                }
            } else {
                // File missing on disk, keep UI hidden
                selectedVideoURL = nil
                videoContainerView.isHidden = true
                print("⚠️ Video file missing on disk, keeping container hidden.")
            }
        }

        // C. PDF
        existingPDFURL = model.existingPDFURL

        if let localPDFPath = model.localPDFPath,
           let fullURL = UploadPersistenceManager.shared.getFullURL(for: localPDFPath) {
            // Check if the permanent PDF file actually exists on disk
            if FileManager.default.fileExists(atPath: fullURL.path) {
                selectedPDFURL = fullURL
                menuContainerView.isHidden = false
                showPDFPreviewInsideContainer(url: fullURL)
            } else {
                // File missing on disk, keep UI hidden
                selectedPDFURL = nil
                menuContainerView.isHidden = true
                print("⚠️ PDF file missing on disk, keeping container hidden.")
            }
        }

        print("✅ UI Restored from Draft successfully! Mode: \(model.isEditMode ? "Edit" : "Add")")
    }

    private func constructTeaPlaceObject(imageURL: String, videoURL: String?, videoThumbURL: String?, pdfURL: String?) -> TeaPlace {
        // Strings where we only need to trim start/end spaces
        let nameTrimmed = txtName.text?.trimmed ?? ""
        let addressTrimmed = lblAddress.text?.trimmed ?? "" // Assuming you have address
        let descTrimmed = txtDesc.text?.trimmed ?? ""
        let cityTrimmed = selectedCity?.trimmed

        // Technical fields where NO spaces are allowed at all
        let phoneCleaned = txtPhone.text?.removeAllSpaces ?? ""
        var website = txtWebsite.text?.removeAllSpaces ?? ""

        // 3. Website Protocol Logic
        if !website.isEmpty {
            // Ensure website has a valid protocol for Safari
            if !website.lowercased().hasPrefix("http://") && !website.lowercased().hasPrefix("https://") {
                website = "https://" + website
            }
        }

        switch screenMode {
        case .add:
            var newPlace = TeaPlace(
                id: UUID().uuidString,
                name: nameTrimmed,
                desc: descTrimmed,
                website: website,
                phone: phoneCleaned,
                city: cityTrimmed,
                address: addressTrimmed,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                imageURL: imageURL,
                videoURL: videoURL,
                videoThumbnailURL: videoThumbURL,
                pdfURL: pdfURL,
                rating: 0.0,
                totalReviewCount: 0,
                priceRange: selectedPriceRange,
                openingTime: selectedOpeningTime,
                closingTime: selectedClosingTime,
                holiday: selectedHoliday,
                createdByUserId: Constants.Strings.currentUserID,
                createdAt: Date()
            )
            // Set Defaults
            newPlace.isFav = false
            newPlace.isVisited = false
            return newPlace

        case let .edit(existingPlace):
            // Update existing object (Keep ID & Owner same)
            return TeaPlace(
                id: existingPlace.id, // KEEP ID
                name: nameTrimmed,
                desc: descTrimmed,
                website: website,
                phone: phoneCleaned,
                city: cityTrimmed,
                address: addressTrimmed,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                imageURL: imageURL,
                videoURL: videoURL,
                videoThumbnailURL: videoThumbURL,
                pdfURL: pdfURL,

                // ⚠️ Keep Old Rating & Counts
                rating: existingPlace.rating,
                totalReviewCount: existingPlace.totalReviewCount,

                priceRange: selectedPriceRange,
                openingTime: selectedOpeningTime,
                closingTime: selectedClosingTime,
                holiday: selectedHoliday,
                createdByUserId: existingPlace.createdByUserId, // KEEP OWNER
                createdAt: existingPlace.createdAt // KEEP TIME
            )
        }
    }

    private func performDatabaseOperation(place: TeaPlace) async throws {
        switch screenMode {
        case .add:
            try await FirebaseManager.shared.addNewPlace(place: place)
        case .edit:
            try await FirebaseManager.shared.updatePlace(place: place)
        }
    }

    private func getSuccessMessage() -> String {
        let isUpdate = btnSubmit.title(for: .normal) == "Update"
        let action = isUpdate ? "Updated" : "Added"
        let emoji = isUpdate ? "✨" : "🎉"

        return """
        Place \(action) Successfully! \(emoji) 
        🔒 Note: You are the owner of this spot. Only you can edit or delete it; others can only view it.
        """
    }

    // MARK: - UI & Validation 🛡️

    private func validateFields() -> String? {
        // 1. 🖼️ Image Validation (Moved Here)
        // Add Mode: User MUST select a new image.
        // Edit Mode: We assume existing image is there, so validation passes.
        if case .add = screenMode, !hasSelectedNewImage {
            return "Please select a cover image for this place 🖼️"
        }

        // 2. 📝 Text Fields Validation
        guard let name = txtName.text?.trimmed, !name.isEmpty else { return "Please enter tea place name" }
        guard let desc = txtDesc.text?.trimmed, !desc.isEmpty else { return "Please enter description" }

        guard let phone = txtPhone.text?.removeAllSpaces, phone.count == 10, phone.isNumeric else {
            return "Enter valid 10-digit contact number"
        }
        guard let website = txtWebsite.text?.removeAllSpaces, website.isEmpty || website.isValidWebsite else { return "Enter valid website starting with www. or https and ending with domain name." }

        // 3. 📍 Dropdown & Location Validation
        guard selectedCity != nil else { return "Please select city" }
        guard selectedPriceRange != nil else { return "Please select price range" }
        guard selectedOpeningTime != nil else { return "Please select opening time" }
        guard selectedClosingTime != nil else { return "Please select closing time" }
        guard selectedHoliday != nil else { return "Please select holiday" }
        guard selectedLatitude != nil, selectedLongitude != nil else { return "Please select location on map" }

        // 4. 🎥 Video Validation (Mandatory)
        // Logic: Pass if (New Video Selected) OR (Edit Mode AND Old Video Exists)
        let hasVideo = selectedVideoURL != nil || (existingVideoURL != nil && !existingVideoURL!.isEmpty)
        if !hasVideo {
            return "Please select a video to upload. It is mandatory 🎥"
        }

        // 5. 📄 PDF Validation (Mandatory)
        // Logic: Pass if (New PDF Selected) OR (Edit Mode AND Old PDF Exists)
        let hasPDF = selectedPDFURL != nil || (existingPDFURL != nil && !existingPDFURL!.isEmpty)
        if !hasPDF {
            return "Please select a place menu in PDF document. It is mandatory 📄"
        }

        return nil // ✅ All Good!
    }

    // MARK: - Helper: Clear Temp File 🧹

    private func clearStoredFile(at url: URL?) {
        guard let url = url else { return }

        // Final check: Only delete if the file exists at the given path
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                print("🧹 File deleted from Documents: \(url.lastPathComponent)")
            } catch {
                print("❌ Error: Failed to delete stored file: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Info: Cleanup skipped, file not found at path.")
        }
    }

    // MARK: - Helper: PDF Preview Inside Container 📄

    private func showPDFPreviewInsideContainer(url: URL) {
        // 1. UI Preparation
        menuContainerView.isHidden = false
        menuContainerView.layoutIfNeeded() // Ensure we have correct bounds for thumbnail

        LoaderManager.shared.startLoading()

        // Initial state before thumbnail is ready
        imgSelectedMenu.image = nil
        imgSelectedMenu.alpha = 0

        // Calculate size for the thumbnail generator
        var targetSize = menuContainerView.bounds.size

        // Handle zero size case if view is just being unhidden
        if targetSize.width == 0 {
            let screenWidth = UIScreen.main.bounds.width
            targetSize = CGSize(width: screenWidth - 40, height: 150)
        }

        // 2. Generate Thumbnail in Background ⚡️
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // ✅ Generate Thumbnail using your PDFHelper
            if let thumbnail = PDFHelper.generateTwoPageThumbnail(of: targetSize, for: url) {
                DispatchQueue.main.async {
                    // 3. Update UI on Main Thread
                    self.imgSelectedMenu.image = thumbnail

                    UIView.animate(withDuration: 0.3) {
                        self.imgSelectedMenu.alpha = 1
                    }
                    LoaderManager.shared.stopLoading()
                }
            } else {
                DispatchQueue.main.async {
                    LoaderManager.shared.stopLoading()
                    print("❌ Failed to generate PDF thumbnail")
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func btnSubmitTapped(_ sender: UIButton) {
        HapticHelper.success()
        view.endEditing(true)
        if let errorMsg = validateFields() {
            AlertHelper.showAlert(title: "Invalid Data", message: errorMsg, vc: self)
            return
        }
        guard AppNetworkManager.shared.isConnected else {
            AlertHelper.showAlert(title: "No Internet 🛜", message: "Please connect to the internet to perform action on add place screen.", vc: self)
            return
        }
        savePlaceToFirebase()
    }

    @IBAction func btnSelectLocationMap(_ sender: UIButton) {
        HapticHelper.medium()
        guard AppNetworkManager.shared.isConnected else {
            AlertHelper.showAlert(title: "No Internet 🛜", message: "Please connect to the internet to open map screen and select location from map 📍.", vc: self)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mapVC = storyboard.instantiateViewController(withIdentifier: "SelectPlaceOnMapVC") as? SelectPlaceOnMapVC else { return }

        if let lat = selectedLatitude, let long = selectedLongitude {
            mapVC.alreadySelectedLatitude = lat
            mapVC.alreadySelectedLongitude = long
        }
        mapVC.delegateMap = self
        navigationController?.pushViewController(mapVC, animated: true)
    }

    @IBAction func btnSelectVideo(_ sender: UIButton) {
        HapticHelper.light()
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - PDF Selection Action

    @IBAction func btnSelectMenu(_ sender: UIButton) {
        HapticHelper.light()

        // Strictly allow only PDF
        let supportedTypes: [UTType] = [.pdf]

        // ✅ asCopy: true
        // This creates a copy in tmp folder automatically, so no permission issues.
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false

        present(documentPicker, animated: true)
    }

    @IBAction func btnRemoveSelectVideo(_ sender: UIButton) {
        HapticHelper.medium()

        AlertHelper.showConfirmationAlert(
            title: "Remove Video? 🎥",
            message: "Are you sure you want to remove this video? This action cannot be undone.🔴",
            vc: self,
            rightBtnTitle: "Remove",
            rightBtnStyle: .destructive,
            leftBtnTitle: "Cancel",
            leftBtnStyle: .cancel,
            rightAction: { _ in
                self.performRemoveVideo()
            },
            leftAction: { _ in
                print("User cancelled video removal")
            }
        )
    }

    @IBAction func btnRemoveSelectMenu(_ sender: UIButton) {
        HapticHelper.medium()

        AlertHelper.showConfirmationAlert(
            title: "Remove PDF? 📄",
            message: "Are you sure you want to remove this PDF document? This action cannot be undone.🔴",
            vc: self,
            rightBtnTitle: "Remove",
            rightBtnStyle: .destructive,
            leftBtnTitle: "Cancel",
            leftBtnStyle: .cancel,
            rightAction: { _ in
                self.performRemovePDF()
            },
            leftAction: { _ in
                print("User cancelled PDF removal")
            }
        )
    }

    private func performRemovePDF() {
        // Cleanup physical file from Documents folder
        clearStoredFile(at: selectedPDFURL)

        // Reset Variables
        selectedPDFURL = nil
        existingPDFURL = nil // Edit mode removal

        // Hide UI
        menuContainerView.isHidden = true
        imgSelectedMenu.image = nil

        print("🗑️❌ PDF Permanent File Removed")
    }

    private func performRemoveVideo() {
        // Cleanup physical file from Documents folder
        clearStoredFile(at: selectedVideoURL)

        selectedVideoURL = nil
        existingVideoURL = nil // Edit mode removal

        // Hide UI
        videoContainerView.isHidden = true
        imgSelectedVideoThumbnail.image = nil
        print("🗑️❌ Video Permanent File Removed")
    }

    // MARK: - Preview Logic 👁️

    private func setupPreviewGestures() {
        // 1. Video Tap Gesture
        let videoTap = UITapGestureRecognizer(target: self, action: #selector(didTapVideoPreview))
        videoContainerView.isUserInteractionEnabled = true
        videoContainerView.addGestureRecognizer(videoTap)

        // 2. PDF Tap Gesture
        let pdfTap = UITapGestureRecognizer(target: self, action: #selector(didTapPDFPreview))
        menuContainerView.isUserInteractionEnabled = true
        menuContainerView.addGestureRecognizer(pdfTap)
    }

    @objc private func didTapVideoPreview() {
        HapticHelper.light()

        // 1. Check if we have a NEW local video selected
        if let localURL = selectedVideoURL {
            playVideo(url: localURL)
        }
        // 2. Else, check if we have an EXISTING remote video
        else if let remoteString = existingVideoURL, let remoteURL = URL(string: remoteString) {
            playVideo(url: remoteURL)
        }
    }

    @objc private func didTapPDFPreview() {
        HapticHelper.light()

        // 1. Check if New Local PDF
        if selectedPDFURL != nil {
            // Open QuickLook for Local File
            let previewController = QLPreviewController()
            previewController.dataSource = self
            present(previewController, animated: true)
        }
        // 2. Check if Existing Remote PDF
        else if let remoteString = existingPDFURL, let remoteURL = URL(string: remoteString) {
            // Open Safari Controller for Remote URL
            let safariVC = SFSafariViewController(url: remoteURL)
            present(safariVC, animated: true)
        }
    }

    private func playVideo(url: URL) {
        print("▶️ Playing Video: \(url.absoluteString)")
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true) {
            player.play()
        }
    }

    // MARK: - UI & Validation

    // Setup Methods
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancelBarButton))
    }

    @objc private func didTapCancelBarButton() {
        showDiscardAlert()
    }

    private func setupMiniMap() {
        googleMapView = GoogleMapHelper.initializeMap(in: mapContainerView, enableGestures: false, showLocationButton: false, showCompass: false, showIndoorPicker: false, enableTraffic: false, showUserLocation: false)
    }

    private func setupImageCofiguration() {
        imgPlace.layer.cornerRadius = 20
        imgPlace.clipsToBounds = true
        imgPlace.contentMode = .scaleAspectFill
        imgPlace.backgroundColor = .secondarySystemBackground
        imgPlace.image = UIImage(systemName: "plus")
        imgPlace.tintColor = .secondaryLabel
        imgPlace.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPlaceImage))
        imgPlace.addGestureRecognizer(tap)
    }

    @objc private func didTapPlaceImage() {
        HapticHelper.light()
        ImagePickerManager.shared.pickSingleImage(from: self) { [weak self] selectedImage in
            guard let self = self, let image = selectedImage else { return }

            // Mark as CHANGED so we know to upload it later
            self.hasSelectedNewImage = true
            self.imgPlace.image = image
        }
    }

    private func showDiscardAlert() {
        let alert = UIAlertController(title: "Discard Changes?", message: "Unsaved changes will be lost.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in self.navigationController?.popViewController(animated: true) })
        present(alert, animated: true)
    }

    private func setupMenuSelection() {
        // Dropdown Data
        let cityOptions: [String] = ["Mumbai", "Delhi", "Bengaluru", "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad", "Surat", "Jaipur", "Lucknow", "Kanpur", "Nagpur", "Indore", "Bhopal", "Vadodara", "Noida", "Gurugram", "Chandigarh", "Patna", "Visakhapatnam", "Coimbatore", "Kochi", "Guwahati"]
        let openingTimeOptions = ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00"]
        let closingTimeOptions = ["21:00", "22:00", "23:00", "23:59"]
        let priceRangeOptions = ["0-200", "200-400", "400-600", "600-800", "800-1000", "more then 1000"]
        let holidayOptions = ["None", "Sunday", "Saturday, Sunday"]

        // Setup Bindings
        // City/Location

        txtCity.applySingleSelectionMenu(title: "Select City", items: cityOptions, selectedItem: selectedCity) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true)
            self.selectedCity = sel
        }

        // Price Range
        txtPriceRange.applySingleSelectionMenu(title: "Select price range", items: priceRangeOptions, selectedItem: selectedPriceRange) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true)
            self.selectedPriceRange = sel
        }

        //  Opening Time
        txtOpeningTime.applySingleSelectionMenu(title: "Select opening time", items: openingTimeOptions, selectedItem: selectedOpeningTime) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true)
            self.selectedOpeningTime = sel
        }

        // Closing Time
        txtClosingTime.applySingleSelectionMenu(title: "Select closing time", items: closingTimeOptions, selectedItem: selectedClosingTime) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true)
            self.selectedClosingTime = sel
        }

        // Holiday
        txtHoliday.applySingleSelectionMenu(title: "Select holiday", items: holidayOptions, selectedItem: selectedHoliday) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true)
            self.selectedHoliday = sel
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txtName:
            txtDesc.becomeFirstResponder()
        case txtDesc:
            txtWebsite.becomeFirstResponder()
        case txtWebsite:
            txtPhone.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - Map Delegate

extension AddPlaceVC: SelectPlaceOnMapVCDelegate {
    func didSelectLocation(latitude: Double, longitude: Double, address: String) {
        selectedLatitude = latitude
        selectedLongitude = longitude
        lblAddress.text = address
        mapContainerView.isHidden = false
        GoogleMapHelper.updateLocation(mapView: googleMapView, lat: latitude, long: longitude, showMarker: true)
    }
}

// MARK: - Video & PDF Pickers Delegate

extension AddPlaceVC: PHPickerViewControllerDelegate {
    // MARK: - PHPicker Entry Point

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        // 1. Validate result and provider
        guard let provider = results.first?.itemProvider,
              provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }

        LoaderManager.shared.startLoading()

        // 2. Load File Representation
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] originalURL, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Picker Error: \(error.localizedDescription)")
                DispatchQueue.main.async { LoaderManager.shared.stopLoading() }
                return
            }

            guard let url = originalURL else { return }

            // 3. Immediate Copy to Documents Directory (Permanent) 📂
            let fileName = "Place_Local_Video_\(UUID().uuidString).\(url.pathExtension)"
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let permanentURL = documentsURL.appendingPathComponent(fileName)

            do {
                if FileManager.default.fileExists(atPath: permanentURL.path) {
                    try FileManager.default.removeItem(at: permanentURL)
                }

                // Copy the ephemeral file to stable app storage
                try FileManager.default.copyItem(at: url, to: permanentURL)

                // 4. Move to processing stage using the stable URL
                self.processVideo(url: permanentURL)

            } catch {
                print("❌ Local Disk Copy Error: \(error.localizedDescription)")
                DispatchQueue.main.async { LoaderManager.shared.stopLoading() }
            }
        }
    }

    // MARK: - Video Processing Logic

    private func processVideo(url: URL) {
        // 1. File Size Validation (Fast Fail)
        if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let fileSize = resources.fileSize, fileSize > (1000 * 1024 * 1024) { // 1GB Limit
            DispatchQueue.main.async {
                LoaderManager.shared.stopLoading()
                AlertHelper.showAlert(title: "Video Too Large 📦", message: "Please select a video smaller than 1 GB.", vc: self)
                self.clearStoredFile(at: url) // Clean up if validation fails
            }
            return
        }

        // 2. Modern Swift Concurrency for Duration & Compression
        Task { [weak self] in
            guard let self = self else { return }

            let asset = AVAsset(url: url)

            do {
                // Load duration using modern async/await
                let duration = try await asset.load(.duration)

                if duration.seconds > 180 { // 3 Minutes Limit
                    await MainActor.run {
                        LoaderManager.shared.stopLoading()
                        AlertHelper.showAlert(title: "Video Too Long ⏳", message: "Please select a video shorter than 3 minutes.", vc: self)
                        self.clearStoredFile(at: url) // Clean up if validation fails
                    }
                    return
                }

                // 3. Video Compression
                // Passing the stable Documents URL to helper
                VideoHelper.compressTo720p(inputURL: url) { [weak self] compressedURL, _ in
                    guard let self = self else { return }

                    if let finalURL = compressedURL {
                        // Generate Thumbnail from the final compressed video
                        let thumb = VideoHelper.generateThumbnail(from: finalURL)

                        DispatchQueue.main.async {
                            // Note: We don't delete 'url' here if you want to keep the raw file,
                            // but usually, we cleanup raw and keep the compressed one in Documents.
                            self.clearStoredFile(at: url) // Cleanup raw local copy
                            self.clearStoredFile(at: self.selectedVideoURL) // Cleanup previous stable selection

                            // Update UI State with the new stable path
                            self.selectedVideoURL = finalURL
                            self.videoContainerView.isHidden = false
                            self.imgSelectedVideoThumbnail.image = thumb

                            print("✅ Process Complete: \(finalURL.lastPathComponent)")
                            LoaderManager.shared.stopLoading()
                        }
                    } else {
                        DispatchQueue.main.async {
                            LoaderManager.shared.stopLoading()
                            self.clearStoredFile(at: url)
                        }
                    }
                }
            } catch {
                print("❌ AVAsset Loading Error: \(error.localizedDescription)")
                await MainActor.run { LoaderManager.shared.stopLoading() }
            }
        }
    }
}

extension AddPlaceVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Note: No need for startAccessingSecurityScopedResource() because of asCopy: true

        // 1. Strict Extension Check 🛡️
        if url.pathExtension.lowercased() != "pdf" {
            // Delete the invalid file iOS created
            clearStoredFile(at: url)
            AlertHelper.showAlert(title: "Invalid File ❌", message: "Please select a valid PDF file.", vc: self)
            return
        }

        // 2. File Size Check (Max 200 MB) 📦
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                let maxSize = 200 * 1024 * 1024 // 200 MB in Bytes

                if fileSize > maxSize {
                    // 🛑 Too Large! Delete this temp file immediately
                    clearStoredFile(at: url)

                    AlertHelper.showAlert(title: "File Too Large ⚠️", message: "PDF size must be less than 200 MB.", vc: self)
                    return
                }
            }
        } catch {
            print("❌ Error checking file size: \(error.localizedDescription)")
            clearStoredFile(at: url) // Safety cleanup
            return
        }

        // ✅ 3. Success Logic (Using Permanent Documents Directory) 📂

        // Create a unique name for our permanent copy
        let fileName = "Place_Local_Menu_PDF_\(UUID().uuidString).pdf"

        // Get the Documents Directory path
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let permanentURL = documentsURL.appendingPathComponent(fileName)

        do {
            // Remove OLD PDF selection from permanent storage if exists
            if let oldURL = selectedPDFURL {
                clearStoredFile(at: oldURL)
            }

            // Copy file from picker's ephemeral location to our stable Documents location
            // This ensures the file stays even if the app restarts or back button is pressed
            try FileManager.default.copyItem(at: url, to: permanentURL)

            // Assign our new stable permanent URL
            selectedPDFURL = permanentURL

            // Clean up the picker's original temp file provided by iOS
            clearStoredFile(at: url)

            menuContainerView.isHidden = false

            // Show Preview using our own permanent copy
            showPDFPreviewInsideContainer(url: permanentURL)

            print("✅ PDF Selected & Validated (Copied to Documents): \(permanentURL.lastPathComponent)")

        } catch {
            print("❌ Local Permanent Copy Error: \(error.localizedDescription)")
            // Fallback to original URL if copy fails
            selectedPDFURL = url
            menuContainerView.isHidden = false
            showPDFPreviewInsideContainer(url: url)
        }
    }
}

// MARK: - PDF Preview Delegate 📄 (For Local QuickLook)

extension AddPlaceVC: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // Return the local file URL we selected
        return (selectedPDFURL ?? URL(string: ""))! as QLPreviewItem
    }
}
