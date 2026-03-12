//
//  BiometricMPinVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/03/26.
//

import UIKit

class BiometricMPinVC: UIViewController {
    // MARK: - IBOutlets

    @IBOutlet var pinLabelOne: UILabel!
    @IBOutlet var pinLabelTwo: UILabel!
    @IBOutlet var pinLabelThree: UILabel!
    @IBOutlet var pinLabelFour: UILabel!

    @IBOutlet var biometricView: UIView!
    @IBOutlet var biometricButton: UIButton!

    // MARK: - Properties

    private let hiddenTextField = UITextField()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHiddenTextField()
        setupUI()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkBiometricStatus()
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hiddenTextField.becomeFirstResponder()

        if !biometricView.isHidden {
            animateBiometricButton()
        }
    }

    // MARK: - Setup Methods

    private func setupUI() {
        let labels = [pinLabelOne, pinLabelTwo, pinLabelThree, pinLabelFour]
        for label in labels {
            label?.layer.borderWidth = 1.5
            label?.layer.borderColor = UIColor.lightGray.cgColor
            label?.layer.cornerRadius = 10
            label?.clipsToBounds = true
            label?.textAlignment = .center
            label?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
            label?.text = ""
        }
    }

    private func setupHiddenTextField() {
        view.addSubview(hiddenTextField)
        hiddenTextField.isHidden = true
        hiddenTextField.keyboardType = .numberPad
        hiddenTextField.delegate = self
        hiddenTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    private func setupGestures() {
        // 1. Tap outside to dismiss keyboard
        let dismissGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dismissGesture)

        // 2. Tap on PIN boxes to clear text and open keyboard
        let pinTapGesture = UITapGestureRecognizer(target: self, action: #selector(pinBoxesTapped))
        pinLabelOne.superview?.addGestureRecognizer(pinTapGesture)
        pinLabelOne.superview?.isUserInteractionEnabled = true
    }

    private func checkBiometricStatus() {
        let isDeviceCapable = BiometricManager.shared.isBiometricAvailable()
        let isUserEnabled = AppPreferences.isBiometricEnabled()
        biometricView.isHidden = !(isDeviceCapable && isUserEnabled)
    }

    // MARK: - Animations

    private func animateBiometricButton() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.15
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        biometricButton.layer.add(pulseAnimation, forKey: "pulse")
    }

    private func shakeUI() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-15.0, 15.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        pinLabelOne.superview?.layer.add(animation, forKey: "shake")

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func pinBoxesTapped() {
        // Clear existing input and open keyboard
        hiddenTextField.text = ""
        updatePinBoxes(with: "")
        hiddenTextField.becomeFirstResponder()
    }

    @IBAction func biometricButtonTapped(_ sender: UIButton) {
        hiddenTextField.resignFirstResponder()

        BiometricManager.shared.authenticateUser { [weak self] success, _ in
            guard let self = self else { return }
            if success {
                self.authenticationSuccessful()
            } else {
                self.hiddenTextField.becomeFirstResponder()
            }
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }

        if text.count > 4 {
            textField.text = String(text.prefix(4))
            return
        }

        updatePinBoxes(with: text)

        if text.count == 4 {
            verifyMPIN(enteredPIN: text)
        }
    }

    // MARK: - Logic

    private func updatePinBoxes(with text: String) {
        let characters = Array(text)

        pinLabelOne.text = characters.indices.contains(0) ? "●" : ""
        pinLabelTwo.text = characters.indices.contains(1) ? "●" : ""
        pinLabelThree.text = characters.indices.contains(2) ? "●" : ""
        pinLabelFour.text = characters.indices.contains(3) ? "●" : ""

        let labels = [pinLabelOne, pinLabelTwo, pinLabelThree, pinLabelFour]
        for (index, label) in labels.enumerated() {
            label?.layer.borderColor = index < text.count ? UIColor.systemIndigo.cgColor : UIColor.lightGray.cgColor
        }
    }

    private func verifyMPIN(enteredPIN: String) {
        guard let savedPIN = KeychainManager.shared.getMPIN() else { return }

        if enteredPIN == savedPIN {
            authenticationSuccessful()
        } else {
            shakeUI()
            hiddenTextField.text = ""
            updatePinBoxes(with: "")
        }
    }

    private func authenticationSuccessful() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        navigateToHomeScreen()
    }

    // MARK: - Navigation

    private func navigateToHomeScreen() {
        let storyboard = UIStoryboard(name: AppConstants.Storyboards.Main, bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: AppConstants.ViewControllers.HomeVC)
        navigationController?.setViewControllers([homeVC], animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension BiometricMPinVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
    }
}
