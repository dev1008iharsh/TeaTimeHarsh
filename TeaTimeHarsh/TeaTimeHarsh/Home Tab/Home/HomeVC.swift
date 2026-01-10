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
                // Logic: Name check karo OR Location check karo (Safe Unwrap sathe)
                let nameMatch = place.name.localizedCaseInsensitiveContains(currentSearchText)
                
                // 🔥 FIX: (place.location ?? "")
                // Aano arth: Jo location nil che, to "" (empty) ma search kar, je false aavse. Crash nai thay.
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
        fetchDataFromFirebase()
        presentTipIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        // Refresh if returning from detail
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
        setupSearchController() // New Search Setup
        configureSegmentController()
        setupRefreshControl()
    }
    
    private func setupTableView() {
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        tblTeaPlaces.delegate = self
        tblTeaPlaces.dataSource = self
        // Adjust insets for aesthetic spacing
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
        setLargeTitleSpacingNavBar(20)
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
    }
    
    private func configureSegmentController() {
        segmentFilter.setTitleTextAttributes([.foregroundColor: UIColor.systemBackground], for: .selected)
        segmentFilter.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(fetchDataFromFirebase), for: .valueChanged)
        refreshControl.tintColor = .systemIndigo
        tblTeaPlaces.refreshControl = refreshControl
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFavNotification(_:)), name: .teaPlaceDidTapFav, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVisitNotification(_:)), name: .teaPlaceDidTapVisit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReload), name: .teaPlacesShouldReload, object: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func didChangeSegmentFilter(_ sender: UISegmentedControl) {
        tblTeaPlaces.reloadData()
        // Scroll to top if items exist
        if !displayedPlaces.isEmpty {
            tblTeaPlaces.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        setNeedsUpdateContentUnavailableConfiguration()
    }
    
    @objc private func didTapAddNavBar() {
        HapticHelper.success()
        let addVC = storyboard?.instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC
        addVC.screenMode = .add
        addVC.onPlaceAdded = { [weak self] _ in self?.fetchDataFromFirebase() }
        navigationController?.pushViewController(addVC, animated: true)
    }

    // MARK: - API & Data Handling
    
    @objc private func fetchDataFromFirebase() {
        if !refreshControl.isRefreshing {
            isLoading = true
            LoaderManager.shared.startLoading()
        }

        Task {
            defer {
                Task { @MainActor in
                    self.isLoading = false
                    LoaderManager.shared.stopLoading()
                    self.refreshControl.endRefreshing()
                }
            }
            do {
                let places = try await FirebaseManager.shared.fetchAllPlaces()
                await MainActor.run { self.arrTeaPlaces = places }
            } catch {
                await MainActor.run {
                    Utility.showAlert(title: "Error", message: error.localizedDescription, viewController: self)
                }
            }
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

// MARK: - Search Delegate
extension HomeVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Update variable and reload table
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
        detailVC.onBackToHome = { [weak self] in self?.fetchDataFromFirebase() }
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
        DispatchQueue.main.async { self.fetchDataFromFirebase() }
    }
    
    private func updateLocalState(from notification: Notification, type: String) {
        guard let placeID = notification.userInfo?["placeID"] as? String,
              let status = notification.userInfo?[type == "fav" ? "isFav" : "isVisited"] as? Bool,
              let index = arrTeaPlaces.firstIndex(where: { $0.id == placeID }) else { return }

        // Update Master Array
        if type == "fav" { arrTeaPlaces[index].isFav = status }
        else { arrTeaPlaces[index].isVisited = status }
        
        tblTeaPlaces.reloadData()
        callApiToToggleStatus(place: arrTeaPlaces[index], type: type)
    }
    
    // Centralized Swipe/Context/Notification Helper
    private func performSwipeToggle(at indexPath: IndexPath, type: String) {
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = displayedPlaces[indexPath.row]
        let share = makeAction(title: "Share", color: .systemBlue, icon: "square.and.arrow.up") { self.actionManager.performShare(place: place, sourceView: $0) }
        
        guard TeaActionManager.canModify(place: place) else { return UISwipeActionsConfiguration(actions: [share]) }
        
        let delete = makeAction(title: "Delete", color: .systemRed, icon: "trash") { cell in
            self.actionManager.performDelete(place: place) {
                if let idx = self.arrTeaPlaces.firstIndex(where: { $0.id == place.id }) {
                    self.arrTeaPlaces.remove(at: idx)
                    self.tblTeaPlaces.reloadData() // Simple reload is safer with filters
                }
            }
        }
        
        let edit = makeAction(title: "Edit", color: .systemOrange, icon: "pencil") { _ in
            self.actionManager.performEdit(place: place) { self.fetchDataFromFirebase() }
        }
        
        return UISwipeActionsConfiguration(actions: [delete, share, edit])
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = displayedPlaces[indexPath.row]
        
        let visit = makeAction(title: place.isVisited ? "Unvisit" : "Visit", color: place.isVisited ? .systemGray4 : .systemGreen, icon: "checkmark.circle") { _ in
            self.performSwipeToggle(at: indexPath, type: "visit")
        }
        
        let fav = makeAction(title: place.isFav ? "Unfav" : "Fav", color: place.isFav ? .systemGray : .systemPink, icon: "heart.fill") { _ in
            self.performSwipeToggle(at: indexPath, type: "fav")
        }
        
        return UISwipeActionsConfiguration(actions: [visit, fav])
    }
    
    // Helper to create swipe actions cleanly
    private func makeAction(title: String, color: UIColor, icon: String, handler: @escaping (UIView) -> Void) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: title) { [weak self] _, view, completion in
            handler(self?.tblTeaPlaces.cellForRow(at: self?.tblTeaPlaces.indexPath(for: view as! UITableViewCell) ?? IndexPath()) ?? view)
            completion(true)
        }
        action.backgroundColor = color
        action.image = UIImage(systemName: icon)
        return action
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
        
        // Show empty state only if filter/search yields no results
        guard displayedPlaces.isEmpty else {
            contentUnavailableConfiguration = nil
            return
        }

        var config = UIContentUnavailableConfiguration.empty()
        config.image = UIImage(systemName: "cup.and.heat.waves.fill")
        config.imageProperties.tintColor = .systemIndigo
        
        // Customized Text based on Context
        if !currentSearchText.isEmpty {
            config.text = "No Matches Found"
            config.secondaryText = "Try searching for a different name or location."
        } else {
            switch segmentFilter.selectedSegmentIndex {
            case 1: config.text = "No Favourites Yet"; config.secondaryText = "Swipe right to heart a place!"
            case 2: config.text = "No Visits Yet"; config.secondaryText = "Go drink some tea!"
            case 3: config.text = "No Uploads"; config.secondaryText = "Add your own discoveries."
            default: config.text = "It’s Tea-rribly Empty"; config.secondaryText = "Add the first tea spot!"
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
                self?.searchController.isActive = false // Close search
                self?.currentSearchText = ""
                self?.didChangeSegmentFilter(self!.segmentFilter)
            }
        }
        config.button = btnConfig
        contentUnavailableConfiguration = config
    }
}
