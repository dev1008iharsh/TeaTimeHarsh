//
//  HomeVC.swift
//  TeaTimeHarsh
//
//  Created by your AI Mentor 🤖
//

import UIKit

class HomeVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var tblTeaPlaces: UITableView!

    // MARK: - Properties
    
    // 1. Action Manager (For Edit/Delete/Share)
    lazy var actionManager = TeaActionManager(viewController: self)
    
    // 2. Loading State
    var isLoading = true {
        didSet { setNeedsUpdateContentUnavailableConfiguration() }
    }
    
    // 3. Data Source
    var arrTeaPlaces = [TeaPlace]() {
        didSet { setNeedsUpdateContentUnavailableConfiguration() }
    }

    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAllUI()
        fetchDataFromFirebase()
        presentTipIfNeeded()
        
        // 🎧 START LISTENING TO NOTIFICATIONS (Restored from your code)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFavNotification(_:)), name: .teaPlaceDidTapFav, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVisitNotification(_:)), name: .teaPlaceDidTapVisit, object: nil)
    }

    deinit {
        print("💀 deinit HomeVC is dead. Memory Free!")
        // 🗑️ Stop Listening
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        // Refresh list if returning from detail to ensure consistency
        if !arrTeaPlaces.isEmpty { tblTeaPlaces.reloadData() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    // MARK: - 🔔 NOTIFICATION HANDLERS (Restored)
    @objc func handleFavNotification(_ notification: Notification) {
        guard let placeID = notification.userInfo?["placeID"] as? String,
              let isFav = notification.userInfo?["isFav"] as? Bool,
              let index = arrTeaPlaces.firstIndex(where: { $0.id == placeID }) else { return }
        
        print("🔔 Notification Received: Fav \(isFav) for \(arrTeaPlaces[index].name)")

        // 1. UPDATE MODEL LOCALLY (Optimistic)
        arrTeaPlaces[index].isFav = isFav
        
        // Reload just that row
        let indexPath = IndexPath(row: index, section: 0)
        tblTeaPlaces.reloadRows(at: [indexPath], with: .none)
        
        // 2. CALL API
        callApiToToggleStatus(place: arrTeaPlaces[index], type: "fav")
    }
    
    @objc func handleVisitNotification(_ notification: Notification) {
        guard let placeID = notification.userInfo?["placeID"] as? String,
              let isVisited = notification.userInfo?["isVisited"] as? Bool,
              let index = arrTeaPlaces.firstIndex(where: { $0.id == placeID }) else { return }
        
        print("🔔 Notification Received: Visited \(isVisited) for \(arrTeaPlaces[index].name)")

        // 1. UPDATE MODEL LOCALLY
        arrTeaPlaces[index].isVisited = isVisited
        let indexPath = IndexPath(row: index, section: 0)
        tblTeaPlaces.reloadRows(at: [indexPath], with: .none)
        
        // 2. CALL API
        callApiToToggleStatus(place: arrTeaPlaces[index], type: "visit")
    }

    // MARK: - 🌍 Central API Logic with REVERT (Restored)
    // Used by both Notifications AND Swipe Actions
    private func callApiToToggleStatus(place: TeaPlace, type: String) {
        Task {
            do {
                try await FirebaseManager.shared.updateUserAction(
                    placeId: place.id,
                    isFav: place.isFav,
                    isVisited: place.isVisited
                )
                print("✅ API Success for \(type)")
            } catch {
                // ⚠️ API FAILED - REVERT LOGIC ⚠️
                print("❌ API Failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    // 1. Revert Local Model in Home List
                    if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == place.id }) {
                        if type == "fav" { self.arrTeaPlaces[index].isFav.toggle() }
                        if type == "visit" { self.arrTeaPlaces[index].isVisited.toggle() }
                        
                        // Reload Row
                        self.tblTeaPlaces.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                    
                    // 2. Notify DetailHeader to Revert (Visually fix the button if Detail is open)
                    NotificationCenter.default.post(
                        name: .teaPlaceUpdateFailed,
                        object: nil,
                        userInfo: ["placeID": place.id, "actionType": type]
                    )
                    
                    // 3. Show Alert
                    HapticHelper.error()
                    Utility.showAlert(title: "Connection Error", message: "Could not update status. Reverting changes.", viewController: self)
                }
            }
        }
    }

    // MARK: - Empty State (iOS 17+)
    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        if isLoading {
            contentUnavailableConfiguration = nil
            return
        }
        guard arrTeaPlaces.isEmpty else {
            contentUnavailableConfiguration = nil
            return
        }
        
        // ✅ SHOW EMPTY STATE: Exact configuration restored
        var config = UIContentUnavailableConfiguration.empty()
        config.image = UIImage(systemName: "cup.and.heat.waves.fill")
        config.text = "It’s Tea-rribly Empty Here!"
        config.secondaryText = "No tea spots found yet. Be the first to spill the tea and add your favorite place!"
        config.imageProperties.tintColor = .systemIndigo
        
        // Add Button with Plus Icon
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.cornerStyle = .capsule
        buttonConfig.title = "Add First Tea Place"
        buttonConfig.image = UIImage(systemName: "plus")
        buttonConfig.imagePadding = 8 
        buttonConfig.baseBackgroundColor = .systemIndigo
        config.button = buttonConfig
        
        // Button Action
        config.buttonProperties.primaryAction = UIAction { [weak self] _ in
            self?.didTapAddNavBar()
        }
        
        contentUnavailableConfiguration = config
    }

    // MARK: - Setup Methods
    private func setupAllUI() {
        setupTableView()
        setupNavBar()
        setupRefreshControl()
    }

    private func setupTableView() {
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        tblTeaPlaces.delegate = self
        tblTeaPlaces.dataSource = self
        tblTeaPlaces.tableFooterView = UIView()
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(fetchDataFromFirebase), for: .valueChanged)
        refreshControl.tintColor = .systemIndigo
        tblTeaPlaces.refreshControl = refreshControl
    }

    private func setupNavBar() {
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(didTapAddNavBar))
        let logoutButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(confirmLogout))
        
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = logoutButton

        hideBackButtonNavBar(hidden: true, swipeEnabled: true)
        setLargeTitleSpacingNavBar(20)
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
    }

    // MARK: - Fetch Data
    @objc private func fetchDataFromFirebase() {
        if !refreshControl.isRefreshing {
            isLoading = true
            LoaderManager.shared.startLoading()
        }

        Task {
            defer {
                Task { @MainActor in
                    self.isLoading = false
                    self.stopLoaders()
                }
            }
            
            do {
                let places = try await FirebaseManager.shared.fetchAllPlaces()
                await MainActor.run {
                    print("*fetchDataFromFirebase",places)
                    self.arrTeaPlaces = places
                    self.tblTeaPlaces.reloadData()
                }
            } catch {
                await MainActor.run {
                    Utility.showAlert(title: "Error", message: error.localizedDescription, viewController: self)
                }
            }
        }
    }

    private func stopLoaders() {
        LoaderManager.shared.stopLoading()
        refreshControl.endRefreshing()
    }

    // MARK: - Actions & Navigation
    @objc private func didTapAddNavBar() {
        HapticHelper.success()
        let addVC = storyboard?.instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC
        addVC.screenMode = .add
        addVC.onPlaceAdded = { [weak self] _ in self?.fetchDataFromFirebase() }
        navigationController?.pushViewController(addVC, animated: true)
    }

    @objc private func confirmLogout() {
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
            navigateToLogin()
        } else {
            Utility.showAlert(title: "Error", message: "Could not log out.", viewController: self)
        }
    }
    
    private func navigateToLogin() {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginRegisterVC")
        let navVC = UINavigationController(rootViewController: loginVC)
        
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = navVC
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
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
        navigateToDetail(for: indexPath)
    }
    
    private func navigateToDetail(for indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "PlaceDetailVC") as! PlaceDetailVC
        let selectedPlace = arrTeaPlaces[indexPath.row]
        detailVC.place = selectedPlace

        // Closure for when we come back (Updates if Edit/Delete happened)
        detailVC.onBackToHome = { [weak self] in
            self?.fetchDataFromFirebase()
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - 🎨 Swipe Actions & Context Menu (Restored + Synced with API Logic)
extension HomeVC {
    
    // 1. Trailing Swipe (Right -> Left): Delete, Share, Edit
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = makeDeleteAction(indexPath: indexPath)
        let share = makeShareAction(indexPath: indexPath)
        let edit = makeEditAction(indexPath: indexPath)

        let config = UISwipeActionsConfiguration(actions: [delete, share, edit])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // 2. Leading Swipe (Left -> Right): Visited, Favorite
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let visited = makeVisitAction(indexPath: indexPath)
        let favorite = makeFavAction(indexPath: indexPath)

        let config = UISwipeActionsConfiguration(actions: [visited, favorite])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // 3. Context Menu (Long Press)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let place = arrTeaPlaces[indexPath.row]

        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
            
            let callAction = UIAction(title: "Call", image: UIImage(systemName: "phone")) { _ in
                if let phone = place.phone, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            
            let favTitle = place.isFav ? "Remove Favourite" : "Add Favourite"
            let favImage = UIImage(systemName: place.isFav ? "heart.slash" : "heart")
            let favAction = UIAction(title: favTitle, image: favImage) { [weak self] _ in
                self?.performSwipeToggle(at: indexPath, type: "fav")
            }

            let visitTitle = place.isVisited ? "Remove Visited" : "Mark Visited"
            let visitImage = UIImage(systemName: place.isVisited ? "checkmark.app" : "checkmark.app.fill")
            let visitAction = UIAction(title: visitTitle, image: visitImage) { [weak self] _ in
                self?.performSwipeToggle(at: indexPath, type: "visit")
            }

            return UIMenu(title: "", children: [callAction, favAction, visitAction])
        }
    }
    
    // 🔥 HELPER: Triggers the same logic as Notifications, but for Swipes/Menu
    private func performSwipeToggle(at indexPath: IndexPath, type: String) {
        // 1. Update Model Locally
        if type == "fav" { arrTeaPlaces[indexPath.row].isFav.toggle() }
        if type == "visit" { arrTeaPlaces[indexPath.row].isVisited.toggle() }
        
        // 2. Reload Row
        tblTeaPlaces.reloadRows(at: [indexPath], with: .none)
        
        // 3. Call API (Using the robust logic with revert)
        callApiToToggleStatus(place: arrTeaPlaces[indexPath.row], type: type)
    }
}

// MARK: - Contextual Action Creators
extension HomeVC {
    
    private func makeDeleteAction(indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            let place = self.arrTeaPlaces[indexPath.row]
            
            self.actionManager.performDelete(place: place) {
                self.arrTeaPlaces.remove(at: indexPath.row)
                completion(true)
            }
        }
    }

    private func makeShareAction(indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let self = self else { return }
            let cell = self.tblTeaPlaces.cellForRow(at: indexPath)
            self.actionManager.performShare(place: self.arrTeaPlaces[indexPath.row], sourceView: cell ?? self.view)
            completion(true)
        }
    }
    
    private func makeEditAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { return }
            let place = self.arrTeaPlaces[indexPath.row]
            self.actionManager.performEdit(place: place) {
                self.fetchDataFromFirebase()
            }
            completion(true)
        }
        action.backgroundColor = .systemOrange
        action.image = UIImage(systemName: "pencil")
        return action
    }

    private func makeFavAction(indexPath: IndexPath) -> UIContextualAction {
        let place = arrTeaPlaces[indexPath.row]
        let action = UIContextualAction(style: .normal, title: place.isFav ? "Unfav" : "Fav") { [weak self] _, _, completion in
            // Use helper to trigger same logic as Notification
            self?.performSwipeToggle(at: indexPath, type: "fav")
            completion(true)
        }
        action.backgroundColor = place.isFav ? .systemGray : .systemPink
        action.image = UIImage(systemName: place.isFav ? "heart.slash" : "heart.fill")
        return action
    }

    private func makeVisitAction(indexPath: IndexPath) -> UIContextualAction {
        let place = arrTeaPlaces[indexPath.row]
        let action = UIContextualAction(style: .normal, title: place.isVisited ? "Unvisit" : "Visit") { [weak self] _, _, completion in
            // Use helper to trigger same logic as Notification
            self?.performSwipeToggle(at: indexPath, type: "visit")
            completion(true)
        }
        action.backgroundColor = place.isVisited ? .systemGray4 : .systemGreen
        action.image = UIImage(systemName: place.isVisited ? "checkmark.circle" : "checkmark.circle.fill")
        return action
    }
}
