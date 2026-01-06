//
//  ComentedCode.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/01/26.
//



/*
 
 if FavouritePlacesStore.favourites.contains(placeID) {
     FavouritePlacesStore.favourites.remove(placeID)
 } else {
     FavouritePlacesStore.favourites.insert(placeID)
 }

 let isFav = FavouritePlacesStore.favourites.contains(placeID)
 header.updateFavouriteButton(isFavourite: isFav)
 
 
 
 
if FavouritePlacesStore.favourites.contains(place.id) {
    updateFavouriteButton(isFavourite: true)
} else {
    updateFavouriteButton(isFavourite: false)
}
 
 
 var onSubmitTap: (() -> Void)?

 @IBAction func submitButton(_ sender: UIButton) {
 print("Header button tapped - UserHeaderView: UIView")
 onSubmitTap?()
 }*/



/* HOMEVC Comment CODE
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
}*/


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
