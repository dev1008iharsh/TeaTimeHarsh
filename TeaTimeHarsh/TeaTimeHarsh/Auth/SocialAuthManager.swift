//
//  SocialAuthManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 09/01/26.
//

import FacebookLogin // 📘 Facebook Official SDK
import FirebaseAuth // For Firebase Auth & Credentials
import FirebaseCore // For FirebaseApp options
import Foundation
import GoogleSignIn // 🌍 Google Official SDK
import UIKit

// Custom Error to handle specific failures
enum SocialAuthError: Error {
    case emailMissing
    case cancelled
    case unknown
    case missingClientID
    case facebookLoginFailed(String)
    case graphRequestFailed
}

class SocialAuthManager: NSObject {
    // MARK: - 1. Singleton Instance

    static let shared = SocialAuthManager()

    override private init() {}

    // MARK: - 🌍 Google Login Logic (Stays Async - It is Native)

    @MainActor
    func startGoogleLogin(in viewController: UIViewController) async throws -> (AuthCredential, User) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw SocialAuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Google supports async natively, so no continuation needed here!
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let user = result.user

        guard let idToken = user.idToken?.tokenString else { throw SocialAuthError.unknown }
        let accessToken = user.accessToken.tokenString

        guard let email = user.profile?.email, !email.isEmpty else {
            GIDSignIn.sharedInstance.signOut()
            throw SocialAuthError.emailMissing
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        let newUser = User(
            id: nil,
            username: user.profile?.name,
            fullName: user.profile?.name,
            email: email,
            profileImageUrl: user.profile?.imageURL(withDimension: 320)?.absoluteString,
            providerType: .google,
            isEmailVerified: true,
            isActive: true,
            isOnBoardingDone: false,
            isSubscribed: false,
            createdAt: Date(),
            lastLoginAt: Date()
        )

        return (credential, newUser)
    }

    // MARK: - 📘 Facebook Login Logic (Changed to Completion Handler)

    // We removed 'async' and 'continuation' here to make it simpler.

    func startFacebookLogin(in viewController: UIViewController, completion: @escaping (Result<(AuthCredential, User), Error>) -> Void) {
        let loginManager = LoginManager()

        // 1. Start Login
        loginManager.logIn(permissions: ["public_profile", "email"], from: viewController) { result, error in

            // Handle Error
            if let error = error {
                completion(.failure(SocialAuthError.facebookLoginFailed(error.localizedDescription)))
                return
            }

            // Handle Cancel
            guard let result = result, !result.isCancelled else {
                completion(.failure(SocialAuthError.cancelled))
                return
            }

            // Handle Success Token
            guard let tokenString = AccessToken.current?.tokenString else {
                completion(.failure(SocialAuthError.unknown))
                return
            }

            // 2. Fetch Profile Data (Nested Callback)
            self.fetchFacebookProfileData { result in
                switch result {
                case let .success(fbData):

                    // 🔒 Mandatory Email Check
                    guard let email = fbData["email"] as? String, !email.isEmpty else {
                        loginManager.logOut()
                        completion(.failure(SocialAuthError.emailMissing))
                        return
                    }

                    let name = fbData["name"] as? String

                    // Parsing Profile Picture
                    let pictureData = fbData["picture"] as? [String: Any]
                    let pictureDataInside = pictureData?["data"] as? [String: Any]
                    let pictureUrl = pictureDataInside?["url"] as? String

                    print("name",name ?? "")
                    print("pictureUrl",pictureUrl ?? "")
                    print("email",email)
                    // 3. Create Firebase Credential
                    let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)

                    // 4. Create User Object
                    let newUser = User(
                        id: nil,
                        username: name,
                        fullName: name,
                        email: email,
                        profileImageUrl: pictureUrl,
                        providerType: .facebook,
                        isEmailVerified: true,
                        isActive: true,
                        isOnBoardingDone: false,
                        isSubscribed: false,
                        createdAt: Date(),
                        lastLoginAt: Date()
                    )

                    // ✅ Return Success via Completion
                    completion(.success((credential, newUser)))

                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - 🛠 Helper: Facebook Graph Request (Completion Based)

    private func fetchFacebookProfileData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let request = GraphRequest(
            graphPath: "me",
            parameters: ["fields": "id, name, email, picture.type(large)"]
        )

        request.start { _, result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = result as? [String: Any] {
                completion(.success(data))
            } else {
                completion(.failure(SocialAuthError.graphRequestFailed))
            }
        }
    }
}
