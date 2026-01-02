//
//  LoginRegisterVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import UIKit

class LoginRegisterVC: UIViewController, UITextFieldDelegate {
    // MARK: - 1. Define Logic States

    enum AuthMode {
        case login
        case register
        case forgotPassword
    }

    // MARK: - Outlets

    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var imgLoginRegisterVector: UIImageView!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtConfirmPassword: UITextField!
    @IBOutlet var btnForgotPassword: UIButton!
    @IBOutlet var btnLoginRegister: UIButton!

    // Variable to track current mode (Default is Login)
    var currentMode: AuthMode = .login

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI(mode: .login)
    }

    deinit {
        print("💀 deinit LoginRegisterVC is dead. Memory Free!")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - 2. Optimized UI Update Function ✨

    /// Manages visibility and text changes based on the AuthMode
    func updateUI(mode: AuthMode) {
        currentMode = mode

        UIView.animate(withDuration: 0.3) {
            // --- A. Visibility Logic (Clean One-Liners) ---

            // Email is ALWAYS visible
            self.txtEmail.isHidden = false

            // Password is visible unless we are in Forgot Password mode
            self.txtPassword.isHidden = (mode == .forgotPassword)

            // Confirm Password is visible ONLY in Register mode
            self.txtConfirmPassword.isHidden = (mode != .register)

            // Segment Control is hidden in Forgot Password mode (Focus on recovery)
            self.segmentControl.isHidden = (mode == .forgotPassword)

            // Forgot Button is hidden in Register mode (Visible in Login and Forgot modes)
            self.btnForgotPassword.isHidden = (mode == .register)

            // --- B. Text & Image Configuration ---
            switch mode {
            case .login:
                self.segmentControl.selectedSegmentIndex = 0
                self.btnForgotPassword.setTitle("Forgot Password?", for: .normal)
                self.btnLoginRegister.setTitle("Login", for: .normal)
                self.imgLoginRegisterVector.image = UIImage(named: "LOGIN_VECTOR")

            case .register:
                self.segmentControl.selectedSegmentIndex = 1
                self.btnLoginRegister.setTitle("Register", for: .normal)
                self.imgLoginRegisterVector.image = UIImage(named: "SIGNUP_VECTOR")

            case .forgotPassword:
                // Change button to "Back" so user can cancel
                self.btnForgotPassword.setTitle("Back to Login", for: .normal)
                self.btnLoginRegister.setTitle("Send Reset Link", for: .normal)
                self.imgLoginRegisterVector.image = UIImage(named: "LOGIN_VECTOR")
            }

            // Force layout update for animation
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    // 1. Segment Control Changed (Switch Login <-> Register)
    @IBAction func onSegmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            updateUI(mode: .login)
        } else {
            updateUI(mode: .register)
        }
    }

    // 2. Forgot Password / Back Button Tapped
    @IBAction func onForgotPasswordTapped(_ sender: UIButton) {
        if currentMode == .login {
            // Go to Forgot Password Screen
            updateUI(mode: .forgotPassword)
        } else if currentMode == .forgotPassword {
            // Go BACK to Login Screen
            updateUI(mode: .login)
        }
    }

    // 3. Main Action Button Tapped (Handles All 3 Logics)
    @IBAction func btnSubmitLoginRegister(_ sender: UIButton) {
        // Common Check: Email is always needed

        guard let email = txtEmail.text?.trimmingCharacters(in: .whitespaces), !email.isEmpty,
              let password = txtPassword.text?.trimmingCharacters(in: .whitespaces), !password.isEmpty else {
            Utility.showAlert(title: "Missing Input", message: "Please enter email and password.", viewController: self)
            return
        }

        if !Utility.isValidEmail(email) {
            Utility.showAlert(title: "Invalid Email", message: "Please enter a valid email address.", viewController: self)
            return
        }

        // Handle Logic based on Current Mode
        switch currentMode {
        case .login:
            // --- LOGIN LOGIC ---
            guard let password = txtPassword.text, !password.isEmpty else {
                Utility.showAlert(title: "Missing Password", message: "Please enter password.", viewController: self)
                return
            }
            print("*\(email) \(password)")
            performLogin(email: email, pass: password)

        case .register:
            // --- REGISTER LOGIC ---
            guard let password = txtPassword.text, !password.isEmpty else {
                Utility.showAlert(title: "Missing Password", message: "Please enter password.", viewController: self)
                return
            }

            if !Utility.isPasswordValid(password) {
                Utility.showAlert(
                    title: "Weak Password",
                    message: "Password must contain:\n• At least 1 Capital Letter (A-Z)\n• At least 1 Small Letter (a-z)\n• At least 1 Special Symbol (@, $, #, etc.)\n• Minimum 6 characters.",
                    viewController: self
                )
                return
            }

            guard let confirmPass = txtConfirmPassword.text, confirmPass == password else {
                Utility.showAlert(title: "Mismatch", message: "Passwords do not match!", viewController: self)
                return
            }
            print("*\(email) \(password)")
            performRegister(email: email, pass: password)

        case .forgotPassword:
            // --- FORGOT PASS LOGIC ---
            print("*\(email)")
            performResetPassword(email: email)
        }
    }

    // MARK: - API Calls (Separated for Clean Code)

    func performLogin(email: String, pass: String) {
        LoaderManager.shared.startLoading()
        AuthManager.shared.loginUser(email: email, pass: pass) { [weak self] success, error in
            self?.handleAuthResponse(success: success, error: error)
        }
    }

    func performRegister(email: String, pass: String) {
        LoaderManager.shared.startLoading()
        AuthManager.shared.registerUser(email: email, pass: pass) { [weak self] success, error in
            self?.handleAuthResponse(success: success, error: error)
        }
    }

    func performResetPassword(email: String) {
        LoaderManager.shared.startLoading()

        AuthManager.shared.resetPassword(email: email) {
            [weak self] success, error in

            LoaderManager.shared.stopLoading()
            guard let self = self else { return }

            if success {
                Utility
                    .showAlertHandler(
                        title: "Email Sent",
                        message: "A password reset link has been sent to \(email). Please check your inbox.",
                        viewController: self) { _ in
                            self.updateUI(mode: .login)
                    }

            } else {
                Utility.showAlert(title: "Error", message: error ?? "Failed to send link.", viewController: self)
            }
        }
    }

    // MARK: - Handle Login/Register Success

    func handleAuthResponse(success: Bool, error: String?) {
        LoaderManager.shared.stopLoading()

        if success {
            print("Success! User is in.")
            // --- 🚀 NAVIGATE TO HOME ---
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            guard let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeVC") as? HomeVC else {
                print("Error: Could not find HomeVC in Main Storyboard")
                return
            }

            let navVC = UINavigationController(rootViewController: homeVC)
            navVC.modalPresentationStyle = .fullScreen

            // Swap Root View Controller (Best Practice)
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                window.rootViewController = navVC

                // Smooth transition animation
                UIView.transition(
                        with: window,
                        duration: 0.3,
                        options: .transitionFlipFromLeft,
                        animations: nil,
                        completion: nil
                    )
            }

        } else {
            // Error handling
            let errorMsg = error ?? "Something went wrong."
            Utility.showAlert(title: "Authentication Failed", message: errorMsg, viewController: self)
        }
    }
}
