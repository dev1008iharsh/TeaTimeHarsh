//
//  AddPlaceVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import UIKit

final class AddPlaceVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet var imgPlace: UIImageView!
    @IBOutlet var txtDesc: UITextField!
    @IBOutlet var txtRating: UITextField! {
        didSet { txtRating.inputView = UIView() }
    }
    @IBOutlet var txtPhone: UITextField!
    @IBOutlet var txtLocation: UITextField! {
        didSet { txtLocation.inputView = UIView() }
    }
    @IBOutlet var txtName: UITextField!

    // MARK: - Properties
    private var imagePickerManager: ImagePickerManager?
    var onPlaceAdded: ((TeaPlace) -> Void)?

    private var selectedRating: String?
    private var selectedLocation: String?
    private var hasSelectedImage = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add New Place"
        setupNavBar()
        setupMenuSelection()
        setupImageSelection()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Navigation Bar
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancelBarButton)
        )
    }

    @objc private func didTapCancelBarButton() {
        showDiscardAlert()
    }

    // MARK: - Image Selection
    private func setupImageSelection() {
        imgPlace.image = UIImage(systemName: "photo")
        imgPlace.tintColor = .secondaryLabel
        imgPlace.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapPlaceImage)
        )
        imgPlace.addGestureRecognizer(tapGesture)
    }

    @objc private func didTapPlaceImage() {
        openImagePicker()
    }

    private func openImagePicker() {
        imagePickerManager = ImagePickerManager(presentationController: self)
        imagePickerManager?.selectImage { [weak self] selectedImage in
            guard let self, let image = selectedImage else {
                print("No image selected or permission denied")
                return
            }
            self.hasSelectedImage = true
            self.imgPlace.image = image
        }
    }

    // MARK: - Menu Selection
    private func setupMenuSelection() {

        let ratingOptions = ["1.0","1.5","2.0","2.5","3.0","3.5","4.0","4.5","5.0"]

        let locationOptions = [
            "Mumbai","Delhi","Bengaluru","Chennai","Hyderabad",
            "Pune","Kolkata","Ahmedabad","Jaipur","Surat"
        ]

        txtRating.applySingleSelectionMenu(
            title: "Select your rating",
            items: ratingOptions,
            selectedItem: selectedRating
        ) { [weak self] selected in
            self?.selectedRating = selected
        }

        txtLocation.applySingleSelectionMenu(
            title: "Select your city location",
            items: locationOptions,
            selectedItem: selectedLocation
        ) { [weak self] selected in
            self?.selectedLocation = selected
        }
    }

    // MARK: - Actions
    @IBAction func didTapCancel(_ sender: UIButton) {
        showDiscardAlert()
    }

    @IBAction func btnSubmitTapped(_ sender: UIButton) {
        if let errorMessage = validateFields() {
            Utility.shared.showAlert(
                title: "Invalid Data",
                message: errorMessage,
                view: self
            )
            return
        }

        let teaPlace = createTeaPlace()
        onPlaceAdded?(teaPlace)
        dismiss(animated: true)
    }

    // MARK: - Validation
    private func validateFields() -> String? {

        if txtName.text?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            return "Please enter tea place name"
        }

        if txtPhone.text?.count != 10 {
            return "Please enter valid 10-digit phone number (Do not include +91 or 0)"
        }

        if txtLocation.text?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            return "Please select location"
        }

        if txtDesc.text?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            return "Please enter description"
        }

        if txtRating.text?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            return "Please select rating"
        }

        if hasSelectedImage == false {
            return "Please select an image"
        }

        return nil
    }

    // MARK: - Model Creation
    private func createTeaPlace() -> TeaPlace {

        let ratingValue = Double(selectedRating ?? "") ?? 0.0

        return TeaPlace(
            name: txtName.text ?? "Unknown Tea Place",
            phone: Int(txtPhone.text ?? "") ?? 0,
            location: txtLocation.text ?? "Unknown Location",
            address: "Ahmedabad Ring Road address available",
            latitude: 23.0225,
            longitude: 72.5714,
            desc: txtDesc.text ?? "No description available",
            rating: ratingValue,
            image: imgPlace.image
        )
    }

    // MARK: - Alerts
    private func showDiscardAlert() {
        let alert = UIAlertController(
            title: "Discard Changes?",
            message: "All entered details will be lost.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.dismiss(animated: true)
        })

        present(alert, animated: true)
    }
}
