//
//  EditProfileVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 08/01/26.
//

import UIKit

class EditProfileVC: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var txtFullName: UITextField!
    @IBOutlet var txtUserName: UITextField!
    @IBOutlet var txtEmail: UITextField! {
        didSet {
            txtEmail.alpha = 0.2
        }
    }

    @IBOutlet var txtPhone: UITextField!
    @IBOutlet var txtCity: UITextField!
    @IBOutlet var txtBirthDate: UITextField!
    @IBOutlet var txtViewBio: UITextView!
    @IBOutlet var btnUpdate: UIButton!

    let placeholderText = "Enter short description about yourself... (Max 250 characters)"
    let placeholderColor = UIColor.lightGray
    let textColor = UIColor.label

    // State Trackings
    private var hasSelectedNewImage = false // True if user picked a new photo from gallery
    private var existingImageURL: String? // Holds the old URL in Edit mode

    var currentUser: User?
    var selectedBirthDate: Date?

    let datePicker = UIDatePicker()

    var onProfileUpdated: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Profile"
        currentUser = UserDataManager.shared.user
        txtEmail.isUserInteractionEnabled = false
        setupDatePicker()
        setupNavBar()
        setupImageCofiguration()
        setupTextViewAndFields()
        setupProfileData()
    }

    private func setupTextViewAndFields() {
        txtFullName.applyDefaultStyle()
        txtUserName.applyDefaultStyle()
        txtEmail.applyDefaultStyle()
        txtPhone.applyDefaultStyle()
        txtCity.applyDefaultStyle()
        txtBirthDate.applyDefaultStyle()

        // 2. Assign the delegate so this class can listen to events
        txtViewBio.delegate = self
        txtViewBio.backgroundColor = .systemBackground
        // 3. Set the initial "Fake" Placeholder
        txtViewBio.text = placeholderText
        txtViewBio.textColor = placeholderColor

        // Apply your styling from before
        Utility.styleTextView(txtViewBio)
    }

    func validateInput() -> String? {
        // 0. Profile Image Check
        guard hasSelectedNewImage else {
            return "Please select your profile picture."
        }

        // 1. Full Name Check
        guard let name = txtFullName.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !name.isEmpty else {
            return "Please enter your full name."
        }

        // 2. Username Check
        guard let username = txtUserName.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !username.isEmpty else {
            return "Please enter a username."
        }

        // 3. Email Check
        guard let email = txtEmail.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            Utility.isValidEmail(email) else {
            return "Please enter a valid email address."
        }

        // 4. Phone Number Check (10 digits)
        guard let phone = txtPhone.text?
            .removeAllSpaces,
            phone.count == 10 else {
            return "Please enter a valid 10-digit phone number."
        }

        // 5. City Check
        guard let city = txtCity.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !city.isEmpty else {
            return "Please enter a city."
        }

        // 6. Bio Check

        guard let bio = txtViewBio.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !bio.isEmpty,
            bio != placeholderText else {
            return "Please enter a short bio about yourself."
        }

        guard bio.count <= 250 else {
            return "Bio must be 250 characters or less."
        }
        return nil // ✅ All validations passed
    }

    private func setupImageCofiguration() {
        imgProfile.applyCircularProfileStyle()
        imgProfile.tintColor = .systemIndigo
        imgProfile.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        imgProfile.addGestureRecognizer(tap)
    }

    @IBAction func btnUpdateTapped(_ sender: UIButton) {
        view.endEditing(true)
        HapticHelper.light()

        // 1. 🛡️ Run Validation
        if let errorMessage = validateInput() {
            HapticHelper.error()
            AlertHelper
                .showAlert(
                    title: "Data validation Error",
                    message: errorMessage,
                    vc: self
                )
            return // Stop here! Do not proceed.
        }
        guard AppNetworkManager.shared.isConnected else {
            AlertHelper
                .showAlert(
                    title: "No Internet 🛜",
                    message: "Please connect to the internet to edit profile.",
                    vc: self
                )
            return
        }

        guard var userToUpdate = currentUser else { return }

        // 2. 📝 Update Model from TextFields (Safe to force unwrap now because we validated)
        userToUpdate.fullName = txtFullName.text?.trimmingCharacters(in: .whitespaces)
        userToUpdate.username = txtUserName.text?.trimmingCharacters(in: .whitespaces)
        userToUpdate.email = txtEmail.text?.trimmingCharacters(in: .whitespaces) ?? ""
        userToUpdate.phoneNumber = txtPhone.text?.trimmingCharacters(in: .whitespaces)
        userToUpdate.city = txtCity.text?.trimmingCharacters(in: .whitespaces)
        userToUpdate.bio = txtViewBio.text

        // Update Date if user changed it
        if let newDate = selectedBirthDate {
            userToUpdate.birthDate = newDate
        }

        // 3. ☁️ Save to Server
        Task { [weak self] in
            guard let self = self else { return }
            LoaderManager.shared.startLoading()

            do {
                guard let profileImage = self.imgProfile.image else { return }

                let imageUrl = try await UserDataManager.shared.uploadProfileImage(profileImage)
                userToUpdate.profileImageUrl = imageUrl

                // B. Update Data
                try await UserDataManager.shared.updateUserProfile(user: userToUpdate)
                LoaderManager.shared.stopLoading()
                // C. Success!
                HapticHelper.success()
                UserProfileImageStorage.saveUserProfileImage(profileImage)
                AlertHelper
                    .showAlertHandler(
                        title: "Success✅",
                        message: "Profile Updated Successfully! 🎉",
                        vc: self) { _ in
                            self.onProfileUpdated?()
                            self.navigationController?
                                .popViewController(animated: true)
                    }

            } catch {
                HapticHelper.error()
                LoaderManager.shared.stopLoading()
                AlertHelper.showAlert(
                    title: "Failed to update",
                    message: error.localizedDescription,
                    vc: self
                )
            }
        }
    }

    func setupDatePicker() {
        let today = Date()
        let calendar = Calendar.current

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline

        datePicker.minimumDate = calendar.date(byAdding: .year, value: -120, to: today)
        datePicker.maximumDate = calendar.date(byAdding: .year, value: -12, to: today)

        // Ensure selected date stays within range
        datePicker.date = min(datePicker.date, datePicker.maximumDate ?? today)

        txtBirthDate.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDateTapped))
        toolbar.tintColor = .systemIndigo
        toolbar.setItems([doneBtn], animated: true)
        txtBirthDate.inputAccessoryView = toolbar

        // 3. Handle value changes
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        selectedBirthDate = sender.date
        // Format: 21-10-2025
        txtBirthDate.text = formatDate(sender.date)
    }

    @objc func doneDateTapped() {
        // Dismiss the picker
        HapticHelper.light()
        txtBirthDate.resignFirstResponder()
    }

    // Helper to format date consistent with your requirement
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    private func setupProfileData() {
        // 1. Fill Texts
        txtFullName.text = currentUser?.fullName
        txtUserName.text = currentUser?.username
        txtEmail.text = currentUser?.email
        // txtViewBio.text = currentUser?.bio
        configureBio(with: currentUser?.bio)
        txtPhone.text = currentUser?.phoneNumber
        txtCity.text = currentUser?.city
        txtBirthDate.text = currentUser?.birthDateString
        datePicker.date = currentUser?.birthDate ?? Date()
        existingImageURL = currentUser?.profileImageUrl
        setProfilePicure()
    }

    private func setProfilePicure() {
        if let validUrl = existingImageURL, !validUrl.isEmpty {
            ImageManagerKF.setImage(
                from: validUrl,
                into: imgProfile
            )
            hasSelectedNewImage = true
        } else {
            hasSelectedNewImage = false
            imgProfile.image = UIImage(systemName: "person.circle.fill")
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txtFullName:
            txtUserName.becomeFirstResponder()
        case txtUserName:
            txtPhone.becomeFirstResponder()
        case txtPhone:
            txtCity.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }

    func configureBio(with text: String?) {
        // 1. Check if the API gave us actual text (and it's not just empty spaces)
        if let bio = text, !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // 🟢 Case A: We have real data!
            txtViewBio.text = bio
            txtViewBio.textColor = textColor // Normal Black Color

        } else {
            // ⚪️ Case B: Data is empty/nil -> Show Placeholder
            txtViewBio.text = placeholderText
            txtViewBio.textColor = placeholderColor // Gray Color
        }
    }

    // 🟢 1. When User Starts Typing (Focus)
    func textViewDidBeginEditing(_ textView: UITextView) {
        // If the text is currently our "placeholder", clear it!
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = textColor // Change color to normal black
        }
    }

    // 🔴 2. When User Stops Typing (Lost Focus)
    func textViewDidEndEditing(_ textView: UITextView) {
        // If user typed nothing (empty), put the placeholder back!
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = placeholderColor
        }
    }

    @objc private func didTapProfileImage() {
        HapticHelper.light()
        ImagePickerManager.shared.pickSingleImage(from: self) { [weak self] selectedImage in
            guard let self = self, let image = selectedImage else { return }

            // Mark as CHANGED so we know to upload it later
            self.hasSelectedNewImage = true
            self.imgProfile.image = image
        }
    }

    // Setup Methods
    private func setupNavBar() {
        navigationItem.leftBarButtonItem?.tintColor = .systemIndigo
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancelBarButton))
    }

    @objc private func didTapCancelBarButton() {
        HapticHelper.warning()

        AlertHelper.showConfirmationAlert(
            title: "Discard Changes?",
            message: "Unsaved changes will be lost. This action can not be undone.🔴",
            vc: self,
            rightBtnTitle: "Discard",
            rightBtnStyle: .destructive, // Makes 'Discard' button Red
            leftBtnTitle: "Keep Editing",
            leftBtnStyle: .cancel, // Makes 'Keep Editing' bold/standard
            rightAction: { [weak self] _ in
                // Pops the view controller if user confirms discard
                self?.navigationController?.popViewController(animated: true)
            },
            leftAction: { _ in
                // No action needed if user wants to stay
            }
        )
    }
}
