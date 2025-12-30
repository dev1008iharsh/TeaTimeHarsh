//
//  AddPlaceVC.swift
//  TeaTimeHarsh
//
//  Fixed by Your AI Mentor on 30/12/25.
//

import GoogleMaps
import UIKit

class AddPlaceVC: UIViewController,UITextFieldDelegate {
    // MARK: - IBOutlets

    @IBOutlet var lblAddress : UILabel!
    
    @IBOutlet var imgPlace: UIImageView!{
        didSet {
            imgPlace.layer.cornerRadius = 20
            imgPlace.clipsToBounds = true
        }
    }
    @IBOutlet var txtDesc: UITextField!
    @IBOutlet var txtRating: UITextField! {
        didSet { txtRating.inputView = UIView() }
    }

    @IBOutlet var txtPhone: UITextField!
    //@IBOutlet var txtAddress: UITextField!
    @IBOutlet var txtLocation: UITextField! {
        didSet { txtLocation.inputView = UIView() }
    }

    @IBOutlet var txtName: UITextField!
    @IBOutlet var mapContainerView: UIView! {
        didSet {
            mapContainerView.layer.cornerRadius = 20
            mapContainerView.clipsToBounds = true
        }
    }

    // MARK: - Properties

    private var googleMapView: GMSMapView?
    
    var onPlaceAdded: ((TeaPlace) -> Void)?

    // Dropdown Data
    private var selectedOptionRating: String?
    private var selectedOptionLocation: String?
    private var hasSelectedImage = false

    // 💾 STATE: Saved Location Data
    private var selectedLatitude: Double?
    private var selectedLongitude: Double?
    // Note: We use txtAddress.text to store the address string

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add New Place"
         
        // Hide container until a location is picked
        mapContainerView.isHidden = true
        // Stop user from typing manually. They MUST use the map button.

        
        setupNavBar()
        setupMenuSelection()
        setupImageSelection()
        setupMiniMap()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            switch textField {
            case txtName:
                txtLocation.becomeFirstResponder()
            case txtLocation:
                txtPhone.becomeFirstResponder()
            case txtPhone:
                txtDesc.becomeFirstResponder()
            case txtDesc:
                txtRating.becomeFirstResponder()
            default:
                textField.resignFirstResponder()
            }
            return true
        }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - UI Setup

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancelBarButton)
        )
    }

    private func setupMiniMap() {
        // Initialize map for display only (Static)
        googleMapView = GoogleMapHelper.initializeMap(
            in: mapContainerView,
            enableGestures: false,
            showLocationButton: false,
            showCompass: false,
            showIndoorPicker: false,
            enableTraffic: false,
            showUserLocation: false
        )
    }

    private func setupImageSelection() {
        imgPlace.image = UIImage(systemName: "photo")
        imgPlace.tintColor = .secondaryLabel
        imgPlace.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPlaceImage))
        imgPlace.addGestureRecognizer(tapGesture)
    }

    private func setupMenuSelection() {
        let ratingOptions = ["1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0", "4.5", "5.0"]
        let locationOptions = ["Mumbai", "Delhi", "Bengaluru", "Chennai", "Hyderabad", "Pune", "Kolkata", "Ahmedabad", "Jaipur", "Surat"]

        txtRating.applySingleSelectionMenu(title: "Select Rating", items: ratingOptions, selectedItem: selectedOptionRating) { [weak self] selected in
            self?.selectedOptionRating = selected
            HapticHelper.light()
        }

        txtLocation.applySingleSelectionMenu(title: "Select City", items: locationOptions, selectedItem: selectedOptionLocation) { [weak self] selected in
            self?.selectedOptionLocation = selected
            HapticHelper.light()
        }
    }

    // MARK: - Actions

    @objc private func didTapCancelBarButton() {
        showDiscardAlert()
    }

    @objc private func didTapPlaceImage() {
        HapticHelper.light()
        ImagePickerManager.shared.pickSingleImage(from: self) { [weak self] selectedImage in
            guard let self = self, let image = selectedImage else { return }
            self.hasSelectedImage = true
            self.imgPlace.image = image
        }
    }

    @IBAction func btnSelectLocationMap(_ sender: UIButton) {
        HapticHelper.medium()
        // 1. Instantiate the Fixed Map VC
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mapVC = storyboard.instantiateViewController(withIdentifier: "SelectPlaceOnMapVC") as? SelectPlaceOnMapVC else {
            print("❌ Could not instantiate SelectPlaceOnMapVC")
            return
        }

        // 2. Pass Saved Data (If available)
        // This ensures the map opens at the last selected location (Logic Fix 🧠)
        if let lat = selectedLatitude, let long = selectedLongitude {
            mapVC.alreadySelectedLatitude = lat
            mapVC.alreadySelectedLongitude = long
        }

        // 3. Connect Delegate
        mapVC.delegateMap = self

        navigationController?.pushViewController(mapVC, animated: true)
    }

    @IBAction func btnSubmitTapped(_ sender: UIButton) {
        HapticHelper.success()
        if let errorMessage = validateFields() {
            Utility
                .showAlert(
                    title: "Invalid Data",
                    message: errorMessage,
                    viewController: self
                )
            return
        }

        let teaPlace = createTeaPlace()
        onPlaceAdded?(teaPlace)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Validation & Helper

    private func validateFields() -> String? {
        guard let name = txtName.text?.trimmed, !name.isEmpty else { return "Please enter tea place name" }
        guard let phone = txtPhone.text, phone.count == 10 else { return "Enter valid 10-digit phone number" }
        guard selectedOptionLocation != nil else { return "Please select city location" }
        guard let desc = txtDesc.text?.trimmed, !desc.isEmpty else { return "Please enter description" }
        guard selectedOptionRating != nil else { return "Please select rating" }
        guard hasSelectedImage else { return "Please select an image" }

        // Map Validation
        guard selectedLatitude != nil, selectedLongitude != nil else { return "Please select location on map" }

        return nil
    }

    private func createTeaPlace() -> TeaPlace {
        return TeaPlace(
            name: txtName.text ?? "",
            phone: Int(txtPhone.text ?? "") ?? 0,
            location: selectedOptionLocation ?? "",
            address: lblAddress.text ?? "", // Uses the map address
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            desc: txtDesc.text ?? "",
            rating: Double(selectedOptionRating ?? "") ?? 0.0,
            image: imgPlace.image
        )
    }

    private func showDiscardAlert() {
        HapticHelper.warning()
        let alert = UIAlertController(title: "Discard Changes?", message: "All entered details will be lost.", preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel) { _ in
             HapticHelper.success()
        })
        
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.navigationController?.popViewController(animated: true)
            HapticHelper.error()
        })
        present(alert, animated: true)
    }
}

// MARK: - Map Delegate Implementation

extension AddPlaceVC: SelectPlaceOnMapVCDelegate {
    func didSelectLocation(latitude: Double, longitude: Double, address: String) {
        print("📍 Received: \(latitude), \(longitude) - \(address)")

        // 1. Update State (So we remember it next time)
        selectedLatitude = latitude
        selectedLongitude = longitude

        // 2. Update UI
        lblAddress.text = address
        mapContainerView.isHidden = false

        // 3. Update Mini Map to show the selected spot
        GoogleMapHelper.updateLocation(
            mapView: googleMapView,
            lat: latitude,
            long: longitude,
            showMarker: true
        )
    }
}
