//
//  AuthManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 09/01/26.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthManager {
    static let shared = AuthManager()
    private init() {}

    var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    // MARK: - 1. Sign Up (Register) Function

    func registerUser(email: String, pass: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: pass) { authResult, error in

            // Check Auth Error
            if let error = error {
                let friendlyMessage = self.getFriendlyError(error)
                print("❌ Register Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            // Get UID safely
            guard let uid = authResult?.user.uid else {
                completion(false, "No User ID found")
                return
            }
            print(" *✅ register uid", uid)

            AppConstants.Strings.currentUserID = uid

            // Create User Model (Explicitly setting all values) - because this model directly could not save in user-default
            let newUser = User(id: uid, username: nil, email: email, bio: nil, phoneNumber: nil, city: nil, profileImageUrl: nil, birthDate: nil, providerID: nil, providerType: .email, isEmailVerified: false, isActive: true, isOnBoardingDone: false, isSubscribed: false, createdAt: Date(), lastLoginAt: Date(), fcmToken: nil)

            // Save to Firestore
            let db = Firestore.firestore()
            try? db.collection("users").document(uid).setData(from: newUser) { error in
                if let error = error {
                    print("❌ Firestore Error: \(error.localizedDescription)")
                    completion(false, "Database save failed")
                } else {
                    print("✅Registered User Email : ", newUser.email)
                    UserDataManager.shared.saveUserToUserDefaults(newUser)
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - 2. Login (Sign In) Function

    func loginUser(email: String, pass: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: pass) { authResult, error in

            // 1. Check Auth Error
            if let error = error {
                let friendlyMessage = self.getFriendlyError(error)
                print("❌ Login Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            // 2. Get UID
            guard let uid = authResult?.user.uid else { completion(false, "User ID not found"); return }
            print("*✅ login uid", uid)
            AppConstants.Strings.currentUserID = uid

            // 3. Fetch User Profile
            let userRef = Firestore.firestore().collection("users").document(uid)

            // ⚠️  Firebase replies on a background thread.
            userRef.getDocument { snapshot, _ in

                // 🚀 JUMP TO MAIN THREAD IMMEDIATELY
                // This satisfies the "Main actor-isolated" requirement and prevents the warning.
                DispatchQueue.main.async {
                    // Check snapshot and Decode User (Now safe on Main Thread)
                    guard let snapshot = snapshot, snapshot.exists, let user = try? snapshot.data(as: User.self) else {
                        completion(false, "User profile missing in database ❌")
                        return
                    }

                    // 4. Security Check
                    if !user.isActive {
                        try? Auth.auth().signOut()
                        completion(false, "Your account has been disabled/banned. 🔴")
                        return
                    }

                    // 5. Success
                    userRef.updateData(["last_login_at": Date()])
                    print("✅ Login Verified: \(user.username ?? "User")")
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - 3. Forgot Password Function

    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in

            if let error = error {
                let friendlyMessage = self.getFriendlyError(error)
                print("❌ Reset Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            completion(true, nil)
        }
    }

    // MARK: - 4. Logout Function

    func signOut() -> Bool {
        if isUserLoggedIn {
            do {
                try Auth.auth().signOut()
                SocialAuthManager.shared.signOutSocialIfNeeded()
                resetKeychain()
                clearAllUserDefaults()
                AppConstants.Strings.currentUserID = ""
                CoreDataManager.shared.clearAllDataOfCoreData()
                UserDataManager.shared.user = nil
                UserProfileImageStorage.clearAllStoredFiles()
                print("✅ Successfully sign-out (All data cleared)")
                return true
            } catch {
                print("❌ Sign out error: \(error)")
                return false
            }
        } else {
            print("❌ User already logged-out. Sign out error")
            return false
        }
    }

    private func resetKeychain() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for itemClass in secItemClasses {
            let spec: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(spec as CFDictionary)
        }
    }

    func clearAllUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
    }

    // MARK: - 5. Social Login Handler 🌐

    func signInWithSocialCredential(credential: AuthCredential, userDetails: User) async throws {
        // 1. Sign in with Firebase
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        let uid = firebaseUser.uid
        AppConstants.Strings.currentUserID = uid

        // 2. 🔒 Final Email Check
        guard let email = firebaseUser.email, !email.isEmpty else {
            try? await firebaseUser.delete()
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "This social account does not provide an email address."])
        }

        let userRef = Firestore.firestore().collection("users").document(uid)

        // 3. Check Firestore
        let snapshot = try await userRef.getDocument()

        if snapshot.exists {
            // --- EXISTING USER ---
            try await userRef.updateData(["last_login_at": Date()])
            print("✅ Social Login: Welcome back existing user.")
        } else {
            // --- NEW USER ---
            var newUser = userDetails
            newUser.id = uid
            newUser.email = email
            newUser.providerID = userDetails.providerID
            print("✅ Final Submitting to Firebase signInWithSocialCredential UID :\(uid)\n  Email :\(email)\n  userDetail.EmailId :\(userDetails.email) \n ProviderID :\(userDetails.providerID ?? "") \n ProfileImageUrl :\(userDetails.profileImageUrl ?? "")\n UserName : \(userDetails.username ?? "")")

            try userRef.setData(from: newUser)
            print("✅ Social Register: New User Created.")
        }
    }

    // MARK: - 🛠️ Error Helper (The Translator)

    private func getFriendlyError(_ error: Error) -> String {
        let nsError = error as NSError

        // If it's a custom error we threw manually (like Banned user), use that description
        if nsError.domain == "Auth" || nsError.domain == "AuthError" {
            return error.localizedDescription
        }

        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch errorCode {
        case .userNotFound:
            return "Account does not exist! Please register first."

        case .wrongPassword:
            return "Incorrect Password. Please try again."

        case .invalidEmail:
            return "Invalid email format."

        case .emailAlreadyInUse:
            return "⚠️ This email is already registered. Please login.It may be registered with social login also so try that."

        case .weakPassword:
            return "Password is too weak."

        // Common additional auth errors
        case .networkError:
            return "Network connection error. Check your internet."

        case .accountExistsWithDifferentCredential:
            return "Account exists with a different sign-in method."

        case .credentialAlreadyInUse:
            return "This social account is already linked to another user."

        // User state related errors
        case .userDisabled:
            return "Your account was disabled. Contact support if needed."

        case .requiresRecentLogin:
            return "Please login again to continue."

        // Provider / credential errors
        case .invalidCredential:
            return "Invalid credentials provided. Try again."

        case .operationNotAllowed:
            return "This sign-in method is disabled in server settings."

        case .providerAlreadyLinked:
            return "This provider is already linked to the user."

        case .noSuchProvider:
            return "This sign-in provider is not available."

        // Too many tries / throttling
        case .tooManyRequests:
            return "Too many attempts. Please wait and try again."

        // App security / authorization
        case .appNotAuthorized:
            return "This app is not authorized to use Firebase Auth."

        case .keychainError:
            return "Secure storage (Keychain) error occurred."

        // Fallback / others
        default:
            return "Error: \(error.localizedDescription)"
        }
    }
}

/*

 // Phone / verification related (if using phone auth)
 case .missingPhoneNumber:
     return "Phone number is required for verification."

 case .invalidPhoneNumber:
     return "Invalid phone number format."

 case .missingVerificationCode:
     return "Verification code is missing."

 case .missingVerificationID:
     return "Verification ID is missing."

 case .captchaCheckFailed:
     return "CAPTCHA validation failed. Try again."

 case .appNotVerified:
     return "App verification failed. Try again later."

 // Multi-factor auth related
 case .secondFactorRequired:
     return "Second factor required. Complete additional authentication."

 case .missingMultiFactorSession:
     return "Missing multi-factor session. Start sign-in again."
 */
