//
//  ReportBugVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import UIKit

class ReportBugVC: UIViewController, UITextViewDelegate {
    @IBOutlet var txtViewDesc: UITextView!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var imgReport: UIImageView!

    var hasSelectedNewImage = false
    // The text we want to show as a hint
    let placeholderText = "Enter founded bug description related to screenshot here..."
    let placeholderColor = UIColor.lightGray
    let textColor = UIColor.label

    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable swipe-down to dismiss
        isModalInPresentation = true
        txtViewDesc.delegate = self
        setupTextView()
        setupImageCofiguration()
    }

    // 🔘 Submit Button Action
    @IBAction func submitTapped(_ sender: UIButton) {
        HapticHelper.medium()
        guard let email = txtEmail.text, !email.isEmpty, Utility.isValidEmail(email) else {
            AlertHelper
                .showAlert(
                    title: "Validation Error",
                    message: "Please enter valid email ID. 📧",
                    vc: self
                )
            return
        }

        guard let desc = txtViewDesc.text, !desc.isEmpty, desc != placeholderText else {
            AlertHelper
                .showAlert(
                    title: "Validation Error",
                    message: "Please enter a description of the bug related to screenshot. ✍️",
                    vc: self
                )
            return
        }

        if !hasSelectedNewImage {
            AlertHelper
                .showAlert(
                    title: "Oops!",
                    message: "Please attach a screenshot. 🖼️",
                    vc: self
                )
            return
        }
        LoaderManager.shared.startLoading()
        Task {
            do {
                guard let imageToUpload = imgReport.image else { return }

                try await FirebaseManager.shared.submitBugReport(desc: desc, email: email, image: imageToUpload)

                // 3️⃣ Success! UI Update Main Thread par
                await MainActor.run {
                    print("Bug Reported Successfully! ✅")
                    LoaderManager.shared.stopLoading()
                    HapticHelper.success()
                    AlertHelper
                        .showAlertHandler(
                            title: "Bug Reported Successfully! ✅",
                            message: "Thank you! We received your report. We will reach to you soon using email address.",
                            vc: self) { _ in
                                self.dismiss(animated: true, completion: nil)
                        }
                }

            } catch {
                // ❌ Error
                await MainActor.run {
                    LoaderManager.shared.stopLoading()
                    HapticHelper.error()
                    AlertHelper.showAlert(title: "❌ Error : Try again", message: "Error: \(error.localizedDescription)", vc: self)
                }
            }
        }
    }

    @IBAction func btnCloseSheet(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    private func setupTextView() {
        txtEmail.applyDefaultStyle()
        // 2. Assign the delegate so this class can listen to events
        txtViewDesc.delegate = self

        // 3. Set the initial "Fake" Placeholder
        txtViewDesc.text = placeholderText
        txtViewDesc.textColor = placeholderColor

        // Apply your styling from before
        Utility.styleTextView(txtViewDesc)
    }

    // MARK: - UITextView Delegate Methods

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

    private func setupImageCofiguration() {
        imgReport.layer.cornerRadius = 10
        imgReport.clipsToBounds = true
        imgReport.contentMode = .scaleAspectFit
        imgReport.preferredSymbolConfiguration = UIImage
            .SymbolConfiguration(scale: .small)
        imgReport.layer.borderColor = UIColor.label.cgColor
        imgReport.layer.borderWidth = 1
        imgReport.backgroundColor = .tertiarySystemGroupedBackground
        imgReport.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPlaceImage))
        imgReport.addGestureRecognizer(tap)
    }

    @objc private func didTapPlaceImage() {
        HapticHelper.light()
        ImagePickerManager.shared.pickSingleImage(from: self) { [weak self] selectedImage in
            guard let self = self, let image = selectedImage else { return }

            // Mark as CHANGED so we know to upload it later
            self.hasSelectedNewImage = true
            self.imgReport.image = image
        }
    }
}
