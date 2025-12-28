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

    /*
      var setFavPlaces: Set<String> {
          get { FavouritePlacesSet.favourites }
          set { FavouritePlacesSet.favourites = newValue }
      }
     var setFavPlaces = Set<String>() // For managing favourite places ❤️
      */

    override func viewDidLoad() {
        super.viewDidLoad()
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        createDummyModel()
        presentTipIfNeeded()
        configureNavBar()

        // detectLongPressOnCell()
    }

    private func configureNavBar() {
        hideBackButtonNavBar(hidden: true, swipeEnabled: true)
        setLargeTitleSpacingNavBar(20)
        setNavigationTitleStyleNavBar(font: .systemFont(ofSize: 20, weight: .bold), color: .systemIndigo)
        // setCustomBackButton(image: UIImage(named: "backButtonIcon") ?? UIImage(), text: "Back", color: .systemIndigo)
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

    /*
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
     }*/
}

// MARK: - UITableViewDelegate UITableViewDelegate

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrTeaPlaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let teaCell = tableView.dequeueReusableCell(withIdentifier: "TeaListCell", for: indexPath) as! TeaListCell
        teaCell.configure(teaPlace: arrTeaPlaces[indexPath.row])

        let isFav = FavouritePlacesStore.favourites.contains(arrTeaPlaces[indexPath.row].id)
        teaCell.isFavImage.image = UIImage(systemName: isFav ? "heart.fill" : "heart")

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

            self.arrTeaPlaces[indexPath.row].toggleIsVisisted()
            /*
             //this is after finding index getting back from detail
             if let index = self.arrTeaPlaces.firstIndex(where: { $0.id == placeID }) {
                 self.arrTeaPlaces[index].toggleIsVisisted()
             }*/
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
            }

            // ❤️ Favourite
            let isFav = FavouritePlacesStore.favourites.contains(place.id)
            let favAction = UIAction(
                title: isFav ? "Remove Favourite" : "Add Favourite",
                image: UIImage(systemName: isFav ? "heart.slash" : "heart"),
                attributes: []
            ) { _ in
                if FavouritePlacesStore.favourites.remove(place.id) == nil {
                    FavouritePlacesStore.favourites.insert(place.id)
                }
                tableView.reloadRows(at: [indexPath], with: .none)

                /* Same code as above == nil
                 if FavouritePlacesStore.favourites.contains(placeID) {
                     FavouritePlacesStore.favourites.remove(placeID)
                 } else {
                     FavouritePlacesStore.favourites.insert(placeID)
                 }
                 */
            }

            // ✅ Visited
            let visitedAction = UIAction(
                title: place.isVisited ? "Remove Visited" : "Mark Visited",
                image: UIImage(systemName: place.isVisited ? "checkmark.app" : "checkmark.app.fill")
            ) { _ in
                self.arrTeaPlaces[indexPath.row].toggleIsVisisted()
                tableView.reloadRows(at: [indexPath], with: .none)
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

            self.present(activityVC, animated: true)
            completion(true)
        }

        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue

        let config = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        config.performsFirstActionWithFullSwipe = true
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
        
        let isFav = FavouritePlacesStore.favourites.contains(place.id)
        
        let favAction = UIContextualAction(style: .normal, title: isFav ? "Unfavourite" : "Favourite") { [weak self] _, _, completion in
            //guard let self else { return }

            if FavouritePlacesStore.favourites.contains(place.id) {
                FavouritePlacesStore.favourites.remove(place.id)
            } else {
                FavouritePlacesStore.favourites.insert(place.id)
            }

            table.reloadRows(at: [indexPath], with: .none)
            completion(true)
        }
        favAction.image = UIImage(systemName: isFav ? "heart.slash" : "heart.fill")
        favAction.backgroundColor = .systemPink

        let visitedAction = UIContextualAction(style: .normal, title: place.isVisited ? "Unvisited" : "Visited") { [weak self] _, _, completion in
            guard let self else { return }

            self.arrTeaPlaces[indexPath.row].toggleIsVisisted()
            table.reloadRows(at: [indexPath], with: .none)
            completion(true)
        }

        visitedAction.image = UIImage(systemName: place.isVisited ? "checkmark.circle" : "checkmark.circle.fill")

        visitedAction.backgroundColor = .systemGreen

        let configuration = UISwipeActionsConfiguration(actions: [visitedAction, favAction])
        configuration.performsFirstActionWithFullSwipe = true

        return configuration
    }

    /*
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
             arrTeaPlaces[indexPath.row].toggleIsVisisted()
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
     }*/
}

extension HomeVC {
    func createDummyModel() {
        arrTeaPlaces.append(contentsOf: [TeaPlace(name: "Assam Chai Point",
                                                  phone: 9876543210,
                                                  location: "Ahmedabad",
                                                  desc: "Street Tea",
                                                  rating: 4.3,
                                                  image: UIImage(named: "tea1")),

                                         TeaPlace(name: "Darjeeling Tea House",
                                                  phone: 9876543211,
                                                  location: "Mumbai",
                                                  desc: "Premium Tea",
                                                  rating: 4.6,
                                                  image: UIImage(named: "tea2")),

                                         TeaPlace(name: "Masala Chai Adda",
                                                  phone: 9876543212,
                                                  location: "Delhi",
                                                  desc: "Masala Tea",
                                                  rating: 4.1,
                                                  image: UIImage(named: "tea3")),

                                         TeaPlace(name: "Green Leaf Café",
                                                  phone: 9876543213,
                                                  location: "Pune",
                                                  desc: "Organic Tea",
                                                  rating: 4.5,
                                                  image: UIImage(named: "tea4")),

                                         TeaPlace(name: "Royal Kulhad Chai",
                                                  phone: 9876543214,
                                                  location: "Jaipur",
                                                  desc: "Kulhad Tea",
                                                  rating: 4.4,
                                                  image: UIImage(named: "tea5")),

                                         TeaPlace(name: "Evening Chaiwala",
                                                  phone: 9876543215,
                                                  location: "Indore",
                                                  desc: "Street Tea",
                                                  rating: 4.0,
                                                  image: UIImage(named: "tea6")),

                                         TeaPlace(name: "Himalayan Tea Lounge",
                                                  phone: 9876543216,
                                                  location: "Shimla",
                                                  desc: "Herbal Tea",
                                                  rating: 4.7,
                                                  image: UIImage(named: "tea7")),

                                         TeaPlace(name: "South Sip Chai",
                                                  phone: 9876543217,
                                                  location: "Bangalore",
                                                  desc: "Filter Tea",
                                                  rating: 4.2,
                                                  image: UIImage(named: "tea8")),

                                         TeaPlace(name: "Midnight Chai Hub",
                                                  phone: 9876543218,
                                                  location: "Hyderabad",
                                                  desc: "Late Night Tea",
                                                  rating: 4.1,
                                                  image: UIImage(named: "tea9")),

                                         TeaPlace(name: "Urban Tea Café",
                                                  phone: 9876543219,
                                                  location: "Gurgaon",
                                                  desc: "Modern Café",
                                                  rating: 4.3,
                                                  image: UIImage(named: "tea10")),

                                         TeaPlace(name: "Classic Cutting Chai",
                                                  phone: 9876543220,
                                                  location: "Surat",
                                                  desc: "Cutting Chai",
                                                  rating: 4.4,
                                                  image: UIImage(named: "tea11")),

                                         TeaPlace(name: "Morning Brew Chai",
                                                  phone: 9876543221,
                                                  location: "Vadodara",
                                                  desc: "Morning Tea",
                                                  rating: 3.9,
                                                  image: UIImage(named: "tea12")),

                                         TeaPlace(name: "Soulful Sips",
                                                  phone: 9876543222,
                                                  location: "Udaipur",
                                                  desc: "Lake View Café",
                                                  rating: 4.6,
                                                  image: UIImage(named: "tea13")),

                                         TeaPlace(name: "Campus Chai Stop",
                                                  phone: 9876543223,
                                                  location: "Gandhinagar",
                                                  desc: "Student Favorite",
                                                  rating: 4.0,
                                                  image: UIImage(named: "tea14")),

                                         TeaPlace(name: "Vintage Tea Corner",
                                                  phone: 9876543224,
                                                  location: "Kolkata",
                                                  desc: "Traditional Tea",
                                                  rating: 4.5,
                                                  image: UIImage(named: "tea15")),

                                         TeaPlace(name: "Highway Chai Dhaba",
                                                  phone: 9876543225,
                                                  location: "NH-8",
                                                  desc: "Highway Tea",
                                                  rating: 4.2,
                                                  image: UIImage(named: "tea16")),

                                         TeaPlace(name: "Sunset Tea Garden",
                                                  phone: 9876543226,
                                                  location: "Mount Abu",
                                                  desc: "Scenic Tea",
                                                  rating: 4.7,
                                                  image: UIImage(named: "tea17")),

            ])
    }
}
