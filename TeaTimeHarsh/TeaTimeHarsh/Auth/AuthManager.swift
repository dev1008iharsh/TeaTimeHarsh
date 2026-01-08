//
//  AuthManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // MARK: - 1. Sign Up (Register) Function
 
    func registerUser(email: String, pass: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: pass) { authResult, error in

            // Check Auth Error
            if let error = error {
                let friendlyMessage = self.getFriendlyError(error)
                print("Register Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            // Get UID safely
            guard let uid = authResult?.user.uid else {
                completion(false, "No User ID found")
                return
            }
            print("*uid",uid)

            Constants.Strings.currentUserID = uid

            // Create User Model (Explicitly setting all values)
            let newUser = User(id: uid, username: nil, email: email, bio: nil, phoneNumber: nil, city: nil, profileImageUrl: nil, birthDate: nil, providerID: nil, providerType: .email, isEmailVerified: false, isActive: true, isOnBoardingDone: false, isSubscribed: false, createdAt: Date(), lastLoginAt: Date(), fcmToken: nil)

            // Save to Firestore
            let db = Firestore.firestore()
            try? db.collection("users").document(uid).setData(from: newUser) { error in
                if let error = error {
                    print("Firestore Error: \(error.localizedDescription)")
                    completion(false, "Database save failed")
                } else {
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
                print("Login Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            // 2. Get UID
            guard let uid = authResult?.user.uid else { completion(false, "User ID not found"); return }
            print("*uid",uid)
            Constants.Strings.currentUserID = uid

            // 3. Fetch User Profile
            let userRef = Firestore.firestore().collection("users").document(uid)
            
            // ⚠️ FIX: Firebase replies on a background thread.
            userRef.getDocument { snapshot, error in
                
                // 🚀 JUMP TO MAIN THREAD IMMEDIATELY
                // This satisfies the "Main actor-isolated" requirement and prevents the warning.
                DispatchQueue.main.async {
                    
                    // Check snapshot and Decode User (Now safe on Main Thread)
                    guard let snapshot = snapshot, snapshot.exists, let user = try? snapshot.data(as: User.self) else {
                        completion(false, "User profile missing in database")
                        return
                    }
                    
                    // 4. Security Check
                    if !user.isActive {
                        try? Auth.auth().signOut()
                        completion(false, "Your account has been disabled/banned.")
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
                print("Reset Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            completion(true, nil)
        }
    }

    // MARK: - 4. Logout Function

    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            // 🧹 CLEANUP: Clear the stored ID on logout
            Constants.Strings.currentUserID = ""
            // 3. 🧼 WIPE: Remove all sensitive data from Keychain
            resetKeychain()
            return true
        } catch {
            return false
        }
    }

    private func resetKeychain() {
        // These are the types of items we want to delete
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]

        // Loop through every type and delete them
        for itemClass in secItemClasses {
            let spec: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(spec as CFDictionary)
        }
    }

    // MARK: - 🔒 Private Error Helper (The Translator)
 
    private func getFriendlyError(_ error: Error) -> String {
        let nsError = error as NSError

        // ✨ FIX: Removed '.Code' (Latest Firebase Syntax)
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch errorCode {
            
        // --- 🟢 Basic Email/Password Errors ---
        case .userNotFound:
            return "Account does not exist! Please register first."

        case .wrongPassword:
            return "Incorrect Password. Please try again."

        case .invalidEmail:
            return "Invalid email format. Please check your email."

        case .emailAlreadyInUse:
            return "⚠️ This email is already registered. Please login instead."

        case .weakPassword:
            return "Password is too weak. Use a stronger password."

        case .networkError:
            return "Network connection error. Check internet."
            
            
        // --- 🆕 NEW: Social Login & Account Linking Errors ---
            
        case .accountExistsWithDifferentCredential:
            // 🚨 THIS IS THE "CROSS THINK" ERROR!
            // It happens when user tries Google login, but email already exists via Facebook/Password
            return "An account already exists with the same email but different sign-in credentials. Please sign in using your original method."
            
        case .credentialAlreadyInUse:
            // This happens if you are trying to LINK a social account that belongs to someone else
            return "This social account is already linked to another user."
            

        // --- 🔴 Default ---
        default:
            // It is good to print the raw code for debugging unexpected issues
            return "Error: \(error.localizedDescription)"
        }
    }
}
