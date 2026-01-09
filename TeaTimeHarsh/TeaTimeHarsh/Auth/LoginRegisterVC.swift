//
//  LoginRegisterVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import FirebaseAuth
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
    @IBOutlet var btnLoginRegister: UIButton! {
        didSet {
            btnLoginRegister.layer.cornerRadius = btnLoginRegister.bounds.height / 2
            btnLoginRegister.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        }
    }

    @IBOutlet var stackView: UIStackView!

    @IBOutlet var btnApple: UIButton!
    @IBOutlet var btnGoogle: UIButton!
    @IBOutlet var btnFacebook: UIButton!

    // Variable to track current mode (Default is Login)
    var currentMode: AuthMode = .login

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI(mode: .login)
        // setupGradientBackground()

        txtEmail.applyDefaultStyle()
        txtPassword.applyDefaultStyle()
        txtConfirmPassword.applyDefaultStyle()
    }

    deinit {
        print("💀 deinit LoginRegisterVC is dead. Memory Free!")
    }

    private func setupGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemPurple.cgColor,
            UIColor.systemPink.cgColor,
            UIColor.systemOrange.cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - 2. Optimized UI Update Function ✨

    /// Manages visibility and text changes based on the AuthMode
    func updateUI(mode: AuthMode) {
        currentMode = mode

        // Email is ALWAYS visible
        txtEmail.isHidden = false

        // Password is visible unless we are in Forgot Password mode
        txtPassword.isHidden = (mode == .forgotPassword)

        // Confirm Password is visible ONLY in Register mode
        txtConfirmPassword.isHidden = (mode != .register)

        // Segment Control is hidden in Forgot Password mode
        segmentControl.isHidden = (mode == .forgotPassword)

        // Forgot Button is hidden in Register mode
        btnForgotPassword.isHidden = (mode == .register)

        switch mode {
        case .login:
            segmentControl.selectedSegmentIndex = 0
            btnForgotPassword.setTitle("Forgot Password?", for: .normal)
            btnLoginRegister.setTitle("Login", for: .normal)
            imgLoginRegisterVector.image = UIImage(named: "LOGIN_VECTOR")

        case .register:
            segmentControl.selectedSegmentIndex = 1
            btnLoginRegister.setTitle("Register", for: .normal)
            imgLoginRegisterVector.image = UIImage(named: "SIGNUP_VECTOR")

        case .forgotPassword:
            btnForgotPassword.setTitle("Back to Login", for: .normal)
            btnLoginRegister.setTitle("Send Reset Link", for: .normal)
            imgLoginRegisterVector.image = UIImage(named: "LOGIN_VECTOR")
        }

        UIView.animate(withDuration: 0.3) {
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

            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarVC")

            // Swap Root View Controller (Best Practice)
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                window.rootViewController = tabBarVC

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
// MARK: - Social Login Actions 🌍
extension LoginRegisterVC {
    
    // 🍎 Apple Login (Disabled as per your request)
    @IBAction func btnAppleTapped(_ sender: UIButton) {
        HapticHelper.heavy()
        // We are ignoring Apple Login for now
        print("Apple login disabled")
    }

    // 🌍 Google Login
    @IBAction func btnGoogleTapped(_ sender: UIButton) {
        HapticHelper.heavy()
        performSocialLogin(provider: .google)
    }
        
    // 📘 Facebook Login
    @IBAction func btnFacebookTapped(_ sender: UIButton) {
        HapticHelper.heavy()
        performSocialLogin(provider: .facebook)
    }
        
    // MARK: - 🛠 Social Login Logic Helper
    
    private func performSocialLogin(provider: AuthProviderType) {
        LoaderManager.shared.startLoading()
        
        // 1. 🌍 Handle Google (Async/Await)
        if provider == .google {
            Task {
                do {
                    // Start Google Login
                    let (credential, user) = try await SocialAuthManager.shared.startGoogleLogin(in: self)
                    
                    // Sign In to Firebase
                    try await AuthManager.shared.signInWithSocialCredential(credential: credential, userDetails: user)
                    
                    // Success! 🎉
                    self.handleAuthResponse(success: true, error: nil)
                    
                } catch {
                    self.handleSocialError(error)
                }
            }
        }
        
        // 2. 📘 Handle Facebook (Completion Handler)
        else if provider == .facebook {
            
            SocialAuthManager.shared.startFacebookLogin(in: self) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let (credential, user)):
                    
                    // Facebook worked! Now we need a Task to call Firebase (because Firebase is async)
                    Task {
                        do {
                            try await AuthManager.shared.signInWithSocialCredential(credential: credential, userDetails: user)
                            self.handleAuthResponse(success: true, error: nil)
                        } catch {
                            self.handleSocialError(error)
                        }
                    }
                    
                case .failure(let error):
                    self.handleSocialError(error)
                }
            }
        }
    }
    
    // MARK: - ⚠️ Error Handling Helper
    private func handleSocialError(_ error: Error) {
        LoaderManager.shared.stopLoading()
        print("Social Login Error: \(error.localizedDescription)")
        
        // Don't show alert if user just cancelled the popup
        if let socialError = error as? SocialAuthError, case .cancelled = socialError {
            return
        }
        
        Utility.showAlert(title: "Login Failed", message: error.localizedDescription, viewController: self)
    }
}
