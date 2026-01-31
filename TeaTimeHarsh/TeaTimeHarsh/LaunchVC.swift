//
//  LaunchVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import Network
import UIKit

import Network
import UIKit

class LaunchVC: UIViewController {
    // MARK: - Properties

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        checkInternet()
    }

    deinit {
        print("💀 LaunchVC removed from memory")
    }

    private func loadCachedUser() {
        if let user = UserDataManager.shared.loadUserFromUserDefaults() {
            print("🚀 Launch User Email: \(user.email)")
            print("🚀 Launch User Name: \(user.fullName ?? "nil")")
        }
    }

    private func checkInternet() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            self.networkMonitor.cancel()

            DispatchQueue.main.async {
                path.status == .satisfied
                    ? self.handleOnline()
                    : self.handleOffline()
            }
        }

        networkMonitor.start(queue: monitorQueue)
    }

    private func handleOnline() {
        print("🌍 Online Launch: Syncing user profile")
        // UserDataManager.shared.isUserUpdatedAtCurrentAppLaunch = false
        // already doen in api response
        UserDataManager.shared.fetchUserProfileIfNeeded()

        goToHome()
    }

    private func goToHome() {
        guard !(navigationController?.topViewController is HomeVC) else { return }

        let homeVC = UIStoryboard(
            name: "Main",
            bundle: nil
        ).instantiateViewController(withIdentifier: "HomeVC")

        navigationController?.setViewControllers([homeVC], animated: true)
    }

    private func handleOffline() {
        print("🔌 Offline Launch")

        UserDataManager.shared.isUserUpdatedAtCurrentAppLaunch = false

        AlertHelper.showAlertHandler(
            title: "🔌 You’re Offline",
            message: """
            You are currently using the offline version of the app.

            • You can view previously saved data
            • Actions are temporarily disabled

            🌐 Connect to the internet to unlock all features.
            """,
            vc: self
        ) { [weak self] _ in
            self?.goToHome()
        }
    }
}

extension LaunchVC {
    // MARK: - View Setup

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
