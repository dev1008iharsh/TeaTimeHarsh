//
//  HomeVC.swift
//  TeaTimeHarsh

import UIKit

class HomeVC: UIViewController {
    // MARK: - Outlets

    @IBOutlet var tblTeaPlaces: UITableView!

    // MARK: - Properties

    var arrTeaPlaces = [TeaPlace]()
    private let refreshControl = UIRefreshControl()

    // MARK: - Enums

    enum ActionType {
        case favorite
        case visited
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavBar()
        setupRefreshControl()

        // Initial Fetch
        fetchDataFromFirebase()

        presentTipIfNeeded()
    }

    deinit {
        print("💀 deinit HomeVC is dead. Memory Free!")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - Setup Methods

    private func setupTableView() {
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        tblTeaPlaces.delegate = self
        tblTeaPlaces.dataSource = self
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(fetchDataFromFirebase), for: .valueChanged)
        refreshControl.tintColor = .systemIndigo
        tblTeaPlaces.refreshControl = refreshControl
    }

    private func setupNavBar() {
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(didTapAddNavBar))
        let logoutButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(didTapLogoutNavBar))
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = logoutButton

        hideBackButtonNavBar(hidden: true, swipeEnabled: true)
        setLargeTitleSpacingNavBar(20)
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
        // setCustomBackButton(image: UIImage(named: "backButtonIcon") ?? UIImage(), text: "Back", color: .systemIndigo)
    }

    // MARK: - API & Data Handling 🌍

    @objc private func fetchDataFromFirebase() {
        if !refreshControl.isRefreshing { LoaderManager.shared.startLoading() }

        Task {
            do {
                let places = try await FirebaseManager.shared.fetchAllPlaces()
                await MainActor.run {
                    self.arrTeaPlaces = places
                    print("*fetchDataFromFirebase", self.arrTeaPlaces)
                    self.tblTeaPlaces.reloadData()
                    self.stopLoaders()
                }
            } catch {
                await MainActor.run {
                    self.stopLoaders()
                    Utility.showAlert(title: "Error", message: error.localizedDescription, viewController: self)
                }
            }
        }
    }

    private func stopLoaders() {
        LoaderManager.shared.stopLoading()
        refreshControl.endRefreshing()
    }

    // MARK: - Centralized Logic (The Brain with Rollback 🧠🛡️)

    // This is the NEW function you needed.

    private func toggleStatus(for placeID: String, action: ActionType) {
        // 1. Find the place index
        guard let index = arrTeaPlaces.firstIndex(where: { $0.id == placeID }) else { return }

        // 2. Keep Backup (Insurance Policy) 🏦
        let originalPlace = arrTeaPlaces[index]

        // 3. Optimistic Update (Change UI instantly) ⚡
        var modifiedPlace = originalPlace
        switch action {
        case .favorite: modifiedPlace.isFav.toggle()
        case .visited: modifiedPlace.isVisited.toggle()
        }

        // Update Array & UI
        arrTeaPlaces[index] = modifiedPlace

        // Use .none animation so it doesn't flicker on fast taps
        tblTeaPlaces.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        HapticHelper.medium()

        // 4. Server Sync with Error Handling (The Real Work) ☁️
        Task {
            do {
                try await FirebaseManager.shared.updateUserAction(
                    placeId: modifiedPlace.id,
                    isFav: modifiedPlace.isFav,
                    isVisited: modifiedPlace.isVisited
                )
                print("✅ Synced successfully")

            } catch {
                // 🛑 API FAILED! Rollback time! ↩️
                print("❌ Sync failed: \(error.localizedDescription)")

                await MainActor.run {
                    // A. Restore Original Data
                    self.arrTeaPlaces[index] = originalPlace

                    // B. Refresh UI to show old state
                    self.tblTeaPlaces.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)

                    // C. Feedback to user
                    HapticHelper.error() // Vibrate to verify failure
                }
            }
        }
    }

    private func deletePlace(at indexPath: IndexPath) {
        let place = arrTeaPlaces[indexPath.row]

        if place.createdByUserId != Constants.Strings.currentUserID {
            Utility.showAlert(title: "Access Denied", message: "You can only delete places created by you.", viewController: self)
            return
        }

        arrTeaPlaces.remove(at: indexPath.row)
        tblTeaPlaces.deleteRows(at: [indexPath], with: .automatic)
        HapticHelper.heavy()

        Task { try? await FirebaseManager.shared.deletePlace(placeId: place.id) }
    }

    // MARK: - Actions

    @objc private func didTapAddNavBar() {
        HapticHelper.success()
        let addVC = storyboard?.instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC
        addVC.screenMode = .add
        addVC.onPlaceAdded = { [weak self] _ in self?.fetchDataFromFirebase() }
        navigationController?.pushViewController(addVC, animated: true)
    }

    @objc private func didTapLogoutNavBar() {
        Utility
            .showYesNoConfirmAlert(
                title: "Logout",
                message: "Logging out will end your current session. Do you want to continue?",
                viewController: self) { _ in
                    self.performLogout()
            } noAction: { _ in }
    }

    func performLogout() {
        // Call AuthManager to sign out from Firebase
        let success = AuthManager.shared.signOut()

        if success {
            print("User Logged Out Successfully.")

            let storyboard = UIStoryboard(name: "Auth", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginRegisterVC")
            let navVC = UINavigationController(rootViewController: loginVC)
            
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                window.rootViewController = navVC
            }

        } else {
            Utility.showAlert(title: "Error", message: "Could not log out. Please try again.", viewController: self)
        }
    }

    private func presentTipIfNeeded() {
        guard HomeListingTipManager.shouldShowTip() else { return }
        let tipVC = storyboard?.instantiateViewController(withIdentifier: "HomeListingTipVC") as! HomeListingTipVC
        tipVC.modalPresentationStyle = .overFullScreen
        tipVC.modalTransitionStyle = .crossDissolve
        present(tipVC, animated: true)
    }
}

// MARK: - UITableView Delegate & DataSource

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrTeaPlaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeaListCell", for: indexPath) as! TeaListCell
        cell.configure(teaPlace: arrTeaPlaces[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "PlaceDetailVC") as! PlaceDetailVC
        let selectedPlace = arrTeaPlaces[indexPath.row]

        detailVC.place = selectedPlace

        detailVC.onBackToHome = { [weak self] in
            self?.tblTeaPlaces.reloadRows(at: [indexPath], with: .automatic)
        }

        // Linking Detail View to Central Logic
        detailVC.onVisitToggle = { [weak self] _ in
            self?.toggleStatus(for: selectedPlace.id, action: .visited)
        }

        detailVC.onFavToggle = { [weak self] _ in
            self?.toggleStatus(for: selectedPlace.id, action: .favorite)
        }

        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = makeDeleteAction(indexPath: indexPath)
        let share = makeShareAction(indexPath: indexPath)
        let edit = makeEditAction(indexPath: indexPath)

        let config = UISwipeActionsConfiguration(actions: [delete, share, edit])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let visited = makeVisitAction(indexPath: indexPath)
        let favorite = makeFavAction(indexPath: indexPath)

        let config = UISwipeActionsConfiguration(actions: [visited, favorite])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - Context Menu

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let place = arrTeaPlaces[indexPath.row]

        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in

            let callAction = UIAction(title: "Call", image: UIImage(systemName: "phone")) { _ in
                if let phone = place.phone, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }

            let favAction = UIAction(title: place.isFav ? "Remove Favourite" : "Add Favourite", image: UIImage(systemName: place.isFav ? "heart.slash" : "heart")) { [weak self] _ in
                self?.toggleStatus(for: place.id, action: .favorite)
            }

            let visitAction = UIAction(title: place.isVisited ? "Remove Visited" : "Mark Visited", image: UIImage(systemName: place.isVisited ? "checkmark.app" : "checkmark.app.fill")) { [weak self] _ in
                self?.toggleStatus(for: place.id, action: .visited)
            }

            return UIMenu(title: "", children: [callAction, favAction, visitAction])
        }
    }
}

// MARK: - Helper Functions (Actions)

extension HomeVC {
    private func makeDeleteAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deletePlace(at: indexPath)
            completion(true)
        }
        action.image = UIImage(systemName: "trash")
        return action
    }

    private func makeShareAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let self = self else { return }
            let place = self.arrTeaPlaces[indexPath.row]
            let text = self.generateShareText(for: place)
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.tblTeaPlaces
                popover.sourceRect = self.tblTeaPlaces.rectForRow(at: indexPath)
            }

            HapticHelper.heavy()
            self.present(activityVC, animated: true)
            completion(true)
        }
        action.backgroundColor = .systemBlue
        action.image = UIImage(systemName: "square.and.arrow.up")
        return action
    }

    private func makeEditAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { return }
            let place = self.arrTeaPlaces[indexPath.row]

            let addVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC
            addVC.screenMode = .edit(place)
            addVC.onPlaceAdded = { [weak self] _ in self?.fetchDataFromFirebase() }

            self.navigationController?.pushViewController(addVC, animated: true)
            completion(true)
        }
        action.backgroundColor = .systemOrange
        action.image = UIImage(systemName: "pencil")
        return action
    }

    private func makeFavAction(indexPath: IndexPath) -> UIContextualAction {
        let place = arrTeaPlaces[indexPath.row]
        let action = UIContextualAction(style: .normal, title: place.isFav ? "Unfav" : "Fav") { [weak self] _, _, completion in
            self?.toggleStatus(for: place.id, action: .favorite)
            completion(true)
        }
        action.backgroundColor = place.isFav ? .systemGray : .systemPink
        action.image = UIImage(systemName: place.isFav ? "heart.slash" : "heart.fill")
        return action
    }

    private func makeVisitAction(indexPath: IndexPath) -> UIContextualAction {
        let place = arrTeaPlaces[indexPath.row]
        let action = UIContextualAction(style: .normal, title: place.isVisited ? "Unvisit" : "Visit") { [weak self] _, _, completion in
            self?.toggleStatus(for: place.id, action: .visited)
            completion(true)
        }
        action.backgroundColor = place.isVisited ? .systemGray4 : .systemGreen
        action.image = UIImage(systemName: place.isVisited ? "checkmark.circle" : "checkmark.circle.fill")
        return action
    }

    private func generateShareText(for place: TeaPlace) -> String {
        return """
        📍 Place Details :
        🏷️ Place Name: \(place.name)
        📌 Location: \(place.location ?? "N/A")
        📞 Phone: \(place.phone ?? "N/A")
        ☕ Description: \(place.desc ?? "N/A")
        ⭐ Rating: \(String(format: "%.1f", place.rating ?? 0.0))
        """
    }
}
