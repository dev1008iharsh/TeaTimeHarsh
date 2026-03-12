import Network
import UIKit

class LaunchVC: UIViewController {
    // MARK: - Properties

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: AppConstants.Strings.networkMonitorQueue)

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
        // already done in api response
        UserDataManager.shared.fetchUserProfileIfNeeded()

        // After online tasks are done, decide where to go
        proceedToNextScreen()
    }

    private func handleOffline() {
        print("🔌 Offline Launch")
        ToastManager.shared.show(message: "You’re Offline ❌.\n 🌐 Connect to the internet to unlock all features.")
        HapticHelper.error()
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
            // User tapped OK on offline alert, now decide where to go
            self?.proceedToNextScreen()
        }
    }

    // MARK: - Routing Logic

    /// Centralized function to determine the next screen based on user state
    private func proceedToNextScreen() {
        // Check if user data exists to confirm login status
        let isLoggedIn = UserDataManager.shared.loadUserFromUserDefaults() != nil

        if !isLoggedIn {
            // User is NOT logged in -> Go to Login
            goToLogin()
        } else {
            // User IS logged in -> Check if MPIN is setup in Keychain
            let isMPINSet = KeychainManager.shared.getMPIN() != nil

            if isMPINSet {
                goToBiometricAuth()
            } else {
                goToHome()
            }
        }
    }

    // MARK: - Navigation Helpers

    private func goToHome() {
        guard !(navigationController?.topViewController is HomeVC) else { return }

        let homeVC = UIStoryboard(
            name: AppConstants.Storyboards.Main,
            bundle: nil
        ).instantiateViewController(
            withIdentifier: AppConstants.ViewControllers.HomeVC
        )

        navigationController?.setViewControllers([homeVC], animated: true)
    }

    private func goToLogin() {
        let loginVC = UIStoryboard(
            name: AppConstants.Storyboards.Auth,
            bundle: nil
        ).instantiateViewController(
            withIdentifier:AppConstants
                .ViewControllers.LoginRegisterVC)
        
        navigationController?.setViewControllers([loginVC], animated: true)
    }

    private func goToBiometricAuth() {
        let biometricVC = UIStoryboard(name: AppConstants.Storyboards.Auth,bundle: nil).instantiateViewController(withIdentifier: AppConstants.ViewControllers.BiometricMPinVC)
        navigationController?.setViewControllers([biometricVC], animated: true)
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
