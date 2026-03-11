//
//  BiometricMPinVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/03/26.
//

import UIKit

class BiometricMPinVC: UIViewController {
    // MARK: - IBOutlets

    // PIN Boxes
    @IBOutlet var pinLabelOne: UILabel!
    @IBOutlet var pinLabelTwo: UILabel!
    @IBOutlet var pinLabelThree: UILabel!
    @IBOutlet var pinLabelFour: UILabel!

    // The nested UIView holding the Biometric Label and Button
    @IBOutlet var biometricView: UIView!
    @IBOutlet var biometricButton: UIButton!

    // MARK: - Properties

    private let hiddenTextField = UITextField()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHiddenTextField()
        setupUI()

        // DEV NOTE: For testing only. Remove this in production.
        // In a real app, MPIN is set from SettingsViewController.
        if KeychainManager.shared.getMPIN() == nil {
            _ = KeychainManager.shared.saveMPIN("1234")
            AppPreferences.setBiometricEnabled(true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check biometric status every time the screen is about to appear
        checkBiometricStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Always bring up the keyboard for quick MPIN entry
        hiddenTextField.becomeFirstResponder()

        // Trigger pulse animation only if the biometric section is visible
        if !biometricView.isHidden {
            animateBiometricButton()
        }
        hiddenTextField.becomeFirstResponder()
    }

    // MARK: - Setup Methods

    private func setupUI() {
        // Tap anywhere on the screen to bring up the keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)

        // Styling the PIN labels to look like modern input boxes
        let labels = [pinLabelOne, pinLabelTwo, pinLabelThree, pinLabelFour]
        for label in labels {
            label?.layer.borderWidth = 1.5
            label?.layer.borderColor = UIColor.lightGray.cgColor
            label?.layer.cornerRadius = 10
            label?.clipsToBounds = true
            label?.textAlignment = .center
            label?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
            label?.text = "" // Ensure they start empty
        }
    }

    private func setupHiddenTextField() {
        view.addSubview(hiddenTextField)
        hiddenTextField.isHidden = true
        hiddenTextField.keyboardType = .numberPad
        hiddenTextField.delegate = self

        // Listen to text changes in real-time
        hiddenTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    private func checkBiometricStatus() {
        // Logic: Is biometric hardware available? AND Did the user enable it?
        let isDeviceCapable = BiometricManager.shared.isBiometricAvailable()
        let isUserEnabled = AppPreferences.isBiometricEnabled()

        let shouldShowBiometric = isDeviceCapable && isUserEnabled

        // Hide or show the nested UIView. The parent StackView will auto-adjust!
        biometricView.isHidden = !shouldShowBiometric
    }

    // MARK: - Animations

    private func animateBiometricButton() {
        // A subtle pulse animation to grab the user's attention
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.15 // Slightly bigger for better visual effect
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity

        biometricButton.layer.add(pulseAnimation, forKey: "pulse")
    }

    private func shakeUI() {
        // Shake animation for incorrect MPIN
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-15.0, 15.0, -10.0, 10.0, -5.0, 5.0, 0.0]

        // Shaking the parent view of the labels
        pinLabelOne.superview?.layer.add(animation, forKey: "shake")

        // Provide haptic feedback for the error
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Actions

    @objc private func viewTapped() {
        hiddenTextField.becomeFirstResponder()
    }

    @IBAction func biometricButtonTapped(_ sender: UIButton) {
        hiddenTextField.resignFirstResponder() // Hide keyboard while scanning FaceID

        BiometricManager.shared.authenticateUser { [weak self] success, _ in
            guard let self = self else { return }

            if success {
                self.authenticationSuccessful()
            } else {
                // If FaceID fails or user cancels, bring the keyboard back for MPIN
                self.hiddenTextField.becomeFirstResponder()
            }
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }

        // Prevent typing more than 4 digits
        if text.count > 4 {
            textField.text = String(text.prefix(4))
            return
        }

        updatePinBoxes(with: text)

        // Automatically verify when 4 digits are entered
        if text.count == 4 {
            verifyMPIN(enteredPIN: text)
        }
    }

    // MARK: - Logic

    private func updatePinBoxes(with text: String) {
        let characters = Array(text)

        // Update text with bullet points for security
        pinLabelOne.text = characters.indices.contains(0) ? "●" : ""
        pinLabelTwo.text = characters.indices.contains(1) ? "●" : ""
        pinLabelThree.text = characters.indices.contains(2) ? "●" : ""
        pinLabelFour.text = characters.indices.contains(3) ? "●" : ""

        // Dynamic border color: Blue when typed, Light Gray when empty
        let labels = [pinLabelOne, pinLabelTwo, pinLabelThree, pinLabelFour]
        for (index, label) in labels.enumerated() {
            if index < text.count {
                label?.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                label?.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
    }

    private func verifyMPIN(enteredPIN: String) {
        guard let savedPIN = KeychainManager.shared.getMPIN() else { return }

        if enteredPIN == savedPIN {
            // Haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            authenticationSuccessful()
        } else {
            shakeUI()
            hiddenTextField.text = ""
            updatePinBoxes(with: "")
        }
    }

    private func authenticationSuccessful() {
        // Haptic feedback for success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        print("Success! Proceeding to the main app.")
        navigateToHomeScreen()
    }

    // MARK: - Navigation

    /// Navigates to Home Screen and clears the navigation stack so user can't swipe back to Lock screen
    private func navigateToHomeScreen() {
        // Using your AppConstants structure if available, else replace with exact strings
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Replace "Main" with AppConstants.Storyboards.Main if you have it
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeVC") // Replace with AppConstants.ViewControllers.HomeVC

        // setViewControllers replaces the entire stack. This is CRITICAL for security screens!
        navigationController?.setViewControllers([homeVC], animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension BiometricMPinVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Only allow decimal digits
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
    }
}
