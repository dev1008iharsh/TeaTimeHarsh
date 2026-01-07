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
        case .preferences: return [.language, .notification, .appearance]
        case .support: return [.help, .share, .rate, .bug, .privacy, .terms]
        case .account: return [.deleteAllPlaces, .deleteAccount, .logout]
        }
    }
}

enum ProfileRow {
    // Personal
    case editProfile, favourites, visited, myPlaces
    // Preferences
    case language, notification, appearance
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableHeader()
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.tblProfile.reloadData()
            }
        }
    }

    func setupTableHeader() {
        guard let header = Bundle.main.loadNibNamed("ProfileHeaderCell", owner: nil)?.first as? ProfileHeaderCell
        else { return }

        header.frame = CGRect(
            x: 0,
            y: 0,
            width: tblProfile.frame.width,
            height: 100
        )
        header.configure(image: UIImage(systemName: "person.circle.fill"))
        header.didTapProfileImage = { [weak self] in
            print("Tapped!")
            guard let self = self else { return }

            if ThemeManager.shared.isDarkModeActive {
                print("We are in the shadows! 🌑")
                ImageZoomViewer.shared
                    .showFullScreen(
                        from: header.imgProfile,
                        backgroundColor: .black
                    )
            } else {
                print("Let there be light! ☀️")
                ImageZoomViewer.shared.showFullScreen(from: header.imgProfile, backgroundColor: .white)
            }
        }

        tblProfile.tableHeaderView = header
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
            break
        }

        cell.accessoryType = .disclosureIndicator
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
            print("🌍 Change Language")
        case .notification:
            print("🔔 Notification Settings")
        case .appearance:
            print("🌗 Appearance Settings")
            showAppearanceOptions()

        // Support
        case .help:
            print("❓ Help Tapped")
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/blob/main/PRIVACY_POLICY.md")
        case .share:
            print("📤 Share App")
            openShareSheetShareApp()
        case .rate:
            print("⭐️ Rate App")
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/")
        case .bug:
            print("🐜 Report Bug")
            presentReportBugVC()
        case .privacy:
            print("🔒 Privacy Policy")
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/blob/main/PRIVACY_POLICY.md")
        case .terms:
            print("📄 Terms & Conditions")
            openSafari(url: "https://github.com/dev1008iharsh/TeaTimeHarsh/blob/main/PRIVACY_POLICY.md")
            // Account

        case .deleteAllPlaces:
            print("🗑️ Delete All Places ")

            let vc = UserPlacesListVC()
            vc.isDeleteAccount = false
            present(vc, animated: true)

        case .deleteAccount:
            print("🗑️ Delete Account Logic")
            let vc = UserPlacesListVC()
            vc.isDeleteAccount = true
            present(vc, animated: true)

        case .logout:
            print("🚪 Logout Logic")
            confirmLogout()
        }
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
