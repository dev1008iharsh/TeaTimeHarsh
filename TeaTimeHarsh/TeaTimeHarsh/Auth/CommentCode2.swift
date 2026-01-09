
//
//  SocialAuthManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 09/01/26.
//
/*
import AuthenticationServices
import CryptoKit
import FacebookLogin
import FirebaseAuth
import Foundation
import GoogleSignIn
import UIKit

// Custom Error to handle "No Email" specifically
enum SocialAuthError: Error {
    case emailMissing
    case cancelled
    case unknown
}

class SocialAuthManager: NSObject {
    // MARK: - 1. Singleton & Config

    static let shared = SocialAuthManager()

    // We need to keep a reference to the 'currentNonce' for Apple Login
    fileprivate var currentNonce: String?

    // We need a completion handler to send data back to VC
    // Returns: (FirebaseCredential, UserObject) OR Error
    private var completion: ((Result<(AuthCredential, User), Error>) -> Void)?

    override private init() {}

    // MARK: - 🌍 Google Login Logic

    func startGoogleLogin(in viewController: UIViewController, completion: @escaping (Result<(AuthCredential, User), Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in

            if let error = error {
                print("❌ Google Signin Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(SocialAuthError.unknown))
                return
            }

            // 🔒 MANDATORY EMAIL CHECK
            guard let email = user.profile.email, !email.isEmpty else {
                completion(.failure(SocialAuthError.emailMissing))
                GIDSignIn.sharedInstance.signOut() // Logout immediately
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            // Create "Black Data" (Pre-filled User Object)
            let newUser = User(
                id: nil, // Will be set by Firebase later
                username: user.profile.name,
                fullName: user.profile.name,
                email: email,
                profileImageUrl: user.profile.imageURL(withDimension: 320)?.absoluteString,
                providerType: .google,
                isEmailVerified: true, // Google emails are verified
                isActive: true,
                isOnBoardingDone: false,
                isSubscribed: false,
                createdAt: Date(),
                lastLoginAt: Date()
            )

            completion(.success((credential, newUser)))
        }
    }

    // MARK: - 📘 Facebook Login Logic

    func startFacebookLogin(in viewController: UIViewController, completion: @escaping (Result<(AuthCredential, User), Error>) -> Void) {
        let loginManager = LoginManager()

        // We request "email" and "public_profile"
        loginManager.logIn(permissions: ["email", "public_profile"], from: viewController) { result, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let result = result, !result.isCancelled else {
                completion(.failure(SocialAuthError.cancelled))
                return
            }

            // 🔒 MANDATORY EMAIL CHECK (Facebook doesn't give email in 'result', we assume we have permission,
            // but we double check during graph request or assume success if permission granted).
            // For Firebase, we get the token first.

            guard let token = AccessToken.current?.tokenString else {
                completion(.failure(SocialAuthError.unknown))
                return
            }

            let credential = FacebookAuthProvider.credential(withAccessToken: token)

            // Note: Facebook SDK doesn't give email directly here easily without a Graph Request.
            // However, Firebase Auth will extract it.
            // If you strictly need to check BEFORE Firebase, we need a Graph Request.
            // For now, let's rely on Firebase to pull the email from the token.

            // Create partial user data
            let newUser = User(
                id: nil,
                username: nil, // FB doesn't give this easily here
                fullName: nil,
                email: "", // Will be filled by Firebase Auth result
                providerType: .facebook,
                isEmailVerified: true,
                isActive: true,
                isOnBoardingDone: false,
                isSubscribed: false,
                createdAt: Date(),
                lastLoginAt: Date()
            )

            completion(.success((credential, newUser)))
        }
    }

    // MARK: - 🍎 Apple Login Logic

    func startAppleLogin(completion: @escaping (Result<(AuthCredential, User), Error>) -> Void) {
        self.completion = completion

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()

        // We ask for Full Name and Email
        request.requestedScopes = [.fullName, .email]

        // Create nonce for Firebase Security
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - 🍎 Apple Delegate Extension

// This handles the response from the Apple Sheet

extension SocialAuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the current window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                completion?(.failure(SocialAuthError.unknown))
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                completion?(.failure(SocialAuthError.unknown))
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completion?(.failure(SocialAuthError.unknown))
                return
            }

            // 🔒 MANDATORY EMAIL CHECK
            // Note: Apple only shares email on the FIRST login. Afterwards it might be nil.
            // If it is nil, Firebase usually handles it if the account is linked.
            // But if it's the first time and no email, we block.

            let email = appleIDCredential.email ?? ""

            // Create Firebase Credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)

            // Setup Name (Apple logic is tricky, usually only available first time)
            var fullNameString: String?
            if let fullName = appleIDCredential.fullName {
                let given = fullName.givenName ?? ""
                let family = fullName.familyName ?? ""
                fullNameString = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
            }

            let newUser = User(
                id: nil,
                username: fullNameString,
                fullName: fullNameString,
                email: email, // Might be empty if existing user, handled in AuthManager
                providerType: .apple,
                isEmailVerified: true,
                isActive: true,
                isOnBoardingDone: false,
                isSubscribed: false,
                createdAt: Date(),
                lastLoginAt: Date()
            )

            completion?(.success((credential, newUser)))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
    }

    // MARK: - 🔐 Apple Security Helpers (Standard Boilerplate)

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// ... Inside LoginRegisterVC ...

// MARK: - Social Login Actions 🌍

@IBAction func btnAppleTapped(_ sender: UIButton) {
    HapticHelper.heavy() // Optional if you have this helper
    LoaderManager.shared.startLoading()

    SocialAuthManager.shared.startAppleLogin { [weak self] result in
        self?.handleSocialResult(result: result)
    }
}

@IBAction func btnGoogleTapped(_ sender: UIButton) {
    HapticHelper.heavy()
    LoaderManager.shared.startLoading()

    SocialAuthManager.shared.startGoogleLogin(in: self) { [weak self] result in
        self?.handleSocialResult(result: result)
    }
}

@IBAction func btnFacebookTapped(_ sender: UIButton) {
    HapticHelper.heavy()
    LoaderManager.shared.startLoading()

    SocialAuthManager.shared.startFacebookLogin(in: self) { [weak self] result in
        self?.handleSocialResult(result: result)
    }
}

// Helper to process the result from SocialAuthManager
private func handleSocialResult(result: Result<(AuthCredential, User), Error>) {
    switch result {
    case .success(let (credential, userData)):

        // Now verify with Firebase via AuthManager
        AuthManager.shared.signInWithSocialCredential(credential: credential, userDetails: userData) { [weak self] success, errorMsg in
            guard let self = self else { return }

            // AuthManager handles the Firestore saving, so we just handle UI here
            self.handleAuthResponse(success: success, error: errorMsg)
        }

    case let .failure(error):
        LoaderManager.shared.stopLoading()

        // Handle specific "No Email" case
        if let socialError = error as? SocialAuthError, socialError == .emailMissing {
            Utility.showAlert(title: "Email Missing", message: "We could not retrieve an email address from your social account. Please sign up using Email & Password instead.", viewController: self)
        } else if let socialError = error as? SocialAuthError, socialError == .cancelled {
            // User cancelled, do nothing
            print("User cancelled social login")
        } else {
            Utility.showAlert(title: "Login Failed", message: error.localizedDescription, viewController: self)
        }
    }
}


/// Handles the Firebase sign-in using credentials from SocialAuthManager
/// - Parameters:
///   - credential: The token from Google/Apple/FB
///   - userDetails: The "black data" (pre-filled user info) from the social provider
func signInWithSocialCredential(credential: AuthCredential, userDetails: User, completion: @escaping (Bool, String?) -> Void) {
    Auth.auth().signIn(with: credential) { authResult, error in

        // 1. Check Error
        if let error = error {
            let msg = self.getFriendlyError(error)
            completion(false, msg)
            return
        }

        guard let uid = authResult?.user.uid, let firebaseUser = authResult?.user else {
            completion(false, "User ID not found")
            return
        }

        Constants.Strings.currentUserID = uid

        // 🔒 FINAL EMAIL CHECK
        // Sometimes Social SDK passes empty email in the struct, but Firebase extracts it from the token.
        // We ensure email exists here.
        guard let email = firebaseUser.email, !email.isEmpty else {
            // If NO email, we delete this user and stop.
            firebaseUser.delete()
            completion(false, "This social account does not provide an email address. We require an email to proceed.")
            return
        }

        // 2. Check if User Document Exists in Firestore
        let userRef = Firestore.firestore().collection("users").document(uid)

        userRef.getDocument { snapshot, error in

            DispatchQueue.main.async {
                if let snapshot = snapshot, snapshot.exists {
                    // --- EXISTING USER ---
                    // Just update Last Login
                    userRef.updateData(["last_login_at": Date()])
                    print("✅ Social Login: Welcome back existing user.")
                    completion(true, nil)

                } else {
                    // --- NEW USER (First Time) ---
                    // Use the 'userDetails' passed from SocialAuthManager, but ensure ID and Email are correct from Firebase
                    var newUser = userDetails
                    newUser.id = uid
                    newUser.email = email // Ensure email is from Firebase Auth

                    // Save to Firestore
                    try? userRef.setData(from: newUser) { error in
                        if let error = error {
                            completion(false, "Database Error: \(error.localizedDescription)")
                        } else {
                            print("✅ Social Register: New User Created.")
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
}
*/
