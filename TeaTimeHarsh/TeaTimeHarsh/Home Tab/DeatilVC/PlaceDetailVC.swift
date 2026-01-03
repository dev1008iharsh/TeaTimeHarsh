//
//  PlaceDetailVC.swift
//  TeaTimeHarsh
//

import UIKit

class PlaceDetailVC: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private var tblPlaceDetail: UITableView!

    // MARK: - Properties
    var place: TeaPlace?
    lazy var actionManager = TeaActionManager(viewController: self)

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
}

// MARK: - Header Setup 🖼️
private extension PlaceDetailVC {
    func setupTableHeader() {
        guard let place = place,
              let header = Bundle.main.loadNibNamed("DetailHeader", owner: nil)?.first as? DetailHeader
        else { return }

        // Configure with data (Header now handles its own NotificationsCenter post Notification)
        header.configure(place: place)
        
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
        if let place = place {
            cell.teaPlace = place

            // 👇  CRUD (Edit/Delete) using Closures 👇

            // 1. Share
            cell.onShareTapped = { [weak self] in
                self?.actionManager.performShare(place: place, sourceView: cell.btnShare)
            }

            // 2. Delete
            cell.onDeleteTapped = { [weak self] in
                guard let self = self else { return }
                self.actionManager.performDelete(place: place) {
                    self.onBackToHome?()
                    // popToRootViewController done in actionManager Method
                }
            }

            // 3. Edit
            cell.onEditTapped = { [weak self] in
                guard let self = self else { return }
                self.actionManager.performEdit(place: place) {
                    self.onBackToHome?() // Ask Home to refresh
                    // popToRootViewController done in actionManager Method
                }
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 500
    }
}
