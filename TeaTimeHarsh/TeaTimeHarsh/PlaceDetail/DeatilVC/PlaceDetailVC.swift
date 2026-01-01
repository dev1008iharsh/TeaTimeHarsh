//
//  PlaceDetailVC.swift
//  TeaTimeHarsh


import UIKit

class PlaceDetailVC: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private var tblPlaceDetail: UITableView!

    // MARK: - Properties
    var place: TeaPlace?
    
    // Closures for Communication
    var onBackToHome: (() -> Void)?
    var onVisitToggle: ((String) -> Void)? // Pass PlaceID
    var onFavToggle: ((String) -> Void)?   // Pass PlaceID

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
        
        if isMovingFromParent {
            onBackToHome?()
        }
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

// MARK: - Header Setup & Logic 🖼️

private extension PlaceDetailVC {
    
    func setupTableHeader() {
        guard let place = place,
              let header = Bundle.main.loadNibNamed("DetailHeader", owner: nil)?.first as? DetailHeader
        else { return }

        // Configure with initial data
        header.configure(place: place)

        // Handle Header Button Taps (Fav / Visit)
        header.onButtonTap = { [weak self] buttonType in
            guard let self = self else { return }
            let placeID = place.id

            switch buttonType {
            case .favourite:
                // 1. Toggle Local State
                self.place?.isFav.toggle()
                let isNowFav = self.place?.isFav ?? false
                
                // 2. Update Header UI
                header.updateFavouriteButton(isFavourite: isNowFav)
                HapticHelper.heavy()
                
                // 3. Notify Home Screen (to update server & list)
                self.onFavToggle?(placeID)
                
            case .visit:
                // 1. Toggle Local State
                self.place?.isVisited.toggle()
                let isNowVisited = self.place?.isVisited ?? false
                
                // 2. Update Header UI
                header.updateVisitedButton(isVisited: isNowVisited)
                HapticHelper.heavy()
                
                // 3. Notify Home Screen (to update server & list)
                self.onVisitToggle?(placeID)
            }
        }

        // Setup Container for Stretchy Effect
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tblPlaceDetail.bounds.width, height: headerHeight))
        header.frame = container.bounds
        container.addSubview(header)
        
        tblPlaceDetail.tableHeaderView = container
        
        // Keep references
        self.headerView = header
        self.headerContainerView = container
    }
    
    // Logic for Stretchy Header Effect
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
        
        // Pass the updated place object (so if state changes, it might reflect if needed)
        if let place = place {
            cell.teaPlace = place
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300 // Providing a better estimate improves scroll performance
    }
}
