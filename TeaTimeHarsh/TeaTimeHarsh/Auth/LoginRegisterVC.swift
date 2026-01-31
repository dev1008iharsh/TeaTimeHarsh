//
//  LoginRegisterVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

// import AuthenticationServices
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
        removePreviousUserIfAny()
        updateUI(mode: .login)
        // setupGradientBackground()

        txtEmail.applyDefaultStyle()
        txtPassword.applyDefaultStyle()
        txtConfirmPassword.applyDefaultStyle()
    }

    deinit {
        print("💀 deinit LoginRegisterVC is dead. Memory Free!")
    }

    private func removePreviousUserIfAny() {
        if AppNetworkManager.shared.isConnected {
            if AuthManager.shared.isUserLoggedIn {
                _ = AuthManager.shared.signOut()
            }
        }
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
        HapticHelper.success()
        view.endEditing(true)

        guard let email = txtEmail.text?.trimmingCharacters(in: .whitespaces), !email.isEmpty,
              let password = txtPassword.text?.trimmingCharacters(in: .whitespaces), !password.isEmpty else {
            AlertHelper
                .showAlert(
                    title: "Missing Input",
                    message: "Please enter email and password.",
                    vc: self
                )
            return
        }

        if !Utility.isValidEmail(email) {
            AlertHelper.showAlert(title: "Invalid Email", message: "Please enter a valid email address.", vc: self)
            return
        }

        // Handle Logic based on Current Mode
        switch currentMode {
        case .login:
            // --- LOGIN LOGIC ---
            guard let password = txtPassword.text, !password.isEmpty else {
                AlertHelper.showAlert(title: "Missing Password", message: "Please enter password.", vc: self)
                return
            }
            print("*\(email) \(password)")
            performLogin(email: email, pass: password)

        case .register:
            // --- REGISTER LOGIC ---
            guard let password = txtPassword.text, !password.isEmpty else {
                AlertHelper
                    .showAlert(
                        title: "Missing Password",
                        message: "Please enter password.",
                        vc: self
                    )
                return
            }

            if !Utility.isPasswordValid(password) {
                AlertHelper.showAlert(
                    title: "Weak Password",
                    message: "Password must contain:\n• At least 1 Capital Letter (A-Z)\n• At least 1 Small Letter (a-z)\n• At least 1 Special Symbol (@, $, #, etc.)\n• Minimum 6 characters.",
                    vc: self
                )
                return
            }

            guard let confirmPass = txtConfirmPassword.text, confirmPass == password else {
                AlertHelper.showAlert(title: "Mismatch", message: "Passwords do not match!", vc: self)
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
                AlertHelper
                    .showAlertHandler(
                        title: "Email Sent",
                        message: "A password reset link has been sent to \(email). Please check your inbox.",
                        vc: self) { _ in
                            self.updateUI(mode: .login)
                    }

            } else {
                AlertHelper
                    .showAlert(
                        title: "Error",
                        message: error ?? "Failed to send link.",
                        vc: self
                    )
            }
        }
    }

    // MARK: - Handle Login/Register Success

    func handleAuthResponse(success: Bool, error: String?) {
        LoaderManager.shared.stopLoading()

        if success {
            print("Success! User is in.Successfully passed the auth flow ✅")

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
            AlertHelper.showAlert(title: "Authentication Failed", message: errorMsg, vc: self)
        }
    }
}

// MARK: - Social Login Actions 🌍

extension LoginRegisterVC {
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

                case let .failure(error):
                    self.handleSocialError(error)
                }
            }
        }
    }

    // MARK: - ⚠️ Error Handling Helper

    private func handleSocialError(_ error: Error) {
        LoaderManager.shared.stopLoading()
        HapticHelper.error()
        print("Social Login Error: \(error.localizedDescription)")

        // Don't show alert if user just cancelled the popup
        if let socialError = error as? SocialAuthError, case .cancelled = socialError {
            return
        }

        AlertHelper.showAlert(title: "Login Failed", message: error.localizedDescription, vc: self)
    }

    @IBAction func btnAppleTapped(_ sender: UIButton) {
        HapticHelper.heavy()
        print("🟢 Apple Sign-In Button Tapped")

        AlertHelper.showAlert(
            title: "Server Error",
            message: "Server is busy due to too much request please try again after some time.",
            vc: self
        )

        // MARK: - Code commented due to not having apple developer account.

        /*
         // 🚀 START LOGIN PROCESS
         let appleIDProvider = ASAuthorizationAppleIDProvider()
         let request = appleIDProvider.createRequest()

         // 📝 We ask for the User's Full Name and Email
         request.requestedScopes = [.fullName, .email]

         // 🚀 Create the controller and show the popup
         let authorizationController = ASAuthorizationController(authorizationRequests: [request])

         authorizationController.delegate = self
         authorizationController.presentationContextProvider = self

         authorizationController.performRequests()*/
    }
}

/*
 // MARK: - Apple Sign In Extensions

 // We combine both protocols here: Delegate (for success/fail) and ContextProviding (for the window)
 extension LoginRegisterVC: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
     // 🖥️ This tells Apple which window to show the popup on
     // (This fixes the "method does not satisfy requirement" error)
     func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
         return view.window!
     }

     // ✅ SUCCESS: We got the data!
     func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
         if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
             print("\n----------- 🍎 APPLE DATA RECEIVED 🍎 -----------")

             // 1. User Identifier (The unique ID for this user)
             let userIdentifier = appleIDCredential.user
             print("🆔 User ID: \(userIdentifier)")

             // 2. Full Name (⚠️ Only comes the FIRST time you sign in!)
             if let fullName = appleIDCredential.fullName {
                 let firstName = fullName.givenName ?? "N/A"
                 let lastName = fullName.familyName ?? "N/A"
                 print("👤 Name: \(firstName) \(lastName)")
             }

             // 3. Email (⚠️ Only comes the FIRST time!)
             if let email = appleIDCredential.email {
                 print("📧 Email: \(email)")
             }

             // 4. Identity Token (For Firebase)
             if let identityTokenData = appleIDCredential.identityToken,
                let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                 print("🔑 Identity Token (For Firebase): \(identityTokenString.prefix(20))...")
             }

             print("--------------------------------------------------\n")

             // 👉 TODO: Here you will call your Firebase Login function
         }
     }

     // ❌ FAILURE: Something went wrong
     func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
         print("🔴 Sign-In Failed: \(error.localizedDescription)")

         // Handle user cancelling the popup
         if let outputError = error as? ASAuthorizationError {
             switch outputError.code {
             case .canceled:
                 print("User cancelled the login window.")
             case .unknown:
                 print("Unknown error.")
             default:
                 break
             }
         }
     }
 }
 */
