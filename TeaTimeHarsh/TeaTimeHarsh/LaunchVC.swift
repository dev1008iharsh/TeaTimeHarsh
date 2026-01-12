//
//  LaunchVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import UIKit

class LaunchVC: UIViewController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if AppNetworkManager.shared.isConnected {
            print("🌍 Online Launch: Starting background sync...")
            UserDataManager.shared.fetchUserProfileIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.goToHome()
            }
        } else {
            print("🔌 Offline Launch")
            UserDataManager.shared.isUserUpdatedAtCurrentAppLaunch = false
            Utility
                .showAlertHandler(
                    title: "🔌 You’re Offline.Please enable internet connection to get latest data🔴",
                    message: """
                    You are currently using the offline version of the app.
                    You cannot perform any actions right now, but you can read data saved from your last available internet connection.

                    🌐 Connect to the internet to enable all features.
                    """,
                    viewController: self) { _ in
                        print("Offline alert ok tapped")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.goToHome()
                        }
                }
        }
    }

    // MARK: - Navigation

    private func goToHome() {
        DispatchQueue.main.async {
            // Safety Check
            if self.navigationController?.topViewController is HomeVC { return }

            let homeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC")
            self.navigationController?.setViewControllers([homeVC], animated: true)
        }
    }

    // MARK: - View Setup

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        print("💀 LaunchVC removed from memory")
    }
}
