//
//  HomeVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import UIKit

class HomeVC: UIViewController {
    // MARK: - Outlets

    @IBOutlet var tblTeaPlaces: UITableView!
    @IBOutlet var segmentFilter: UISegmentedControl!

    // MARK: - Properties

    lazy var actionManager = TeaActionManager(viewController: self)
    private let refreshControl = UIRefreshControl()

    // Search Controller
    private let searchController = UISearchController(searchResultsController: nil)
    private var currentSearchText: String = ""

    // Loading State
    var isLoading = true {
        didSet { setNeedsUpdateContentUnavailableConfiguration() }
    }

    // Master Data Source
    var arrTeaPlaces = [TeaPlace]() {
        didSet {
            setNeedsUpdateContentUnavailableConfiguration()
            tblTeaPlaces.reloadData()
        }
    }

    // 🔥 COMPUTED PROPERTY: Handles Search + Segment Filters
    var displayedPlaces: [TeaPlace] {
        // 1. First, filter by Search Text (Name OR Location)
        var filtered = arrTeaPlaces

        if !currentSearchText.isEmpty {
            filtered = filtered.filter { place in
                let nameMatch = place.name.localizedCaseInsensitiveContains(currentSearchText)
                let locationMatch = (place.location ?? "").localizedCaseInsensitiveContains(currentSearchText)
                return nameMatch || locationMatch
            }
        }

        // 2. Then, filter by Segment
        switch segmentFilter.selectedSegmentIndex {
        case 1: // Favourites
            return filtered.filter { $0.isFav }
        case 2: // Visited
            return filtered.filter { $0.isVisited }
        case 3: // Mine
            return filtered.filter { $0.createdByUserId == Constants.Strings.currentUserID }
        default: // All
            return filtered
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAllUI()
        setupObservers()
        loadData()
        presentTipIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        // Refresh if returning from detail (Local update check)
        if !arrTeaPlaces.isEmpty { tblTeaPlaces.reloadData() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - Setup UI

    private func setupAllUI() {
        setupTableView()
        setupNavBar()
        setupSearchController()
        configureSegmentController()
        setupRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDataManager.shared.user?.fullName == nil {
            askUserToUpdateProfile()
        }
    }

    func askUserToUpdateProfile() {
        let alert = UIAlertController(
            title: "👋 Hey Buddy!",
            message: "Your profile looks incomplete.\n✨ Update it now so friends can recognise you easily! 😊 ",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "✏️ Update Profile", style: .default) { [weak self] _ in
            self?.tabBarController?.selectedIndex = 1
        })
        alert.addAction(UIAlertAction(title: "❌ Cancel", style: .destructive))

        present(alert, animated: true)
    }

    private func setupTableView() {
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        tblTeaPlaces.delegate = self
        tblTeaPlaces.dataSource = self
        tblTeaPlaces.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        tblTeaPlaces.tableFooterView = UIView()
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by Name or Location"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupNavBar() {
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(didTapAddNavBar))
        navigationItem.rightBarButtonItem = addButton
        setCustomNavigationBarStyle()
    }

    private func configureSegmentController() {
        segmentFilter.setTitleTextAttributes([.foregroundColor: UIColor.systemBackground], for: .selected)
        segmentFilter.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
    }

    private func setupRefreshControl() {
        // 🔥 Update Selector to loadData
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        refreshControl.tintColor = .systemIndigo
        tblTeaPlaces.refreshControl = refreshControl
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFavNotification(_:)), name: .teaPlaceDidTapFav, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVisitNotification(_:)), name: .teaPlaceDidTapVisit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReload), name: .teaPlacesShouldReload, object: nil)
        // 🔥 Connection Restored Observer
        NotificationCenter.default.addObserver(self, selector: #selector(handleConnectionRestored), name: .connectionRestored, object: nil)
    }

    // MARK: - Actions

    @IBAction func didChangeSegmentFilter(_ sender: UISegmentedControl) {
        tblTeaPlaces.reloadData()
        if !displayedPlaces.isEmpty {
            tblTeaPlaces.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }

        setNeedsUpdateContentUnavailableConfiguration()
    }

    @objc func handleConnectionRestored() {
        print("🚀 Internet Restored! Auto-refreshing Home & User Data...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadData()
        }

        UserDataManager.shared.fetchUserProfileIfNeeded()
    }

    @objc private func didTapAddNavBar() {
        guard AppNetworkManager.shared.isConnected else {
            showOfflineAlertAtHome()
            return
        }

        HapticHelper.success()
        let addVC = storyboard?.instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC
        addVC.screenMode = .add
        addVC.onPlaceAdded = { [weak self] _ in self?.loadData() }
        navigationController?.pushViewController(addVC, animated: true)
    }

    // MARK: - 🔥 API & Data Handling (The Brain)

    @objc private func loadData() {
        // 1. UI Loading State
        if !refreshControl.isRefreshing {
            isLoading = true
            LoaderManager.shared.startLoading()
        }

        // 2. Check Connection using your AppNetworkManager
        if AppNetworkManager.shared.isConnected {
            print("🌍 Internet Available for that fetching data from firebase")
            fetchFromFirebaseAndSync()
        } else {
            print("🔌 No Internet Available - for that fetching from CoreData")
            fetchFromCoreData()
        }
    }

    // Scenario A: Online
    private func fetchFromFirebaseAndSync() {
        Task {
            do {
                let places = try await FirebaseManager.shared.fetchAllPlaces()
                await MainActor.run { self.arrTeaPlaces = places }
                stopLoadingUI()
                // Sync in background
                CoreDataManager.shared.syncPlacesToLocalDB(places: places)

            } catch {
                await MainActor.run {
                    // Fallback to local if API fails
                    stopLoadingUI()
                    HapticHelper.error()
                    print("⚠️ Firebase Error: \(error), trying local...")
                    Utility
                        .showAlertHandler(
                            title: "❌ Error : Failed to get latest data",
                            message: "Could not connect to server. Showing offline data.",
                            viewController: self) { okAction in
                                self.fetchFromCoreData()
                            }
                    
                }
            }
        }
    }

    // Scenario B: Offline
    private func fetchFromCoreData() {
        let localPlaces = CoreDataManager.shared.fetchLocalPlaces()
        arrTeaPlaces = localPlaces
        stopLoadingUI()

        if localPlaces.isEmpty {
            // Only show alert if screen is totally empty
            print("🔴 Offline - No internet and no saved data found.")
        }
    }

    private func stopLoadingUI() {
        Task { @MainActor in
            self.isLoading = false
            LoaderManager.shared.stopLoading()
            self.refreshControl.endRefreshing()
        }
    }

    private func presentTipIfNeeded() {
        guard HomeListingTipManager.shouldShowTip() else { return }
        let tipVC = storyboard?.instantiateViewController(withIdentifier: "HomeListingTipVC") as! HomeListingTipVC
        tipVC.modalPresentationStyle = .overFullScreen
        tipVC.modalTransitionStyle = .crossDissolve
        present(tipVC, animated: true)
    }

    // Helper for repetitive alerts
    private func showOfflineAlertAtHome() {
        Utility.showAlert(title: "No Internet", message: "Please connect to the internet to perform this action.", viewController: self)
    }
}

// MARK: - Search Delegate

extension HomeVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        currentSearchText = searchController.searchBar.text ?? ""
        tblTeaPlaces.reloadData()
        setNeedsUpdateContentUnavailableConfiguration()
    }
}

// MARK: - TableView Delegate & DataSource

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPlaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeaListCell", for: indexPath) as! TeaListCell
        cell.configure(teaPlace: displayedPlaces[indexPath.row])

        cell.onFavTapped = { [weak self] in
            self?.performSwipeToggle(at: indexPath, type: "fav")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "PlaceDetailVC") as! PlaceDetailVC
        detailVC.place = displayedPlaces[indexPath.row]
        // Reload when coming back to ensure data consistency
        detailVC.onBackToHome = { [weak self] in self?.loadData() }
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Notifications & Toggle Logic

extension HomeVC {
    @objc func handleFavNotification(_ notification: Notification) {
        updateLocalState(from: notification, type: "fav")
    }

    @objc func handleVisitNotification(_ notification: Notification) {
        updateLocalState(from: notification, type: "visit")
    }

    @objc func handleReload() {
        DispatchQueue.main.async { self.loadData() }
    }

    private func updateLocalState(from notification: Notification, type: String) {
        // 🔥 GUARD: Internet Check
        guard AppNetworkManager.shared.isConnected else {
            // Notification might come from detail, so we don't necessarily show alert here, but logic stops
            return
        }

        guard let placeID = notification.userInfo?["placeID"] as? String,
              let status = notification.userInfo?[type == "fav" ? "isFav" : "isVisited"] as? Bool,
              let index = arrTeaPlaces.firstIndex(where: { $0.id == placeID }) else { return }

        if type == "fav" { arrTeaPlaces[index].isFav = status }
        else { arrTeaPlaces[index].isVisited = status }

        tblTeaPlaces.reloadData()
        callApiToToggleStatus(place: arrTeaPlaces[index], type: type)
    }

    // Centralized Swipe/Context/Notification Helper
    private func performSwipeToggle(at indexPath: IndexPath, type: String) {
        // 🔥 GUARD: Internet Check
        guard AppNetworkManager.shared.isConnected else {
            showOfflineAlertAtHome()
            return
        }

        let selectedPlace = displayedPlaces[indexPath.row]
        guard let originalIndex = arrTeaPlaces.firstIndex(where: { $0.id == selectedPlace.id }) else { return }

        // 1. Toggle Local
        if type == "fav" { arrTeaPlaces[originalIndex].isFav.toggle() }
        if type == "visit" { arrTeaPlaces[originalIndex].isVisited.toggle() }

        // 2. Animation
        if let cell = tblTeaPlaces.cellForRow(at: indexPath) as? TeaListCell {
            cell.configure(teaPlace: displayedPlaces[indexPath.row])
            UIView.animate(withDuration: 0.1, animations: { cell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1) }) { _ in
                UIView.animate(withDuration: 0.3) { cell.transform = .identity }
            }
        }

        // 3. API
        callApiToToggleStatus(place: arrTeaPlaces[originalIndex], type: type)
    }

    private func callApiToToggleStatus(place: TeaPlace, type: String) {
        Task {
            do {
                try await FirebaseManager.shared.updateUserAction(placeId: place.id, isFav: place.isFav, isVisited: place.isVisited)
            } catch {
                await MainActor.run {
                    // Revert Logic on Failure
                    if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == place.id }) {
                        if type == "fav" { self.arrTeaPlaces[index].isFav.toggle() }
                        if type == "visit" { self.arrTeaPlaces[index].isVisited.toggle() }
                        self.tblTeaPlaces.reloadData()
                        Utility.showAlert(title: "Connection Error", message: "Changes reverted.", viewController: self)
                    }
                }
            }
        }
    }
}

// MARK: - Swipe Actions & Context Menu

extension HomeVC {
    // 1. Trailing Swipe (Right -> Left): Delete, Share, Edit
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = makeDeleteAction(indexPath: indexPath)
        let share = makeShareAction(indexPath: indexPath)
        let edit = makeEditAction(indexPath: indexPath)

        var config = UISwipeActionsConfiguration(actions: [share])
        // Check Owner Permissions (✨ UPDATED: Use displayedPlaces)
        let isOwner = TeaActionManager.canModify(place: displayedPlaces[indexPath.row])

        config = isOwner ? UISwipeActionsConfiguration(actions: [delete, share, edit]) : UISwipeActionsConfiguration(actions: [share])

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

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let place = displayedPlaces[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let call = UIAction(title: "Call", image: UIImage(systemName: "phone")) { _ in
                if let url = URL(string: "tel://\(place.phone ?? "")"), UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
            }
            return UIMenu(children: [call])
        }
    }
}

// MARK: - Empty State (iOS 17+)

extension HomeVC {
    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        if isLoading {
            contentUnavailableConfiguration = nil
            return
        }

        guard displayedPlaces.isEmpty else {
            contentUnavailableConfiguration = nil
            return
        }

        var config = UIContentUnavailableConfiguration.empty()
        config.image = UIImage(systemName: "cup.and.heat.waves.fill")
        config.imageProperties.tintColor = .systemIndigo

        if !currentSearchText.isEmpty {
            config.text = "No Matches Found"
            config.secondaryText = "Try searching for a different name or location."
        } else {
            // Customize based on filter (same as before)
            switch segmentFilter.selectedSegmentIndex {
            case 1: config.text = "No favourite spots? Playing hard to get? 😉"; config.secondaryText = "Don't be shy! Swipe right on any tea place to mark it as your favourite place.❤️"
            case 2: config.text = "Zero Visits? Are you on a diet? 😜"; config.secondaryText = "Go have a cup! Then swipe right on the list to mark it as visited place.✈️"
            case 3: config.text = "No places added by you 🧑‍💻"
                config.secondaryText = "You haven't uploaded any tea spots yet. Tap the + button to add one!🏦"
            default: config.text = "It’s Tea-rribly Empty Here! 😱"; config.secondaryText = "No tea spots found yet. Be the first to spill the tea and add your favourite place! 🥳"
            }
        }

        // Button Logic
        var btnConfig = UIButton.Configuration.filled()
        btnConfig.cornerStyle = .capsule
        btnConfig.baseBackgroundColor = .systemIndigo

        if segmentFilter.selectedSegmentIndex == 0 && currentSearchText.isEmpty {
            btnConfig.title = "Add First Place"
            btnConfig.image = UIImage(systemName: "plus")
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in self?.didTapAddNavBar() }
        } else {
            btnConfig.title = "Clear Filters"
            btnConfig.image = UIImage(systemName: "xmark.circle")
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                self?.segmentFilter.selectedSegmentIndex = 0
                self?.searchController.searchBar.text = ""
                self?.searchController.isActive = false
                self?.currentSearchText = ""
                self?.didChangeSegmentFilter(self!.segmentFilter)
            }
        }
        config.button = btnConfig
        contentUnavailableConfiguration = config
    }
}

// MARK: - Contextual Action Creators

extension HomeVC {
    private func makeDeleteAction(indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            // ✨ UPDATED: Use displayedPlaces
            let place = self.displayedPlaces[indexPath.row]

            self.actionManager.performDelete(place: place) {
                // Remove from MAIN array
                if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == place.id }) {
                    self.arrTeaPlaces.remove(at: index)
                }
                // Reload to update filtered view
                self.tblTeaPlaces.reloadData()
                completion(true)
            }
        }
    }

    private func makeShareAction(indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let self = self else { return }
            let cell = self.tblTeaPlaces.cellForRow(at: indexPath)
            // ✨ UPDATED: Use displayedPlaces
            self.actionManager.performShare(place: self.displayedPlaces[indexPath.row], sourceView: cell ?? self.view)
            completion(true)
        }
    }

    private func makeEditAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { return }
            // ✨ UPDATED: Use displayedPlaces
            let place = self.displayedPlaces[indexPath.row]
            self.actionManager.performEdit(place: place) {
                self.fetchFromFirebaseAndSync()
            }

            completion(true)
        }
        action.backgroundColor = .systemOrange
        action.image = UIImage(systemName: "pencil")
        return action
    }

    private func makeFavAction(indexPath: IndexPath) -> UIContextualAction {
        // ✨ UPDATED: Use displayedPlaces
        let place = displayedPlaces[indexPath.row]
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
        // ✨ UPDATED: Use displayedPlaces
        let place = displayedPlaces[indexPath.row]
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
