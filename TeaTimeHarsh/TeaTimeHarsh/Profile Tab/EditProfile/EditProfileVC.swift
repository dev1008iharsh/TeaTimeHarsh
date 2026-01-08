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
 
    let placeholderText = "Enter short description about yourself"
    let placeholderColor = UIColor.lightGray
    let textColor = UIColor.label

    // State Trackings
    private var hasSelectedNewImage = false // True if user picked a new photo from gallery
    private var existingImageURL: String? // Holds the old URL in Edit mode

    var currentUser: User?
    var selectedBirthDate: Date?
    
    var onProfileUpdated: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Profile"
        
        txtEmail.isUserInteractionEnabled = false
        setupDatePicker()
        setupNavBar()
        setupImageCofiguration()
        setupTextViewAndFields()
        fetchData()
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
        // 1. Full Name Check
        guard let name = txtFullName.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return "Please enter your full name."
        }

        // 2. Username Check
        guard let username = txtUserName.text?.trimmingCharacters(in: .whitespaces), !username.isEmpty else {
            return "Please enter a username."
        }

        // 3. Email Check (Basic Regex)
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        guard let email = txtEmail.text?.trimmingCharacters(in: .whitespaces), emailPred.evaluate(with: email) else {
            return "Please enter a valid email address."
        }

        // 4. Phone Check (Example: Must be 10 digits)
        if let phone = txtPhone.text, !phone.isEmpty {
            if phone.count < 10 {
                return "Phone number must be at least 10 digits."
            }
        }

        // 5. Bio Check (Optional, but maybe limit length)
        if let bio = txtViewBio.text, bio.count > 150 {
            return "Bio is too long (max 150 characters)."
        }

        return nil // nil means NO errors, everything is good! ✅
    }

    func fetchData() {
        LoaderManager.shared.startLoading()

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let userProfileData = try await UserDataManager.shared
                    .fetchCurrentUser()

                self.currentUser = userProfileData
                await self.setupProfileData()

            } catch {
                Utility
                    .showAlert(
                        title: "Error",
                        message: error.localizedDescription,
                        viewController: self
                    )
            }

            LoaderManager.shared.stopLoading()
        }
    }

    private func setupImageCofiguration() {
        imgProfile.layer.cornerRadius = imgProfile.bounds.height / 2
        imgProfile.clipsToBounds = true
        imgProfile.contentMode = .scaleAspectFill
        imgProfile.backgroundColor = .secondarySystemBackground
        imgProfile.tintColor = .secondaryLabel
        imgProfile.isUserInteractionEnabled = true
        imgProfile.tintColor = .systemIndigo
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        imgProfile.addGestureRecognizer(tap)
    }

    @IBAction func btnUpdateTapped(_ sender: UIButton) {
        HapticHelper.heavy()

        // 1. 🛡️ Run Validation
        if let errorMessage = validateInput() {
            Utility.showAlert(title: "Input Error", message: errorMessage, viewController: self)
            return // Stop here! Do not proceed.
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
                LocalProfileImageSave.shared.saveImage(image: profileImage)
                Utility
                    .showAlertHandler(
                        title: "Success✅",
                        message: "Profile Updated Successfully! 🎉",
                        viewController: self) { _ in
                            self.onProfileUpdated?()
                            self.navigationController?
                                .popViewController(animated: true)
                    }

              

            } catch {
                LoaderManager.shared.stopLoading()
                Utility.showAlert(
                    title: "Failed to update",
                    message: error.localizedDescription,
                    viewController: self
                )
            }
        }
    }

    func setupDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline // or .inline for modern look
        datePicker.maximumDate = Date() // cannot be born in the future! 👶

        // 1. Assign the picker as the input view for the textfield
        txtBirthDate.inputView = datePicker

        // 2. Add a Toolbar with a "Done" button
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
        txtBirthDate.resignFirstResponder()
    }

    // Helper to format date consistent with your requirement
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    private func setupProfileData() async {
        // 1. Fill Texts
        txtFullName.text = currentUser?.fullName
        txtUserName.text = currentUser?.username
        txtEmail.text = currentUser?.email
        //txtViewBio.text = currentUser?.bio
        self.configureBio(with: currentUser?.bio)
        txtPhone.text = currentUser?.phoneNumber
        txtCity.text = currentUser?.city
        txtBirthDate.text = currentUser?.birthDateString
        existingImageURL = currentUser?.profileImageUrl

        if let validUrl = existingImageURL, !validUrl.isEmpty {
            ImageManagerKF.setImage(
                from: validUrl,
                into: imgProfile,
                placeholderName: ""
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
            txtEmail.becomeFirstResponder()
        case txtEmail:
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
        HapticHelper.error()

        Utility
            .showCustomConfirmAlert(
                title: "Discard Changes?",
                message: "Unsaved changes will be lost. This action can not be undone.🔴",
                rightSideActionName: "Discard",
                leftSideActionName: "Keep Editing",
                viewController: self) { _ in
                    self.navigationController?.popViewController(animated: true)

            } leftAction: { _ in
                
            }
    }
}

