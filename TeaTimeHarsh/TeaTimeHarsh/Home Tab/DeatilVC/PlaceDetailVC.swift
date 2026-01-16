//
//  PlaceDetailVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import UIKit

class PlaceDetailVC: UIViewController {
    // MARK: - IBOutlet

    @IBOutlet private var tblPlaceDetail: UITableView!

    // MARK: - Properties

    var place: TeaPlace?
    var placeOwnerUser: User?
    lazy var actionManager = TeaActionManager(viewController: self)
    var arrReviews: [PlaceReview]?

    // 🔒 Closures for EDIT / DELETE (As requested)
    var onBackToHome: (() -> Void)?

    // Header Properties
    private var headerContainerView: UIView?
    private var headerView: DetailHeader?
    private let headerHeight: CGFloat = 300

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupTableHeader()
        fetchPlaceOwnerPersonalDetails()
        fetchPlaceReviews()
    }

    deinit {
        print("💀 deinit PlaceDetailVC is dead. Memory Free!")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeBackButtonTextNavBar()
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Setup Helpers

    private func setupTableView() {
        tblPlaceDetail.delegate = self
        tblPlaceDetail.dataSource = self
        tblPlaceDetail.tableFooterView = UIView()
        tblPlaceDetail.register(
            UINib(nibName: "DetailStaticCell", bundle: nil),
            forCellReuseIdentifier: "DetailStaticCell"
        )
    }

    private func fetchPlaceOwnerPersonalDetails() {
        guard let idPlaceOwner = place?.createdByUserId else { return }

        Task {
            LoaderManager.shared.startLoading()
            do {
                LoaderManager.shared.stopLoading()
                self.placeOwnerUser = try await FirebaseManager.shared.fetchUserPersonalDetails(userID: idPlaceOwner)
                print("setupFetchPlaceOwnerPersonalDetails", placeOwnerUser as Any)
                self.tblPlaceDetail.reloadData()

            } catch {
                LoaderManager.shared.stopLoading()
                print("Error fetching user: \(error.localizedDescription)")
            }
        }
    }

    private func fetchPlaceReviews() {
        guard let placeId = place?.id else { return }
        Task {
            LoaderManager.shared.startLoading()
            do {
                LoaderManager.shared.stopLoading()
                let fetchedReviews = try await FirebaseManager.shared.fetchPlaceReviews(for: placeId)
                self.arrReviews = fetchedReviews
                print("✅ Got \(fetchedReviews.count) reviews!")
            } catch {
                LoaderManager.shared.stopLoading()
                print("❌ Failed to fetch reviews: \(error.localizedDescription)")
                Utility
                    .showAlert(title: "Failed to fetch reviews", message: error.localizedDescription, viewController: self)
            }
        }
    }
}

// MARK: - Header Setup 🖼️

private extension PlaceDetailVC {
    func setupTableHeader() {
        guard let place = place,
              let header = Bundle.main.loadNibNamed("DetailHeader", owner: nil)?.first as? DetailHeader
        else { return }

        // Configure with data (Header now handles its own NotificationsCenter post Notification)
        header.configure(place: place)

        header.onReviewTapped = { [weak self] in
            guard let self = self else { return }
            guard AppNetworkManager.shared.isConnected else {
                showOfflineAlertAtDetail()
                return
            }
            presentBottomSheetPlaceReviews()
        }

        // Setup Container for Stretchy Effect
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tblPlaceDetail.bounds.width, height: headerHeight))
        header.frame = container.bounds
        container.addSubview(header)

        tblPlaceDetail.tableHeaderView = container

        // Keep references
        headerView = header
        headerContainerView = container
    }

    func stretchHeaderIfNeeded(_ scrollView: UIScrollView) {
        guard let container = headerContainerView, let header = headerView else { return }
        let offsetY = scrollView.contentOffset.y

        if offsetY < 0 {
            container.frame = CGRect(x: 0, y: offsetY, width: tblPlaceDetail.bounds.width, height: headerHeight - offsetY)
            header.frame = container.bounds
        }
    }

    private func presentBottomSheetPlaceReviews() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let reviewVC = storyboard.instantiateViewController(withIdentifier: "PlaceReviewVC") as? PlaceReviewVC else { return }
        reviewVC.place = place
        reviewVC.arrReviews = arrReviews
        reviewVC.reloadRating = { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(name: .teaPlacesShouldReload, object: nil)
            self.navigationController?.popViewController(animated: true)
        }
        if let sheet = reviewVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(reviewVC, animated: true)
    }
}

// MARK: - UITableView Delegate & DataSource

extension PlaceDetailVC: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        stretchHeaderIfNeeded(scrollView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailStaticCell", for: indexPath) as! DetailStaticCell
        if let owner = placeOwnerUser {
            cell.placeOwnerUser = owner
        }
        if let place = place {
            cell.teaPlace = place

            // 👇  CRUD (Edit/Delete) using Closures 👇

            // 1. Share
            cell.onShareTapped = { [weak self] in
                guard let self = self else { return }
                guard AppNetworkManager.shared.isConnected else {
                    Utility.showAlert(title: "No Internet 🛜", message: "Please connect to the internet to perform this action because image is downloading from internet to share this place.", viewController: self)
                    return
                }
                self.actionManager.performShare(place: place, sourceView: cell.btnShare)
            }

            // 2. Delete
            cell.onDeleteTapped = { [weak self] in
                guard let self = self else { return }
                guard AppNetworkManager.shared.isConnected else {
                    showOfflineAlertAtDetail()
                    return
                }
                self.actionManager.performDelete(place: place) {
                    self.onBackToHome?()
                    // popToRootViewController done in actionManager Method
                }
            }

            // 3. Edit
            cell.onEditTapped = { [weak self] in
                guard let self = self else { return }
                guard AppNetworkManager.shared.isConnected else {
                    showOfflineAlertAtDetail()
                    return
                }
                self.actionManager.performEdit(place: place) {
                    self.onBackToHome?() // Ask Home to refresh
                    // popToRootViewController done in actionManager Method
                }
            }

            // 4. Show place owner popup
            cell.onPlaceOwnerTapped = { [weak self] in
                guard let self = self else { return }
                guard AppNetworkManager.shared.isConnected else {
                    showOfflineAlertAtDetail()
                    return
                }
                presentBottomSheetOwnerDetails()
            }
        }
        return cell
    }

    func presentBottomSheetOwnerDetails() {
        guard let placeOwnerUser else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let ownerVC = storyboard.instantiateViewController(withIdentifier: "PlaceOwnerDetailsVC") as? PlaceOwnerDetailsVC else {
            return
        }
        ownerVC.placeOwnerUser = placeOwnerUser
        if let sheet = ownerVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        present(ownerVC, animated: true)
    }

    private func showOfflineAlertAtDetail() {
        Utility.showAlert(title: "No Internet 🛜", message: "Please connect to the internet to perform this place details screen action.", viewController: self)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 500
    }
}
