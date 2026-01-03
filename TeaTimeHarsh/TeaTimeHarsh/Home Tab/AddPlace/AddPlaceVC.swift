//
//  AddPlaceVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import GoogleMaps
import UIKit

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
    @IBOutlet var txtPhone: UITextField!

    // Dropdown Fields
    @IBOutlet var txtRating: UITextField!
    @IBOutlet var txtLocation: UITextField!
    @IBOutlet var txtPriceRange: UITextField!
    @IBOutlet var txtOpeningTime: UITextField!
    @IBOutlet var txtClosingTime: UITextField!
    @IBOutlet var txtHoliday: UITextField!

    @IBOutlet var mapContainerView: UIView! {
        didSet {
            mapContainerView.layer.cornerRadius = 20
            mapContainerView.clipsToBounds = true
        }
    }

    @IBOutlet var btnSubmit: UIButton! // To change title (Submit / Update)

    // MARK: - Properties

    // Public: Set this before pushing VC
    var screenMode: PlaceScreenMode = .add

    // Private Helpers
    private var googleMapView: GMSMapView?
    var onPlaceAdded: ((Bool) -> Void)?

    // State Tracking
    private var hasSelectedNewImage = false // True if user picked a new photo from gallery
    private var existingImageURL: String? // Holds the old URL in Edit mode

    // Dropdown Selections
    private var selectedRating: String?
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

        setupNavBar()
        setupMenuSelection()
        setupImageCofiguration()
        setupMiniMap()

        // Configure UI based on Mode (Add vs Edit)
        configureScreenMode()
    }

    deinit {
        print("💀 deinit AddPlaceVC is dead. Memory Free!")
    }

    // MARK: - Mode Configuration 🛠️

    private func configureScreenMode() {
        switch screenMode {
        case .add:
            title = "Add New Place"
            btnSubmit.setTitle("Submit", for: .normal)
            mapContainerView.isHidden = true

        case let .edit(place):
            title = "Edit Place"
            btnSubmit.setTitle("Update", for: .normal)
            mapContainerView.isHidden = false

            // 🔒 Security Check
            let currentUserId = Constants.Strings.currentUserID
            if place.createdByUserId != currentUserId {
                Utility.showAlert(title: "Access Denied", message: "You can only edit places created by you.", viewController: self)
                view.isUserInteractionEnabled = false
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
        txtPhone.text = place.phone
        lblAddress.text = place.address

        // 2. Fill Dropdowns
        selectedRating = "\(place.rating ?? 0.0)"
        txtRating.text = selectedRating

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

        // 4. Set Image (Using our NEW Manager) 🖼️
        existingImageURL = place.imageURL
        ImageManagerKF.setImage(from: place.imageURL, into: imgPlace, placeholderName: "photo")
    }

    // MARK: - Save / Update Logic 🚀

    func savePlaceToFirebase() {
        print("⏳ Process Started...")

        // 1. Validation Logic ✅
        guard validateImgInputs() else { return }

        LoaderManager.shared.startLoading()

        Task {
            do {
                // 2. Image Logic (Upload or Reuse) 🖼️
                let finalImageURL = try await processImageUpload()

                // 3. Create Object Logic 📦
                let placeToSave = constructTeaPlaceObject(imageURL: finalImageURL)
                print("*** Save To Firebase API Params :", placeToSave)

                // 4. Database Logic (Add or Update) 💾
                try await performDatabaseOperation(place: placeToSave)

                // 5. Success Logic 🎉
                await MainActor.run {
                    LoaderManager.shared.stopLoading()
                    Utility.showAlertHandler(title: "Success ✅", message: getSuccessMessage(),
                                             viewController: self) { _ in
                        self.onPlaceAdded?(true)

                        self.navigationController?.popViewController(animated: true)
                    }
                }

            } catch {
                await MainActor.run {
                    LoaderManager.shared.stopLoading()
                    Utility.showAlert(title: "Error", message: error.localizedDescription, viewController: self)
                }
            }
        }
    }

    private func validateImgInputs() -> Bool {
        // Add Mode: Must have new image
        // Edit Mode: Can reuse old image
        if case .add = screenMode, !hasSelectedNewImage {
            Utility.showAlert(title: "Missing Image", message: "Please select an image.", viewController: self)
            return false
        }
        return true
    }

    private func processImageUpload() async throws -> String {
        if hasSelectedNewImage, let newImage = imgPlace.image {
            // Case A: User picked a NEW photo (Upload it)
            print("☁️ Uploading new image...")
            return try await FirebaseManager.shared.uploadImage(newImage)

        } else if case .edit = screenMode, let oldUrl = existingImageURL {
            // Case B: User kept OLD photo (Reuse URL)
            print("♻️ Reusing existing image URL")
            return oldUrl
        }

        return "" // Fallback (Should typically not reach here due to validation)
    }

    private func constructTeaPlaceObject(imageURL: String) -> TeaPlace {
        // Collect UI Data
        let name = txtName.text ?? ""
        let desc = txtDesc.text ?? ""
        let phone = txtPhone.text ?? ""
        let location = selectedLocation
        let address = lblAddress.text
        let ratingDouble = Double(selectedRating ?? "0.0")

        switch screenMode {
        case .add:
            var newPlace = TeaPlace(
                id: UUID().uuidString,
                name: name,
                desc: desc,
                phone: phone,
                location: location,
                address: address,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                imageURL: imageURL,
                rating: ratingDouble,
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
                phone: phone,
                location: location,
                address: address,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                imageURL: imageURL,
                rating: ratingDouble,
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

    // MARK: - Actions

    @IBAction func btnSubmitTapped(_ sender: UIButton) {
        HapticHelper.success()
        if let errorMsg = validateFields() {
            Utility.showAlert(title: "Invalid Data", message: errorMsg, viewController: self)
            return
        }
        savePlaceToFirebase()
    }

    @objc private func didTapCancelBarButton() {
        showDiscardAlert()
    }
    
    @objc private func didTapDone() {
        self.view.endEditing(true)
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

    @IBAction func btnSelectLocationMap(_ sender: UIButton) {
        HapticHelper.medium()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mapVC = storyboard.instantiateViewController(withIdentifier: "SelectPlaceOnMapVC") as? SelectPlaceOnMapVC else { return }

        if let lat = selectedLatitude, let long = selectedLongitude {
            mapVC.alreadySelectedLatitude = lat
            mapVC.alreadySelectedLongitude = long
        }
        mapVC.delegateMap = self
        navigationController?.pushViewController(mapVC, animated: true)
    }

    // MARK: - UI & Validation

    private func validateFields() -> String? {
        guard let name = txtName.text?.trimmed, !name.isEmpty else { return "Please enter tea place name" }
        guard let desc = txtDesc.text?.trimmed, !desc.isEmpty else { return "Please enter description" }
        guard let phone = txtPhone.text?.removeAllSpaces, phone.count == 10 else {
            return "Enter valid 10-digit contact number"
        }
        guard selectedLocation != nil else { return "Please select city location" }
        guard selectedRating != nil else { return "Please select rating" }
        guard selectedPriceRange != nil else { return "Please select price range" }
        guard selectedOpeningTime != nil else { return "Please select opening time" }
        guard selectedClosingTime != nil else { return "Please select closing time" }
        guard selectedHoliday != nil else { return "Please select holiday" }
        guard selectedLatitude != nil, selectedLongitude != nil else { return "Please select location on map" }

        return nil
    }

    // Setup Methods
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancelBarButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",style: .plain,
            target: self, action: #selector(didTapDone))
    }

    private func setupMiniMap() {
        googleMapView = GoogleMapHelper.initializeMap(in: mapContainerView, enableGestures: false, showLocationButton: false, showCompass: false, showIndoorPicker: false, enableTraffic: false, showUserLocation: false)
    }

    private func setupImageCofiguration() {
        imgPlace.layer.cornerRadius = 20
        imgPlace.clipsToBounds = true
        imgPlace.contentMode = .scaleAspectFill
        imgPlace.backgroundColor = .secondarySystemBackground
        imgPlace.image = UIImage(systemName: "photo")
        imgPlace.tintColor = .secondaryLabel
        imgPlace.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPlaceImage))
        imgPlace.addGestureRecognizer(tap)
    }

    private func showDiscardAlert() {
        let alert = UIAlertController(title: "Discard Changes?", message: "Unsaved changes will be lost.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in self.navigationController?.popViewController(animated: true) })
        present(alert, animated: true)
    }

    private func setupMenuSelection() {
        // Dropdown Data
        let ratingOptions = ["1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0", "4.5", "5.0"]
        let locationOptions = ["Mumbai", "Delhi", "Bengaluru", "Chennai", "Hyderabad", "Pune", "Kolkata", "Ahmedabad", "Jaipur", "Surat"]
        let openingTimeOptions = ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00"]
        let closingTimeOptions = ["21:00", "22:00", "23:00", "23:59"]
        let priceRangeOptions = ["0-200", "200-400", "400-600", "600-800", "800-1000", "more then 1000"]
        let holidayOptions = ["Sunday", "Saturday, Sunday"]

        // Setup Bindings
        // City/Location
        // Rating
        txtRating.applySingleSelectionMenu(title: "Select Rating", items: ratingOptions, selectedItem: selectedRating) { [weak self] sel in
            guard let self else { return }
            self.view.endEditing(true) // ⌨️ Dismiss Keyboard
            self.selectedRating = sel
        }

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
