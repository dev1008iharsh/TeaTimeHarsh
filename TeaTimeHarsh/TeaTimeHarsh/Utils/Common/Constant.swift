//
//  Constants.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/01/26.
//

import UIKit

struct Constants {
    struct Strings {
        static var currentUserID = ""
        static let appName = "TeaPlace"
        static let developerEmail = "dev.iharsh1008@gmail.com"
        static let registerTitle = "Register"
        static let ok = "OK"
        static let cancel = "Cancel"
    }

    struct URLs {
        static let baseURL = "https://api.myserver.com"
        static let login = "/auth/login"
        static let register = "/auth/register"
    }
}

final class UtilsProject {
    // 🔒 Private Init
    private init() {}

    // Key name to avoid spelling mistakes
    private static let notificationKey = "notifications_enabled"

    /// Returns TRUE if user previously turned switch ON, else FALSE
    static func isNotificationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: notificationKey)
    }

    /// Saves the switch status (ON or OFF)
    static func setNotificationState(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: notificationKey)
    }

    @MainActor
    static func logoutAndNavigateToLoginVC() {
        // 1. Get the Main Storyboard and Login VC
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginRegisterVC")
        let navVC = UINavigationController(rootViewController: loginVC)

        // 2. Find the active Window safely (Works from anywhere!)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }

        // 3. Swap the root view controller
        window.rootViewController = navVC

        // 4. Animate the transition
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionFlipFromRight,
            animations: nil
        )
    }

    static var getAppName: String {
        // 1. Try to get the "Display Name" (Home screen name)
        if let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }

        // 2. If not found, fallback to "Bundle Name" (Project name)
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }

        // 3. Fallback if everything fails
        return "TeaTimeHarsh App"
    }
}
