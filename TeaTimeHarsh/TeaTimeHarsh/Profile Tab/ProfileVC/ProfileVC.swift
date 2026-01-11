//
//  ProfileVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import UIKit

// This manages all your data. No more hard-coded strings in the VC!

enum ProfileSection: Int, CaseIterable {
    case personal
    case preferences
    case support
    case account

    var title: String {
        switch self {
        case .personal: return "Personal Details"
        case .preferences: return "App Preference"
        case .support: return "Support"
        case .account: return "Account management"
        }
    }

    var items: [ProfileRow] {
        switch self {
        case .personal: return [.editProfile, .favourites, .visited, .myPlaces]
        case .preferences: return [.language, .notification, .appearance, .appIcon]
        case .support: return [.help, .share, .rate, .bug, .privacy, .terms]
        case .account: return [.deleteAllPlaces, .deleteAccount, .logout]
        }
    }
}

enum ProfileRow {
    // Personal
    case editProfile, favourites, visited, myPlaces
    // Preferences
    case language, notification, appearance, appIcon
    // Support
    case help, share, rate, bug, privacy, terms
    // Account
    case deleteAllPlaces, deleteAccount, logout

    var title: String {
        switch self {
        case .editProfile: return "Edit Profile"
        case .favourites: return "Favourites"
        case .visited: return "Visited"
        case .myPlaces: return "My Places"
        case .language: return "Language"
        case .notification: return "Notification"
        case .appearance: return "Appearance"
        case .appIcon: return "Change app icon"
        case .help: return "Help & Support / FAQ"
        case .share: return "Share app"
        case .rate: return "Rate Us on App store"
        case .bug: return "Report bug"
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms & Conditions"
        case .deleteAllPlaces: return "Delete all created places"
        case .deleteAccount: return "Delete Account"
        case .logout: return "Log Out"
        }
    }

    var iconName: String {
        switch self {
        case .editProfile: return "person.crop.circle"
        case .favourites: return "heart"
        case .visited: return "mappin.and.ellipse"
        case .myPlaces: return "folder.badge.person.crop"
        case .language: return "globe"
        case .notification: return "bell.badge"
        case .appearance: return "moon.stars"
        case .appIcon: return "app.gift"
        case .help: return "questionmark.circle"
        case .share: return "square.and.arrow.up"
        case .rate: return "star"
        case .bug: return "ant"
        case .privacy: return "hand.raised"
        case .terms: return "doc.text"
        case .deleteAllPlaces: return "trash.circle"
        case .deleteAccount: return "trash"
        case .logout: return "square.and.arrow.up.circle"
        }
    }

    // Helper to check if this is a "Destructive" action (Red Color)
    var isDestructive: Bool {
        return self == .deleteAllPlaces || self == .deleteAccount || self == .logout
    }
}

// MARK: - View Controller

class ProfileVC: UIViewController {
    @IBOutlet var tblProfile: UITableView!
    lazy var profileHeader: ProfileHeaderCell = {
        // A. Load the XIB
        guard let header = Bundle.main.loadNibNamed("ProfileHeaderCell", owner: nil)?.first as? ProfileHeaderCell else {
            fatalError("❌ Could not load ProfileHeaderCell XIB file")
        }

        // B. Set the Frame
        // Note: We use a default height, but we can update it later
        header.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 120)

        // C. Configure the Tap Action immediately
        header.didTapProfileImage = { [weak self] in
            guard let self = self else { return }
            self.handleProfileImageTap() // 👇 Keeping logic clean by calling a function
        }
        return header
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tblProfile.tableHeaderView = profileHeader
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.tblProfile.reloadData()
            }
        }
    }

    // MARK: - Helper Functions

    func handleProfileImageTap() {
        print("Tapped!")
        // Accessing the global variable easily 👇
        let imageToZoom = profileHeader.imgProfile
        if ThemeManager.shared.isDarkModeActive {
            ImageZoomViewer.shared
                .showFullScreen(
                    from: imageToZoom ?? UIImageView(),
                    backgroundColor: .black
                )
        } else {
            ImageZoomViewer.shared.showFullScreen(from: imageToZoom ?? UIImageView(), backgroundColor: .white)
        }
    }
}

// MARK: - TableView Methods

extension ProfileVC: UITableViewDataSource, UITableViewDelegate {
    // 1. Sections from Enum
    func numberOfSections(in tableView: UITableView) -> Int {
        return ProfileSection.allCases.count
    }

    // 2. Title from Enum
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ProfileSection(rawValue: section)?.title
    }

    // 3. Rows from Enum Items
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = ProfileSection(rawValue: section) else { return 0 }
        return sectionType.items.count
    }

    // 4. Configure Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileItemCell", for: indexPath)

        // 🎯 Get the specific row data safely
        guard let sectionType = ProfileSection(rawValue: indexPath.section) else { return UITableViewCell() }
        let item = sectionType.items[indexPath.row]

        // Setup Basic Data
        cell.textLabel?.text = item.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.imageView?.image = UIImage(systemName: item.iconName)

        // Reset Text Color
        cell.detailTextLabel?.text = nil
        cell.textLabel?.textColor = .label
        cell.imageView?.tintColor = .systemIndigo

        // 🎨 Specific Visual Logic
        if item.isDestructive {
            cell.textLabel?.textColor = .red
            cell.imageView?.tintColor = .red
        }

        // Handle Detail Text (Right side text)
        switch item {
        case .notification:
            setupNotificationSwitch(for: cell)

        case .language:
            cell.detailTextLabel?.text = "English"

        case .appearance:
            let currentTheme = ThemeManager.shared.getCurrentTheme()
            cell.detailTextLabel?.text = currentTheme.title

        default:
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            break
        }

        return cell
    }

    private func setupNotificationSwitch(for cell: UITableViewCell) {
        let switchControl = UISwitch()
        switchControl.onTintColor = .systemIndigo
        switchControl.isOn = UserDefaults.standard.bool(forKey: "notifications_enabled")
        switchControl.addTarget(self, action: #selector(notificationToggled(_:)), for: .valueChanged)

        // Set the switch
        cell.accessoryView = switchControl

        // Remove the arrow (>) because switches don't need arrows
        cell.accessoryType = .none
    }

    @objc private func notificationToggled(_ sender: UISwitch) {
        // Save the new value using Utility
        UtilsProject.setNotificationState(sender.isOn)

        print(sender.isOn ? "🔔 Notification preference : On" : "🔕 Saved: Off")
    }

    // 5. THE MOST EFFICIENT DID SELECT 🚀
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Get the exact item enum
        guard let sectionType = ProfileSection(rawValue: indexPath.section) else { return }
        let item = sectionType.items[indexPath.row]

        // Switch on the Enum (Type Safe & Clean) ✅
        switch item {
        // Personal
        case .editProfile:
            print("👤 Edit Profile Tapped")
            let mainStoryboard = UIStoryboard(name: "Profile", bundle: nil)
            guard let editVC = mainStoryboard.instantiateViewController(withIdentifier: "EditProfileVC") as? EditProfileVC else { return }
            editVC.onProfileUpdated = { [weak self] in
                self?.profileHeader.setProfileImage()
            }
            navigationController?.pushViewController(editVC, animated: true)

        case .favourites:
            print("❤️ Favourites Tapped")
            navigateToHomeAndFilter(segmentIndex: 1)
        case .visited:
            print("📍 Visited Tapped")
            navigateToHomeAndFilter(segmentIndex: 2)
        case .myPlaces:
            print("🖐️ My Place Tapped")
            navigateToHomeAndFilter(segmentIndex: 3)

        // Preferences
        case .language:
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            print("🌍 Change Language")
        case .notification:
            print("🔔 Notification Settings")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
        case .appearance:
            print("🌗 Appearance Settings")
            showAppearanceOptions()
            
        case .appIcon:
            print("📱 Change app icon")
            navigateToChangeAppIcon()

        // Support
        case .help:
            print("❓ Help Tapped")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/blob/main/PRIVACY_POLICY.md")
        case .share:
            print("📤 Share App")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            openShareSheetShareApp()
        case .rate:
            print("⭐️ Rate App")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/")
        case .bug:
            print("🐜 Report Bug")
            presentReportBugVC()
        case .privacy:
            print("🔒 Privacy Policy")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/blob/main/PRIVACY_POLICY.md")
        case .terms:
            print("📄 Terms & Conditions")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/blob/main/PRIVACY_POLICY.md")
            // Account

        case .deleteAllPlaces:
            print("🗑️ Delete All Places ")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            loadUserData()

        case .deleteAccount:
            print("🗑️ Delete Account Logic")
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtProfile()
                return
            }
            performDeleteAccount()

        case .logout:
            print("🚪 Logout Logic")
            confirmLogout()
        }
    }

    private func loadUserData() {
        LoaderManager.shared.startLoading()
        Task { [weak self] in
            defer {
                DispatchQueue.main.async { LoaderManager.shared.stopLoading() }
            }
            guard let self = self else { return }
            do {
                let places = try await FirebaseManager.shared.fetchCurretnUserPlaces()

                print("Successfully loaded \(places.count) places.")

                if places.isEmpty {
                    Utility.showAlertHandler(
                        title: "Oops!",
                        message: "You haven't added any places.🍵 Tap the ➕ button on the Home screen to get started! ✨",
                        viewController: self
                    ) { _ in }
                } else {
                    let vc = UserPlacesListVC()
                    vc.places = places
                    present(vc, animated: true)
                }
            } catch {
                print("Error fetching user places: \(error.localizedDescription)")
            }
        }
    }

    func showOfflineAlertAtProfile() {
        Utility.showAlert(title: "No Internet 🛜", message: "Please connect to the internet to perform this profile screen action.", viewController: self)
    }

    // Helper function to switch tab and filter
    func navigateToHomeAndFilter(segmentIndex: Int) {
        // 1. 🔄 Switch to the Home Tab (Assuming Home is the 1st tab, index 0)
        // Change '0' if your Home Tab is at a different position
        tabBarController?.selectedIndex = 0

        // 2. 🕵️‍♂️ Find the HomeVC inside the Navigation Controller
        // We check the first tab's Navigation Controller to find 'HomeVC'
        if let navController = tabBarController?.viewControllers?[0] as? UINavigationController,
           let homeVC = navController.viewControllers.first as? HomeVC {
            // 3. ⚡️ Ensure the view is loaded so Outlets aren't nil
            // This prevents a crash if HomeVC hasn't been opened yet
            homeVC.loadViewIfNeeded()

            // 4. 🎛 Change the Segment Control Index
            homeVC.segmentFilter.selectedSegmentIndex = segmentIndex

            // 5. 🔄 Trigger the Action manually to reload the table
            homeVC.didChangeSegmentFilter(homeVC.segmentFilter)

            // Optional: Scroll to top to show fresh data
            if !homeVC.displayedPlaces.isEmpty {
                homeVC.tblTeaPlaces.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }

    private func navigateToChangeAppIcon() {
        let mainStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        guard let editVC = mainStoryboard.instantiateViewController(withIdentifier: "ChangeAppIconVC") as? ChangeAppIconVC else { return }
        navigationController?.pushViewController(editVC, animated: true)
    }

    private func presentReportBugVC() {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        if let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportBugVC") as? ReportBugVC {
            reportVC.modalPresentationStyle = .pageSheet
            present(reportVC, animated: true, completion: nil)
        }
    }

    private func confirmLogout() {
        Utility.showYesNoConfirmAlert(
            title: "Logout Alert",
            message: "Logging out will end your current session. Do you want to continue?",
            viewController: self
        ) { [weak self] _ in
            self?.performLogout()
        } noAction: { _ in }
    }

    private func performLogout() {
        let success = AuthManager.shared.signOut()
        if success {
            UtilsProject.logoutAndNavigateToLoginVC()
        } else {
            Utility.showAlert(title: "Error", message: "Could not log out.Please try again after some time.", viewController: self)
        }
    }

    func showAppearanceOptions() {
        let alert = UIAlertController(title: "Choose Appearance", message: "Select your preferred display mode", preferredStyle: .actionSheet)
        alert.view.tintColor = .systemIndigo // Your indigo color 💜

        // Helper closure to handle the update
        let updateTheme = { (theme: AppTheme) in
            ThemeManager.shared.apply(theme: theme)

            // 🚀 THIS IS THE KEY: Force the table to refresh the text
            self.tblProfile.reloadData()
        }

        alert.addAction(UIAlertAction(title: "System Default", style: .default, handler: { _ in
            updateTheme(.system)
        }))

        alert.addAction(UIAlertAction(title: "Light Mode", style: .default, handler: { _ in
            updateTheme(.light)
        }))

        alert.addAction(UIAlertAction(title: "Dark Mode", style: .default, handler: { _ in
            updateTheme(.dark)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    func openShareSheetShareApp() {
        // 1. The Promotional Text
        let textToShare = "Hey! Check out TeaTimeHarsh 🍵 — the ultimate app for tea lovers! You can find nearby tea spots, track your visits, and add your own favourite places. 🚀"

        // 2. The Link (Converted to a real URL object)
        if let urlToShare = URL(string: "https://github.com/dev1008iharsh/TeaTimeHarsh") {
            // 3. Pass BOTH items to the Activity Controller
            let objectsToShare: [Any] = [textToShare, urlToShare]

            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

            // iPad requires a source view to know where to pop up from
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }

            present(activityVC, animated: true, completion: nil)
        }
    }
}

extension ProfileVC {
    // 1. The Main Trigger
    // Now creates the Password Alert DIRECTLY (No extra "Are you sure" popup first)
    private func performDeleteAccount() {
        showReauthInputAlert()
    }

    // 2. The Password Popup (With the Full Warning Message)
    private func showReauthInputAlert() {
        // We combine your Title and Warning Message here
        let alertTitle = "Delete Entire Account?"

        // I added a small line break "\n\n" before the security instruction to make it readable
        let alertMessage = """
        This action will delete your profile and all your saved places. 📉 Everything you have added will be deleted. This action cannot be undone. 🚫 Once you delete, all data related to your account will be lost permanently. 🔴

        For your security, please enter your password to confirm deletion. 🔒
        """

        let alert = UIAlertController(
            title: alertTitle,
            message: alertMessage,
            preferredStyle: .alert
        )

        // Add the Password Text Field
        alert.addTextField { textField in
            textField.placeholder = "Enter your password"
            textField.isSecureTextEntry = true
        }

        // The "Delete" Button
        let deleteAction = UIAlertAction(title: "Delete Permanently", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            // 1. Check if text field is empty
            guard let password = alert.textFields?.first?.text, !password.isEmpty else {
                self.showErrorAlert(message: "Password cannot be empty.")
                return
            }

            // 2. Proceed to Verify & Delete
            self.deleteAccountWithPassword(password)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Delete Account cancelled by user")
        }

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    // 3. The Logic: Verify Password -> Then Delete
    private func deleteAccountWithPassword(_ password: String) {
        LoaderManager.shared.startLoading()

        Task {
            do {
                // STEP A: Verify Password with Firebase 🕵️‍♂️
                // If this fails (wrong password), it jumps to 'catch' block immediately.
                try await FirebaseManager.shared.reauthenticateWithPassword(password)

                // STEP B: Delete Everything 🗑️
                // We only run this if Step A succeeded
                try await FirebaseManager.shared.deleteEntireAccount()

                // STEP C: Success UI
                await MainActor.run {
                    LoaderManager.shared.stopLoading()
                    self.handleDeleteSuccess()
                }

            } catch {
                // Failure (Wrong password, etc.)
                await MainActor.run {
                    LoaderManager.shared.stopLoading()
                    // Show a helpful error message
                    self.showErrorAlert(message: "Incorrect password or network error. Please try again.")
                }
            }
        }
    }

    // MARK: - UI Helpers

    // 4. Success Handler
    private func handleDeleteSuccess() {
        HapticHelper.success()
        Utility.showAlertHandler(
            title: "Account Deleted ✅",
            message: "Your account has been permanently deleted. See you soon! 👋",
            viewController: self
        ) { _ in
            if AuthManager.shared.signOut() {
                UtilsProject.logoutAndNavigateToLoginVC()
            }
        }
    }

    // 5. Error Handler
    private func showErrorAlert(message: String) {
        HapticHelper.error()
        Utility.showAlert(
            title: "Error",
            message: message,
            viewController: self
        )
    }
}
