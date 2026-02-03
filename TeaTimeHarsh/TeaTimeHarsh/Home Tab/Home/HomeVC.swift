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
    var arrTeaPlaces = [TeaPlace]()

    // COMPUTED PROPERTY: Handles Search + Segment Filters
    var displayedPlaces: [TeaPlace] {
        // 1. First, filter by Search Text (Name OR Location)
        var filtered = arrTeaPlaces

        if !currentSearchText.isEmpty {
            filtered = filtered.filter { place in
                let nameMatch = place.name.localizedCaseInsensitiveContains(currentSearchText)
                let locationMatch = (place.city ?? "").localizedCaseInsensitiveContains(currentSearchText)
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
            return filtered.filter { $0.createdByUserId == AppConstants.Strings.currentUserID }
        default: // All
            return filtered
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAllUI()
        setupObservers()
        fetchLatestDataApi()
        presentTipIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if AppNetworkManager.shared.isConnected {
            // Priority 1: Check for interrupted uploads first
            if let draft = UploadPersistenceManager.shared.getPendingUpload() {
                // If a draft is found, show the resume action sheet
                checkPendingUploads(draft: draft)
                return // 🛑 Stop here to avoid multiple alerts appearing at once
            }

            // Priority 2: Check if Profile is incomplete
            // This will only run if NO pending upload was found
            if UserDataManager.shared.user?.fullName == nil {
                askUserToUpdateProfile()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        // Refresh if returning from detail (Local update check)
        /*
         if !arrTeaPlaces.isEmpty {
             HapticHelper.success()
             tblTeaPlaces.reloadData()
         }*/
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

    // MARK: - Check Pending Uploads (Resume / Discard Logic) 🚀

    private func checkPendingUploads(draft: PendingUploadModel) {
        // Debug print to see what files are tracked for deletion
        print("🔍 Found Tracked Media URLs for potential cleanup:", UploadPersistenceManager.shared.getUploadedDraftMediaURLs())

        let actions = [
            // ---------------------------------------------------------
            // Action 1: Resume Upload 🚀
            // ---------------------------------------------------------
            SheetAction(title: "Resume Place Upload 🚀", style: .default) {
                // A. Initialize AddPlaceVC
                let storyboard = UIStoryboard(name: AppConstants.Storyboards.Main, bundle: nil)
                if let addVC = storyboard.instantiateViewController(withIdentifier: AppConstants.ViewControllers.AddPlaceVC) as? AddPlaceVC {
                    // B. Force Load UI (Important: outlets will be nil otherwise)
                    addVC.loadViewIfNeeded()
                    addVC.onPlaceAdded = { [weak self] _ in
                        guard let self = self else { return }
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            fetchLatestDataApi()
                        }
                    }

                    // C. Restore Data from Draft
                    addVC.restoreFromDraft(model: draft)

                    // D. Push to Screen
                    self.navigationController?.pushViewController(addVC, animated: true)
                }
            },

            // ---------------------------------------------------------
            // Action 2: Discard Draft 🗑️ (With Smart Safety Check)
            // ---------------------------------------------------------
            SheetAction(title: "Discard Draft ❌", style: .destructive) {
                // ⚠️ SAFETY CHECK FOR EDIT MODE
                // Since we use 'Overwrite Strategy', uploading a file in Edit mode replaces the live file immediately.
                // If user discards now, we MUST NOT delete the file, otherwise the Live Place will have a broken link.
                // We simply clear the local draft state.
                if draft.isEditMode {
                    print("🛡️ Edit Mode detected: Skipping server file deletion to prevent broken links.")
                    UploadPersistenceManager.shared.clearUploadState()
                    return
                }

                // --- ADD MODE DELETION LOGIC BELOW ---
                // For New Places, if we discard, the files are orphans. So we MUST delete them.

                // 1. Get ALL tracked links globally (Safety net)
                let linksToDelete = UploadPersistenceManager.shared.getUploadedDraftMediaURLs()

                // If no files were uploaded, just clear local state and exit
                if linksToDelete.isEmpty {
                    UploadPersistenceManager.shared.clearUploadState()
                    print("🧹 No remote files found. Local draft cleared.")
                    return
                }

                // 2. Start Async Cleanup Task
                Task {
                    print("🗑️ Discarding Draft (Add Mode): Found \(linksToDelete.count) orphan files to delete from Server.")

                    // Loop through and delete from Firebase Storage
                    for urlString in linksToDelete {
                        // Safety Check: Only delete if it looks like a Firebase URL
                        if urlString.contains("firebase") {
                            print("🔥 Deleting file from cloud: \(urlString)")
                            await FirebaseManager.shared.deleteStorageFile(at: urlString)
                        }
                    }

                    // 3. Update UI on Main Thread after cleanup
                    await MainActor.run {
                        HapticHelper.medium()

                        // ONLY after all Firebase files are deleted, clear local state.
                        UploadPersistenceManager.shared.clearUploadState()

                        print("✅ Draft Discarded & All Orphan Files Cleaned Successfully.")
                    }
                }
            },
        ]

        // 3. Show Action Sheet using your Helper
        AlertHelper.showActionSheet(
            on: self,
            title: "Incomplete Upload Found ⚠️",
            message: "Last time the upload for '\(draft.name)' was interrupted. Would you like to finish uploading it?",
            actions: actions
        )
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
        tblTeaPlaces
            .register(
                UINib(nibName: AppConstants.Cells.TeaListCell, bundle: nil),
                forCellReuseIdentifier: AppConstants.Cells.TeaListCell
            )
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
        // Update Selector to loadData
        refreshControl.addTarget(self, action: #selector(fetchLatestDataApi), for: .valueChanged)
        refreshControl.tintColor = .systemIndigo
        tblTeaPlaces.refreshControl = refreshControl
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFavNotification(_:)), name: .teaPlaceDidTapFav, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVisitNotification(_:)), name: .teaPlaceDidTapVisit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReload), name: .teaPlacesShouldReload, object: nil)
        // Connection Restored Observer
        NotificationCenter.default.addObserver(self, selector: #selector(handleConnectionRestored), name: .connectionRestored, object: nil)
    }

    // MARK: - Actions

    @IBAction func didChangeSegmentFilter(_ sender: UISegmentedControl) {
        tblTeaPlaces.reloadData()
        HapticHelper.light()
        if !displayedPlaces.isEmpty {
            tblTeaPlaces.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }

        setNeedsUpdateContentUnavailableConfiguration()
    }

    @objc func handleConnectionRestored() {
        print("🚀 Internet Restored! Auto-refreshing Home & User Data...")
        ToastManager.shared.show(message: "🚀 Internet Restored! Auto-refreshing Home and User Data...🥳")
        HapticHelper.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchLatestDataApi()
        }

        UserDataManager.shared.fetchUserProfileIfNeeded()
    }

    @objc private func didTapAddNavBar() {
        HapticHelper.light()

        guard AppNetworkManager.shared.isConnected else {
            showOfflineAlertAtHome()
            return
        }

        let addVC = storyboard?.instantiateViewController(withIdentifier: AppConstants.ViewControllers.AddPlaceVC) as! AddPlaceVC
        addVC.screenMode = .add
        addVC.onPlaceAdded = { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                fetchLatestDataApi()
            }
        }
        navigationController?.pushViewController(addVC, animated: true)
    }

    // MARK: - 🔥 API & Data Handling (The Brain)

    @objc private func fetchLatestDataApi() {
        // 1. UI Loading State
        HapticHelper.light()

        if !refreshControl.isRefreshing {
            isLoading = true
            LoaderManager.shared.startLoading()
        }

        // 2. Check Connection using your AppNetworkManager
        if AppNetworkManager.shared.isConnected {
            ToastManager.shared.show(message: "Fetching latest places from server...🥳")

            print("🌍 Internet Available for that fetching data from firebase")
            fetchFromFirebaseAndSync()
        } else {
            ToastManager.shared.show(message: "🔌 No Internet. \n Fetching places from Local Database")
            print("🔌 No Internet Available - for that fetching from CoreData")
            fetchFromCoreData()
        }
    }

    // Scenario A: Online
    private func fetchFromFirebaseAndSync() {
        Task {
            do {
                let places = try await FirebaseManager.shared.fetchAllPlaces()
                await MainActor.run {
                    self.arrTeaPlaces = places
                    self.tblTeaPlaces.reloadData()
                    setNeedsUpdateContentUnavailableConfiguration()
                }
                stopLoadingUI()
                // Sync in background
                CoreDataManager.shared.syncPlacesToLocalDB(places: places)
                HapticHelper.success()
            } catch {
                await MainActor.run {
                    // Fallback to local if API fails
                    stopLoadingUI()
                    HapticHelper.error()
                    print("⚠️ Firebase Error: \(error), trying local...")
                    AlertHelper
                        .showAlertHandler(
                            title: "❌ Error : Failed to get latest data",
                            message: "Could not connect to server. Showing offline data.",
                            vc: self) { _ in
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
        tblTeaPlaces.reloadData()
        stopLoadingUI()

        if localPlaces.isEmpty {
            // Only show alert if screen is totally empty
            print("🔴 Offline - No internet and no saved data found.")
            ToastManager.shared.show(message: "🔴 Offline \n No internet and no saved data found.")
            HapticHelper.error()
        } else {
            HapticHelper.success()
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
        let tipVC = storyboard?.instantiateViewController(
            withIdentifier: AppConstants
                .ViewControllers.HomeListingTipVC) as! HomeListingTipVC
        tipVC.modalPresentationStyle = .overFullScreen
        tipVC.modalTransitionStyle = .crossDissolve
        present(tipVC, animated: true)
    }

    // Helper for repetitive alerts
    private func showOfflineAlertAtHome() {
        HapticHelper.warning()
        AlertHelper.showAlert(title: "No Internet 🛜", message: "Please connect to the internet to perform this home screen action.", vc: self)
    }
}

// MARK: - Search Delegate (Optimized with Debouncing) 🔍

extension HomeVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // 1. Cancel the previous pending search request
        // This stops multiple reloads if the user is typing fast
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performDebouncedSearch), object: nil)

        // 2. Update the search text immediately
        currentSearchText = searchController.searchBar.text ?? ""

        // 3. Schedule the actual search/reload after 0.3 seconds delay
        perform(#selector(performDebouncedSearch), with: nil, afterDelay: 0.3)
    }

    @objc private func performDebouncedSearch() {
        // Finally reload the table once user stops typing
        print("🔍 Searching for: \(currentSearchText)")

        tblTeaPlaces.reloadData()
        HapticHelper.success()
        setNeedsUpdateContentUnavailableConfiguration()

        // Bonus: Success haptic if search yields results
        if !displayedPlaces.isEmpty && !currentSearchText.isEmpty {
            HapticHelper.light()
        }
    }
}

// MARK: - TableView Delegate & DataSource

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPlaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Double Safety check
        if indexPath.row >= displayedPlaces.count { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: AppConstants.Cells.TeaListCell, for: indexPath) as! TeaListCell
        cell.configure(teaPlace: displayedPlaces[indexPath.row])

        cell.onFavTapped = { [weak self] in
            if AppNetworkManager.shared.isConnected {
                self?.performSwipeToggle(at: indexPath, type: "fav")
            } else {
                self?.showOfflineAlertAtHome()
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(
            withIdentifier: AppConstants.ViewControllers.PlaceDetailVC) as! PlaceDetailVC
        detailVC.place = displayedPlaces[indexPath.row]
        // Reload when coming back to ensure data consistency
        detailVC.onBackToHome = { [weak self] in self?.fetchLatestDataApi() }
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
        DispatchQueue.main.async { self.fetchLatestDataApi() }
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

        // OPTIMIZATION: Instead of full reloadData, just reload the specific row if visible
        if let displayIndex = displayedPlaces.firstIndex(where: { $0.id == placeID }) {
            let indexPath = IndexPath(row: displayIndex, section: 0)
            tblTeaPlaces.reloadRows(at: [indexPath], with: .none)
        }
        HapticHelper.success()
        callApiToToggleStatus(place: arrTeaPlaces[index], type: type)
    }

    // MARK: - Centralized Swipe/Context/Notification Helper 🛠️

    private func performSwipeToggle(at indexPath: IndexPath, type: String) {
        // 1. Safety Check: Index Out of Range Guard 🛡️
        // Check if the indexPath is still valid for current displayedPlaces
        guard indexPath.row < displayedPlaces.count else {
            print("⚠️ Index out of range: Table state might have changed.")
            return
        }

        // 2. Internet Check 🛜
        guard AppNetworkManager.shared.isConnected else {
            showOfflineAlertAtHome()
            return
        }

        let selectedPlace = displayedPlaces[indexPath.row]

        // Find original index in master array safely
        guard let originalIndex = arrTeaPlaces.firstIndex(where: { $0.id == selectedPlace.id }) else { return }

        // 3. Toggle Local Data State 🔄
        if type == "fav" {
            arrTeaPlaces[originalIndex].isFav.toggle()
            HapticHelper.medium()
        } else if type == "visit" {
            arrTeaPlaces[originalIndex].isVisited.toggle()
            HapticHelper.medium()
        }

        // 4. Safe Animation Logic ✨
        // We use reloadRows to ensure the cell is properly reconfigured by the system,
        // which avoids 'Cell Reuse' glitches.
        tblTeaPlaces.setEditing(false, animated: true)

        HapticHelper.heavy()

        // Get the specific cell to apply a quick scale effect safely
        if let cell = tblTeaPlaces.cellForRow(at: indexPath) as? TeaListCell {
            // Update UI immediately for smooth feel
            cell.configure(teaPlace: arrTeaPlaces[originalIndex])

            // Subtle bounce animation
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    cell.transform = .identity
                }
            }
        }

        // 5. API Sync 🌐
        callApiToToggleStatus(place: arrTeaPlaces[originalIndex], type: type)
    }

    // MARK: - Update Action API (Optimistic UI with Safety) 🔄

    private func callApiToToggleStatus(place: TeaPlace, type: String) {
        Task {
            do {
                // Step 1: Fire Firebase API call
                try await FirebaseManager.shared.updateUserAction(
                    placeId: place.id,
                    isFav: place.isFav,
                    isVisited: place.isVisited
                )
                // Note: We don't need reloadData here because didSet handles it
                // and the local state was already updated before calling this function.

            } catch {
                // Step 2: Handle Failure & Revert State
                await MainActor.run { [weak self] in
                    guard let self = self else { return }

                    // ID based search is much safer than passing index directly
                    if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == place.id }) {
                        // Revert local data based on type
                        if type == "fav" {
                            self.arrTeaPlaces[index].isFav.toggle()
                        } else if type == "visit" {
                            self.arrTeaPlaces[index].isVisited.toggle()
                        }

                        // Show Dynamic Toast
                        ToastManager.shared.show(message: "⚠️ Connection error. Changes reverted.")

                        // Haptic feedback for error
                        HapticHelper.error()

                        print("❌ API Failed: State reverted for Place ID: \(place.id)")
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
        if !AppNetworkManager.shared.isConnected {
            showOfflineAlertAtHome()
            return UISwipeActionsConfiguration()
        }
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
        if !AppNetworkManager.shared.isConnected {
            showOfflineAlertAtHome()
            return UISwipeActionsConfiguration()
        }
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
            HapticHelper.error()
            // ✨ UPDATED: Use displayedPlaces
            let place = self.displayedPlaces[indexPath.row]

            self.actionManager.performDelete(place: place) {
                // Remove from MAIN array
                if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == place.id }) {
                    self.arrTeaPlaces.remove(at: index)
                }

                // OPTIMIZATION: Animate deletion instead of full reloadData
                self.tblTeaPlaces.deleteRows(at: [indexPath], with: .left)

                HapticHelper.success()
                completion(true)
            }
        }
    }

    private func makeShareAction(indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let self = self else { return }
            HapticHelper.light()
            let cell = self.tblTeaPlaces.cellForRow(at: indexPath)
            // ✨ UPDATED: Use displayedPlaces
            self.actionManager.performShare(place: self.displayedPlaces[indexPath.row], sourceView: cell ?? self.view)
            completion(true)
        }
    }

    private func makeEditAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { return }
            HapticHelper.medium()
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
