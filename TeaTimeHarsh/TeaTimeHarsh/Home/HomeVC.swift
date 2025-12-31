//
//  HomeVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import UIKit

class HomeVC: UIViewController {
    @IBOutlet var tblTeaPlaces: UITableView!

    var arrTeaPlaces = [TeaPlace]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        createDummyModel()
        presentTipIfNeeded()
        configureNavBar()

        // detectLongPressOnCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }


    private func configureNavBar() {
        addPlaceNavBar()

        hideBackButtonNavBar(hidden: true, swipeEnabled: true)
        setLargeTitleSpacingNavBar(20)
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
        // setCustomBackButton(image: UIImage(named: "backButtonIcon") ?? UIImage(), text: "Back", color: .systemIndigo)
    }

    private func addPlaceNavBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(didTapAddNavBar)
        )
        navigationItem.rightBarButtonItem = addButton
    }

    @objc private func didTapAddNavBar() {
        print("Plus button tapped")
        HapticHelper.success()
        let addPlaceVC = navigationController?.storyboard?
            .instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC

        addPlaceVC.onPlaceAdded = { [weak self] newPlace in
            self?.arrTeaPlaces.insert(newPlace, at: 0)
            self?.tblTeaPlaces.reloadData()
            HapticHelper.heavy()
        }
        navigationController?.pushViewController(addPlaceVC, animated: true)
        
        /*
        // 🔴 Embed in Navigation Controller to show navBar
        let navVC = UINavigationController(rootViewController: vc)

        present(navVC, animated: true)*/
    }

    private func presentTipIfNeeded() {
        guard HomeListingTipManager.shouldShowTip() else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tipVC = storyboard.instantiateViewController(
            withIdentifier: "HomeListingTipVC"
        ) as! HomeListingTipVC

        tipVC.modalPresentationStyle = .overFullScreen
        tipVC.modalTransitionStyle = .crossDissolve

        present(tipVC, animated: true)
    }
 
}

// MARK: - UITableViewDelegate UITableViewDelegate

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrTeaPlaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let teaCell = tableView.dequeueReusableCell(withIdentifier: "TeaListCell", for: indexPath) as! TeaListCell
        teaCell.configure(teaPlace: arrTeaPlaces[indexPath.row])
 
        return teaCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "PlaceDetailVC") as! PlaceDetailVC

        detailVC.place = arrTeaPlaces[indexPath.row]
        detailVC.onBackToHome = { [weak self] in
            guard let self else { return }
            print("⬅️ User came back from Detail to Home")
            // ✅ Refresh UI / reload table / sync favourites
            self.tblTeaPlaces.reloadRows(at: [indexPath], with: .automatic)
        }

        detailVC.onVisitToggle = { [weak self] _ in
            guard let self else { return }

            self.arrTeaPlaces[indexPath.row].toggleIsVisited()
            /*
             //this is after finding index getting back from detail
             if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == placeID }) {
                 self.arrTeaPlaces[index].toggleIsVisited()
             }*/
            HapticHelper.heavy()
        }
        detailVC.onFavToggle = { [weak self] _ in
            guard let self else { return }

            self.arrTeaPlaces[indexPath.row].toggleIsFav()
            
            HapticHelper.heavy()
        }
        

        navigationController?.pushViewController(detailVC, animated: true)

        // performDidSelectOpenActionSheetOperations(table: tableView, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        makeTrailingSwipeActions(table: tableView, indexPath: indexPath)
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        makeLeadingSwipeActions(table: tableView, indexPath: indexPath)
    }

    // MARK: - UIContextMenu on cell tap

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let place = arrTeaPlaces[indexPath.row]

        return UIContextMenuConfiguration(
            identifier: indexPath as NSIndexPath,
            previewProvider: nil
        ) { _ in

            // 📞 Call
            let callAction = UIAction(
                title: "Call",
                image: UIImage(systemName: "phone")
            ) { _ in
                guard let phone = place.phone,
                      let url = URL(string: "tel://\(phone)"),
                      UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
                HapticHelper.heavy()
            }

            
            // ✅ Visited
            let favAction = UIAction(
                title: place.isFav ? "Remove Favourite" : "Add Favourite",
                image: UIImage(
                    systemName: place.isFav ? "heart.slash" : "heart"
                )
            ) { _ in
                self.arrTeaPlaces[indexPath.row].toggleIsFav()
                tableView.reloadRows(at: [indexPath], with: .automatic)
                HapticHelper.heavy()
            }
 

            // ✅ Visited
            let visitedAction = UIAction(
                title: place.isVisited ? "Remove Visited" : "Mark Visited",
                image: UIImage(systemName: place.isVisited ? "checkmark.app" : "checkmark.app.fill")
            ) { _ in
                self.arrTeaPlaces[indexPath.row].toggleIsVisited()
                tableView.reloadRows(at: [indexPath], with: .automatic)
                HapticHelper.heavy()
            }

            return UIMenu(title: "", children: [
                callAction,
                favAction,
                visitedAction,
            ])
        }
    }

    // MARK: - Trailing swipe on cell

    private func makeTrailingSwipeActions(table: UITableView, indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else { return }
            self.arrTeaPlaces.remove(at: indexPath.row)
            table.deleteRows(at: [indexPath], with: .automatic)
            HapticHelper.heavy()
            completion(true)
        }

        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed

        let shareAction = UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let self else { return }

            let place = self.arrTeaPlaces[indexPath.row]
            let shareText = self.makeShareSheetText(for: place)

            var items: [Any] = [shareText]
            if let image = place.image {
                items.append(image)
            }

            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = table
                popover.sourceRect = table.rectForRow(at: indexPath)
            }
            HapticHelper.heavy()
            self.present(activityVC, animated: true)
            completion(true)
        }

        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue

        let config = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    private func makeShareSheetText(for place: TeaPlace) -> String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "My App Name"
        return """
        📍 Place Details :
        🏷️ Place Name: \(place.name ?? "N/A \(appName)")
        📌 Location: \(place.location ?? "N/A \(appName)")
        📞 Phone: \(place.phone.map(String.init) ?? "N/A \(appName)")
        ☕ Description: \(place.desc ?? "N/A \(appName)")
        ⭐ Rating: \(place.rating.map { String(format: "%.1f", $0) } ?? "N/A \(appName)")

        ——————————————
        📲 Shared via \(appName)
        👨‍💻 Made by Harsh Darji – iOS Developer
        🔗 GitHub: dev.iharsh1008
        """
    }

    // MARK: - Leading swipe on cell

    private func makeLeadingSwipeActions(table: UITableView, indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let place = arrTeaPlaces[indexPath.row]


        let favAction = UIContextualAction(style: .normal, title: place.isFav ? "Unfavourite" : "Favourite") { [weak self] _, _, completion in
            guard let self else { return }
            HapticHelper.heavy()
            self.arrTeaPlaces[indexPath.row].toggleIsFav()
            table.reloadRows(at: [indexPath], with: .left)
            completion(true)
        }

        favAction.image = UIImage(systemName: place.isFav ? "heart.slash" : "heart.fill")
        favAction.backgroundColor = place.isFav ? .systemGray : .systemPink
        
        let visitedAction = UIContextualAction(style: .normal, title: place.isVisited ? "Unvisited" : "Visited") { [weak self] _, _, completion in
            guard let self else { return }
            HapticHelper.heavy()
            self.arrTeaPlaces[indexPath.row].toggleIsVisited()
            table.reloadRows(at: [indexPath], with: .left)
            completion(true)
        }

        visitedAction.image = UIImage(systemName: place.isVisited ? "checkmark.circle" : "checkmark.circle.fill")

        visitedAction.backgroundColor = place.isVisited ? .systemGray4 : .systemGreen

        let configuration = UISwipeActionsConfiguration(actions: [visitedAction, favAction])
        configuration.performsFirstActionWithFullSwipe = false

        return configuration
    }

    
}

extension HomeVC {
    func createDummyModel() { arrTeaPlaces.append(contentsOf: [
        TeaPlace(
            name: "Assam Chai Point",
            phone: 9876543210,
            location: "Ahmedabad",
            address: "123 Tea Lane, Satellite, Ahmedabad, Gujarat, India",
            latitude: 23.030357, // Satellite, Ahmedabad lat-long  [oai_citation:0‡LatLong.net](https://www.latlong.net/place/satellite-ahmedabad-india-8065.html?utm_source=chatgpt.com)
            longitude: 72.517845,
            desc: "Cozy chai place with rich Assam blends and city views.Fresh Nilgiri brews with panoramic garden views.Scenic spot for authentic Darjeeling tea above the clouds.Fresh Nilgiri brews with panoramic garden views.Cozy chai place with rich Assam blends and city views.Fresh Nilgiri brews with panoramic garden views.Lush plantation cafe with mist-covered hills all around.Fresh Nilgiri brews with panoramic garden views.",
            rating: 4.3,
            image: UIImage(named: "tea1")
        ),
        TeaPlace(
            name: "Darjeeling Brew House",
            phone: 9876501234,
            location: "Darjeeling",
            address: "45 Hilltop Rd, Darjeeling, West Bengal, India",
            latitude: 27.0360,
            longitude: 88.2626,
            desc: "Scenic spot for authentic Darjeeling tea above the clouds.Fresh Nilgiri brews with panoramic garden views.Cozy chai place with rich Assam blends and city views.Fresh Nilgiri brews with panoramic garden views.",
            rating: 4.7,
            image: UIImage(named: "tea2")
        ),
        TeaPlace(
            name: "Nilgiri Tea Garden Cafe",
            phone: 9123456780,
            location: "Nilgiris",
            address: "Tea Terrace, Coonoor, Tamil Nadu, India",
            latitude: 11.3543,
            longitude: 76.8258,
            desc: "Fresh Nilgiri brews with panoramic garden views.Scenic spot for authentic Darjeeling tea above the clouds.Fresh Nilgiri brews with panoramic garden views.Cozy chai place with rich Assam blends and city views.Fresh Nilgiri brews with panoramic garden views.",
            rating: 4.5,
            image: UIImage(named: "tea3")
        ),
        TeaPlace(
            name: "Munnar Mist Tea Spot",
            phone: 9345678123,
            location: "Munnar",
            address: "99 Green Valley Rd, Munnar, Kerala, India",
            latitude: 10.0892,
            longitude: 77.0595,
            desc: "Lush plantation cafe with mist-covered hills all around.Fresh Nilgiri brews with panoramic garden views.Scenic spot for authentic Darjeeling tea above the clouds.Fresh Nilgiri brews with panoramic garden views.",
            rating: 4.6,
            image: UIImage(named: "tea4")
        ),
        TeaPlace(
            name: "Assam Gardens Brew",
            phone: 9012345678,
            location: "Jorhat",
            address: "Tea Estate Rd, Jorhat, Assam, India",
            latitude: 26.7573,
            longitude: 94.2020,
            desc: "Traditional Assam tea experience inside a working plantation.",
            rating: 4.8,
            image: UIImage(named: "tea5")
        ),
        TeaPlace(
            name: "Kolukkumalai Peak Tea",
            phone: 9785634120,
            location: "Kolukkumalai",
            address: "Peak Rd, Kolukkumalai, Tamil Nadu, India",
            latitude: 10.1925,
            longitude: 77.2550,
            desc: "Highest tea garden cafe in the world with great views.",
            rating: 4.9,
            image: UIImage(named: "tea6")
        ),
        TeaPlace(
            name: "Himalayan Tea Hut",
            phone: 9678901234,
            location: "Kurseong",
            address: "Tea Rd, Kurseong, West Bengal, India",
            latitude: 26.8222,
            longitude: 88.2690,
            desc: "Small mountain cafe surrounded by tea estate.",
            rating: 4.4,
            image: UIImage(named: "tea7")
        ),
        TeaPlace(
            name: "Gujarat Chai Junction",
            phone: 9456123870,
            location: "Ahmedabad",
            address: "88 Caffeine St, Naroda, Ahmedabad, Gujarat, India",
            latitude: 23.068586, // Naroda, Ahmedabad lat-long  [oai_citation:1‡LatLong.net](https://www.latlong.net/place/naroda-ahmedabad-gujarat-india-18808.html?utm_source=chatgpt.com)
            longitude: 72.653595,
            desc: "Urban tea cafe with masala chai and snacks.",
            rating: 4.2,
            image: UIImage(named: "tea8")
        ),
        TeaPlace(
            name: "Spice & Sip Cafe",
            phone: 9567890123,
            location: "Shillong",
            address: "Tea Plaza, Shillong, Meghalaya, India",
            latitude: 25.5788,
            longitude: 91.8933,
            desc: "Hill cafe serving Assam and Himalayan tea blends.",
            rating: 4.5,
            image: UIImage(named: "tea9")
        ),
        TeaPlace(
            name: "Tea Trails Bistro",
            phone: 9234567890,
            location: "Ooty",
            address: "Botanical Rd, Ooty, Tamil Nadu, India",
            latitude: 11.4064,
            longitude: 76.6950,
            desc: "Tea lounge with scenic blue mountains in the backdrop.",
            rating: 4.6,
            image: UIImage(named: "tea10")
        ),
    ]) }
}


/*
 // MARK: - Global Class
 import UIKit
 final class FavouritePlacesSet {
     private static let key = "favourite_place_ids"

     static var favourites: Set<String> {
         get {
             Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
         }
         set {
             UserDefaults.standard.set(Array(newValue), forKey: key)

             // ✅ PRINT every time it changes
             print("❤️ FavouritePlaces updated:", newValue)
         }
     }
 }

 final class FavouritePlacesStore {
     static var favourites = Set<String>()
 }
 
 
 // MARK: - cellForRowAt
let isFav = FavouritePlacesStore.favourites.contains(arrTeaPlaces[indexPath.row].id)
teaCell.isFavImage.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
 

   Favourite
 // MARK: - makeLeadingSwipeActions
 let isFav = FavouritePlacesStore.favourites.contains(place.id)
 let favAction = UIAction(
     title: isFav ? "Remove Favourite" : "Add Favourite",
     image: UIImage(systemName: isFav ? "heart.slash" : "heart"),
     attributes: []
 ) { _ in
     if FavouritePlacesStore.favourites.remove(place.id) == nil {
         FavouritePlacesStore.favourites.insert(place.id)
     }
     tableView.reloadRows(at: [indexPath], with: .automatic)
     HapticHelper.heavy()
     Same code as above == nil
      if FavouritePlacesStore.favourites.contains(placeID) {
          FavouritePlacesStore.favourites.remove(placeID)
      } else {
          FavouritePlacesStore.favourites.insert(placeID)
      }
      
 }
 
 // MARK: - makeLeadingSwipeActions
 let isFav = FavouritePlacesStore.favourites.contains(place.id)

 let favAction = UIContextualAction(style: .normal, title: isFav ? "Unfavourite" : "Favourite") { [weak self] _, _, completion in
     // guard let self else { return }

     if FavouritePlacesStore.favourites.contains(place.id) {
         FavouritePlacesStore.favourites.remove(place.id)
     } else {
         FavouritePlacesStore.favourites.insert(place.id)
     }
     HapticHelper.heavy()
     table.reloadRows(at: [indexPath], with: .left)
     completion(true)
 }
 favAction.image = UIImage(systemName: isFav ? "heart.slash" : "heart.fill")
 favAction.backgroundColor = isFav ? .systemGray : .systemPink
 
 
 // MARK: - ActionSheet on cell tap

 func performDidSelectOpenActionSheetOperations(table: UITableView, indexPath: IndexPath) {
     let place = arrTeaPlaces[indexPath.row]
     let placeID = place.id

     let actionSheet = UIAlertController(
         title: "What action do you want to perform with \(place.name ?? "Selected Place") ?",
         message: nil,
         preferredStyle: .actionSheet
     )

     // 📞 Call
     actionSheet.addAction(UIAlertAction(title: "Call", style: .default) { _ in
         guard let phone = place.phone,
               let url = URL(string: "tel://\(phone)"),
               UIApplication.shared.canOpenURL(url) else { return }
         UIApplication.shared.open(url)
     })

     // ❤️ Favourite
     let favTitle = FavouritePlacesStore.favourites.contains(placeID) ? "Remove from Favourites" : "Add to Favourites"
     actionSheet.addAction(UIAlertAction(title: favTitle, style: .default) { [weak self] _ in
         guard let self else { return }
         if FavouritePlacesStore.favourites.remove(placeID) == nil {
             FavouritePlacesStore.favourites.insert(placeID)
         }
         table.reloadRows(at: [indexPath], with: .none)
     })

     // ✅ Visited
     let visitedTitle = place.isVisited ? "Remove from Visited" : "Add to Visited"
     actionSheet.addAction(UIAlertAction(title: visitedTitle, style: .default) { [weak self] _ in
         guard let self else { return }
         arrTeaPlaces[indexPath.row].toggleIsVisited()
         table.reloadRows(at: [indexPath], with: .none)
     })

     actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

     // 📱 iPad support
     if let popover = actionSheet.popoverPresentationController {
         popover.sourceView = table
         popover.sourceRect = table.rectForRow(at: indexPath)
         popover.permittedArrowDirections = [.up, .down]
     }

     present(actionSheet, animated: true)
 }
 // MARK: - detectLongPressOnCell
 func detectLongPressOnCell() {
     let longPressGesture = UILongPressGestureRecognizer(
         target: self,
         action: #selector(handleLongPress(_:))
     )
     tblTeaPlaces.addGestureRecognizer(longPressGesture)
 }

@objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    // fire only once (not continuously)
    guard gesture.state == .began else { return }

    let point = gesture.location(in: tblTeaPlaces)
    guard let indexPath = tblTeaPlaces.indexPathForRow(at: point) else { return }

    // reuse your existing logic
    performDidSelectOpenActionSheetOperations(table: tblTeaPlaces, indexPath: indexPath)
}
 */
