//
//  AddPlaceVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import AVFoundation // ✅ Required for Video Thumbnail
import AVKit // 🎥 For Video Player
import GoogleMaps
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
    @IBOutlet var txtLocation: UITextField!
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
    private var selectedLocation: String?
    private var selectedPriceRange: String?
    private var selectedOpeningTime: String?
    private var selectedClosingTime: String?
    private var selectedHoliday: String?

    // Location Data
    private var selectedLatitude: Double?
    private var selectedLongitude: Double?

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
        // Cleanup Temp Files on Exit 🧹
        clearTempFile(at: selectedVideoURL)
        clearTempFile(at: selectedPDFURL)
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

        selectedLocation = place.location
        txtLocation.text = selectedLocation

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

        // 5. Set Video Data (✅ NEW)
        existingVideoURL = place.videoURL
        existingVideoThumbURL = place.videoThumbnailURL

        if let thumbURL = place.videoThumbnailURL, !thumbURL.isEmpty {
            videoContainerView.isHidden = false
            ImageManagerKF.setImage(from: thumbURL, into: imgSelectedVideoThumbnail, placeholderName: "")
        }

        // 6. Set PDF Data (✅ NEW)
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
        txtLocation.applyDefaultStyle()
        txtPriceRange.applyDefaultStyle()
        txtOpeningTime.applyDefaultStyle()
        txtClosingTime.applyDefaultStyle()
        txtHoliday.applyDefaultStyle()
    }

    // MARK: - Save / Update Logic 🚀

    func savePlaceToFirebase() {
        print("⏳ Process Started...")

        // 1. Show Custom Progress Loader (on Window) ⏳
        guard let window = view.window else { return }
        UploadProgressHUD.shared.show(on: window)

        Task {
            do {
                // MARK: - Step A: Image Upload (Weight: 20%) 🖼️

                var finalImageURL = existingImageURL ?? ""

                // If user picked a NEW image, upload it
                if hasSelectedNewImage, let image = imgPlace.image {
                    UploadProgressHUD.shared.updateProgress(0.05) // Started

                    finalImageURL = try await FirebaseManager.shared.uploadImage(image) { progress in
                        // Map 0-100% of image upload to 0-20% of total progress
                        let totalProgress = 0.0 + (progress * 0.2)
                        UploadProgressHUD.shared.updateProgress(totalProgress)
                    }
                } else {
                    // If reusing old image, assume this step is done
                    UploadProgressHUD.shared.updateProgress(0.2)
                }

                // MARK: - Step B: Video Processing & Upload (Weight: 60%) 🎥

                var finalVideoURL: String? = existingVideoURL // Keep old if editing
                var finalThumbURL: String? = existingVideoThumbURL

                if let rawVideoURL = selectedVideoURL {
                    print("🎥 Compressing Video to 720p HEVC...")

                    // 1. Compress Video (Async Wait)
                    let compressedURL = await withCheckedContinuation { continuation in
                        VideoHelper.compressTo720pHEVC(inputURL: rawVideoURL) { url in
                            continuation.resume(returning: url)
                        }
                    }

                    if let compressedVideo = compressedURL {
                        print("☁️ Uploading Video...")
                        // 2. Upload Compressed Video
                        let result = try await FirebaseManager.shared.uploadVideo(compressedVideoURL: compressedVideo) { progress in
                            // Map 0-100% of video upload to 20-80% of total progress
                            let totalProgress = 0.2 + (progress * 0.6)
                            UploadProgressHUD.shared.updateProgress(totalProgress)
                        }

                        finalVideoURL = result.videoUrl
                        finalThumbURL = result.thumbUrl
                    }
                } else {
                    // No new video selected, skip to 80%
                    UploadProgressHUD.shared.updateProgress(0.8)
                }

                // MARK: - Step C: PDF Upload (Weight: 20%) 📄

                var finalPDFURL: String? = existingPDFURL // Keep old if editing

                if let pdfURL = selectedPDFURL {
                    print("☁️ Uploading PDF...")
                    finalPDFURL = try await FirebaseManager.shared.uploadPDF(pdfURL: pdfURL) { progress in
                        // Map 0-100% of PDF upload to 80-100% of total progress
                        let totalProgress = 0.8 + (progress * 0.2)
                        UploadProgressHUD.shared.updateProgress(totalProgress)
                    }
                } else {
                    // No new PDF, progress complete (100%)
                    UploadProgressHUD.shared.updateProgress(1.0)
                }

                // MARK: - Step D: Create Object & Save 💾

                let placeToSave = constructTeaPlaceObject(
                    imageURL: finalImageURL,
                    videoURL: finalVideoURL,
                    videoThumbURL: finalThumbURL,
                    pdfURL: finalPDFURL
                )

                print("*** Save To Firebase API Params :", placeToSave)

                // Perform Database Operation (Add or Update)
                try await performDatabaseOperation(place: placeToSave)

                // MARK: - Step E: Success 🎉

                await MainActor.run {
                    UploadProgressHUD.shared.dismiss()
                    HapticHelper.success()

                    AlertHelper.showAlertHandler(
                        title: "Success ✅",
                        message: getSuccessMessage(),
                        vc: self
                    ) { _ in
                        self.onPlaceAdded?(true)
                        self.navigationController?.popViewController(animated: true)
                    }
                }

            } catch {
                // MARK: - Step F: Error Handling ❌

                await MainActor.run {
                    UploadProgressHUD.shared.dismiss() // Hide loader
                    HapticHelper.error()
                    print("❌ Save Error: \(error.localizedDescription)")
                    AlertHelper.showAlert(title: "Error", message: error.localizedDescription, vc: self)
                }
            }
        }
    }

    private func constructTeaPlaceObject(imageURL: String, videoURL: String?, videoThumbURL: String?, pdfURL: String?) -> TeaPlace {
        // Strings where we only need to trim start/end spaces
        let name = txtName.text?.trimmed ?? ""
        let address = lblAddress.text?.trimmed ?? "" // Assuming you have address
        let desc = txtDesc.text?.trimmed ?? ""
        let location = selectedLocation?.trimmed

        // Technical fields where NO spaces are allowed at all
        let phone = txtPhone.text?.removeAllSpaces ?? ""
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
                name: name,
                desc: desc,
                website: website,
                phone: phone,
                location: location,
                address: address,
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
                name: name,
                desc: desc,
                website: website,
                phone: phone,
                location: location,
                address: address,
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
        guard let website = txtWebsite.text?.removeAllSpaces, website.isEmpty || website.isValidWebsite else { return "Enter valid website starting with www. and ending with domain name." }

        // 3. 📍 Dropdown & Location Validation
        guard selectedLocation != nil else { return "Please select city location" }
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
            return "Please select a PDF document. It is mandatory 📄"
        }

        return nil // ✅ All Good!
    }

    // MARK: - Helper: Clear Temp File 🧹

    private func clearTempFile(at url: URL?) {
        guard let url = url else { return }
        do {
            try FileManager.default.removeItem(at: url)
            print("🧹 Old temp file deleted: \(url.lastPathComponent)")
        } catch {
            // It's okay if file doesn't exist
            print("⚠️ Info: Temp file cleanup skipped/failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper: PDF Preview Inside Container 📄

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

    // MARK: - Video Selection Action

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
        let supportedTypes: [UTType] = [UTType.pdf]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @IBAction func btnRemoveSelectVideo(_ sender: UIButton) {
        HapticHelper.medium()

        AlertHelper.showConfirmationAlert(
            title: "Remove Video? 🎥",
            message: "Are you sure you want to remove this video? This action cannot be undone.",
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
            message: "Are you sure you want to remove this PDF document? This action cannot be undone.",
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
        // Cleanup
        clearTempFile(at: selectedPDFURL)
        selectedPDFURL = nil
        existingPDFURL = nil // Edit mode removal

        // Hide UI
        menuContainerView.isHidden = true
        imgSelectedMenu.image = nil
        print("🗑️ PDF Removed")
    }

    private func performRemoveVideo() {
        // Cleanup
        clearTempFile(at: selectedVideoURL)
        selectedVideoURL = nil
        existingVideoURL = nil // Edit mode removal

        // Hide UI
        videoContainerView.isHidden = true
        imgSelectedVideoThumbnail.image = nil
        print("🗑️ Video Removed")
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
        let locationOptions = ["Mumbai", "Delhi", "Bengaluru", "Chennai", "Hyderabad", "Pune", "Kolkata", "Ahmedabad", "Jaipur", "Surat"]
        let openingTimeOptions = ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00"]
        let closingTimeOptions = ["21:00", "22:00", "23:00", "23:59"]
        let priceRangeOptions = ["0-200", "200-400", "400-600", "600-800", "800-1000", "more then 1000"]
        let holidayOptions = ["Sunday", "Saturday, Sunday"]

        // Setup Bindings
        // City/Location

        txtLocation.applySingleSelectionMenu(title: "Select City", items: locationOptions, selectedItem: selectedLocation) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true)
            self.selectedLocation = sel
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
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider, provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }

        // 🚀 START LOADER: Process is starting
        LoaderManager.shared.startLoading()

        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self = self else { return }

            // ⚠️ Error Handling: If URL is nil, stop loader
            guard let url = url else {
                DispatchQueue.main.async {
                    LoaderManager.shared.stopLoading()
                    print("❌ Error loading video: \(String(describing: error))")
                }
                return
            }

            // 1. Copy video to temp directory
            let fileName = "\(UUID().uuidString).mp4"
            let newURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try FileManager.default.copyItem(at: url, to: newURL)

                // 2. Generate Thumbnail (Time Consuming Task)
                let thumb = VideoHelper.generateThumbnail(from: newURL)

                DispatchQueue.main.async {
                    // 🔥 Cleanup Old File
                    self.clearTempFile(at: self.selectedVideoURL)

                    // 3. Update UI
                    self.selectedVideoURL = newURL
                    self.videoContainerView.isHidden = false

                    if let thumb = thumb {
                        self.imgSelectedVideoThumbnail.image = thumb
                    }

                    print("✅ New Video Selected: \(fileName)")

                    // 🏁 STOP LOADER: Everything is ready!
                    LoaderManager.shared.stopLoading()
                }
            } catch {
                DispatchQueue.main.async {
                    LoaderManager.shared.stopLoading()
                    print("❌ Error copying video: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension AddPlaceVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        // Copy PDF to temp
        let fileName = "\(UUID().uuidString).pdf"
        let newURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: url, to: newURL)

        // 🔥 Cleanup OLD file if user re-selects
        clearTempFile(at: selectedPDFURL)

        selectedPDFURL = newURL
        menuContainerView.isHidden = false

        // 🔥 Show Preview Inside Container
        showPDFPreviewInsideContainer(url: newURL)

        print("✅ PDF Selected: \(fileName)")
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
