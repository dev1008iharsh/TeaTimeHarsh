//
//  SceneDelegate.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import FirebaseAuth
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 1. Create a new Window manually
        let window = UIWindow(windowScene: windowScene)

        // 2. Check Logic: User Login che ke nahi?
        if let user = Auth.auth().currentUser { 
            // ✅ SUCCESS: User Found
            print("*** User is Logged In. Going to Home. Current Firebase USER ID: \(user.uid)")

            // 💾 STORE ID GLOBALLY
            Constants.Strings.currentUserID = user.uid

            // ✅ CASE 1: USER LOGGED IN -> Go to Main Storyboard (Home)
            

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            // Note: Make sure your HomeVC has Storyboard ID "HomeVC"
            let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeVC")

            // Wrap in Navigation Controller (Recommended for Home flow)
            let navVC = UINavigationController(rootViewController: homeVC)
            window.rootViewController = navVC

        } else {
            // ❌ CASE 2: USER NOT LOGGED IN -> Go to Auth Storyboard (Login)
            print("User is NOT Logged In. Going to Login.")

            let storyboard = UIStoryboard(name: "Auth", bundle: nil)
            // Note: Make sure LoginRegisterVC has Storyboard ID "LoginRegisterVC"
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginRegisterVC")

            // Wrap in Navigation Controller (Optional, but good for structure)
            let navVC = UINavigationController(rootViewController: loginVC)
            window.rootViewController = navVC
        }

        // 3. Make the window visible
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        let count = UserDefaults.standard.integer(forKey: AppLaunchTracker.homeListingTipLaunchCount)
        UserDefaults.standard.set(count + 1, forKey: AppLaunchTracker.homeListingTipLaunchCount)

        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
