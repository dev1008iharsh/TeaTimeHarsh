//
//  AuthManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import FirebaseAuth
import Foundation

class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // MARK: - 1. Sign Up (Register) Function

    func registerUser(email: String, pass: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: pass) { _, error in

            if let error = error {
                // Here we convert the error to a friendly String BEFORE sending it back
                let friendlyMessage = self.getFriendlyError(error)
                print("Register Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            completion(true, nil)
        }
    }

    // MARK: - 2. Login (Sign In) Function

    func loginUser(email: String, pass: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: pass) { _, error in

            if let error = error {
                // Convert to friendly string
                let friendlyMessage = self.getFriendlyError(error)
                print("Login Error: \(friendlyMessage)")
                completion(false, friendlyMessage)
                return
            }

            completion(true, nil)
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
            return true
        } catch {
            return false
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
        case .userNotFound:
            return "Account does not exist! Please register first."

        case .wrongPassword:
            return "Incorrect Password. Please try again."

        case .invalidEmail:
            return "Invalid email format. Please check your email."

        case .emailAlreadyInUse:
            return "This email is already registered. Please login."

        case .weakPassword:
            return "Password is too weak. Use a stronger password."

        case .networkError:
            return "Network connection error. Check internet."

            // You can add more specific cases here if needed

        default:
            return "Error: \(error.localizedDescription)"
        }
    }
}
