//
//  PlaceDetailVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import UIKit

class PlaceDetailVC: UIViewController {
    // MARK: - IBOutlet

    @IBOutlet private var tblPlaceDetail: UITableView!

    // MARK: - Properties

    var place: TeaPlace?
    // var setFavPlaces = Set<String>()
    var onBackToHome: (() -> Void)?
    var onVisitToggle: ((String) -> Void)? // pass placeID

    // MARK: - Header Properties

    private var headerContainerView: UIView?
    private var headerView: PlaceDetailHeader?

    private let headerHeight: CGFloat = 300

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupTableHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeBackButtonText()
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        if isMovingFromParent {
            onBackToHome?()
        }
    }

    // MARK: - Helpers

    func setupTableView() {
        tblPlaceDetail.delegate = self
        tblPlaceDetail.dataSource = self
    }
}

// MARK: - Header Setup

private extension PlaceDetailVC {
    func setupTableHeader() {
        guard
            let place,
            let header = Bundle.main.loadNibNamed(
                "PlaceDetailHeader",
                owner: nil,
                options: nil
            )?.first as? PlaceDetailHeader
        else { return }

        // Configure header data

        header.configure(place: place)

        // header.setFavPlaces = FavouritePlacesStore.favourites
        // Button callback
        header.onButtonTap = { [weak self] buttonType in
            guard let self else { return }
            let placeID = place.id
            switch buttonType {
            case .favourite:
                if FavouritePlacesStore.favourites.contains(placeID) {
                    FavouritePlacesStore.favourites.remove(placeID)
                } else {
                    FavouritePlacesStore.favourites.insert(placeID)
                }

                let isFavourite = FavouritePlacesStore.favourites.contains(placeID)
                header.updateFavouriteButton(isFavourite: isFavourite)

            case .visit:
                // 🔥 Tell HOME to update the real model
                self.onVisitToggle?(placeID)

                // 🔄 Update local copy only for UI
                self.place?.toggleIsVisisted()

                header.updateVisitedButton(
                    isVisited: self.place?.isVisited ?? false
                )
            }
        }

        // Container view (required for stretch)
        let container = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tblPlaceDetail.bounds.width,
                height: headerHeight
            )
        )

        header.frame = container.bounds
        container.addSubview(header)

        tblPlaceDetail.tableHeaderView = container

        // Store references
        headerView = header
        headerContainerView = container
    }
}

// MARK: - Stretch Header Logic

private extension PlaceDetailVC {
    func stretchHeaderIfNeeded(_ scrollView: UIScrollView) {
        guard
            let container = headerContainerView,
            let header = headerView
        else { return }

        let offsetY = scrollView.contentOffset.y

        if offsetY < 0 {
            container.frame = CGRect(
                x: 0,
                y: offsetY,
                width: tblPlaceDetail.bounds.width,
                height: headerHeight - offsetY
            )

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
        25
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        // Replace with real cell later
        return UITableViewCell()
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        120
    }
}

/*
  guard
      let views = Bundle.main.loadNibNamed(
          "UserHeaderView",
          owner: nil,
          options: nil),
      let header = views.first as? UserHeaderView
  else {
      fatalError("UserHeaderView.xib not found or wrong class")
  }

 // FORCE Auto Layout to calculate size
 header.setNeedsLayout()
 header.layoutIfNeeded()

  // Calculate dynamic height
  let targetSize = CGSize(
  width: tblHome.bounds.width,
  height: UIView.layoutFittingCompressedSize.height
  )

  let dynamicHeight = header.systemLayoutSizeFitting(
  targetSize,
  withHorizontalFittingPriority: .required,
  verticalFittingPriority: .fittingSizeLevel
  ).height

  */
