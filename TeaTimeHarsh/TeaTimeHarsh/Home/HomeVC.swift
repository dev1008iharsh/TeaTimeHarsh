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
    var setFavPlaces = Set<String>() //For managing favourite places ❤️
     
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblTeaPlaces.register(UINib(nibName: "TeaListCell", bundle: nil), forCellReuseIdentifier: "TeaListCell")
        createDummyModel()
    }

    
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrTeaPlaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let teaCell = tableView.dequeueReusableCell(withIdentifier: "TeaListCell", for: indexPath) as! TeaListCell
        teaCell.configure(teaPlace: arrTeaPlaces[indexPath.row])
        
        let isFav = setFavPlaces.contains(arrTeaPlaces[indexPath.row].id)
        teaCell.isFavImage.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
        
        return teaCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performDidSelectOperations(table: tableView, indexPath: indexPath)
    }
    
    func performDidSelectOperations(table: UITableView, indexPath: IndexPath) {

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
        let favTitle = setFavPlaces.contains(placeID) ? "Remove from Favourites" : "Add to Favourites"
        actionSheet.addAction(UIAlertAction(title: favTitle, style: .default) { [weak self] _ in
            guard let self else { return }
            if setFavPlaces.remove(placeID) == nil {
                setFavPlaces.insert(placeID)
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
    }
}
extension HomeVC{
    func createDummyModel() {
        arrTeaPlaces.append(contentsOf: [TeaPlace(name: "Assam Chai Point",
                                                  phone: 9876543210,
                                                  location: "Ahmedabad",
                                                  type: "Street Tea",
                                                  rating: 4.3,
                                                  image: UIImage(named: "tea1")),
                                                
                                         TeaPlace(name: "Darjeeling Tea House",
                                                  phone: 9876543211,
                                                  location: "Mumbai",
                                                  type: "Premium Tea",
                                                  rating: 4.6,
                                                  image: UIImage(named: "tea2")),
                                                
                                         TeaPlace(name: "Masala Chai Adda",
                                                  phone: 9876543212,
                                                  location: "Delhi",
                                                  type: "Masala Tea",
                                                  rating: 4.1,
                                                  image: UIImage(named: "tea3")),
                                             

                                         TeaPlace(name: "Green Leaf Café",
                                                  phone: 9876543213,
                                                  location: "Pune",
                                                  type: "Organic Tea",
                                                  rating: 4.5,
                                                  image: UIImage(named: "tea4")),
                                                  

                                         TeaPlace(name: "Royal Kulhad Chai",
                                                  phone: 9876543214,
                                                  location: "Jaipur",
                                                  type: "Kulhad Tea",
                                                  rating: 4.4,
                                                  image: UIImage(named: "tea5")),
                                                  

                                         TeaPlace(name: "Evening Chaiwala",
                                                  phone: 9876543215,
                                                  location: "Indore",
                                                  type: "Street Tea",
                                                  rating: 4.0,
                                                  image: UIImage(named: "tea6")),
                                               

                                         TeaPlace(name: "Himalayan Tea Lounge",
                                                  phone: 9876543216,
                                                  location: "Shimla",
                                                  type: "Herbal Tea",
                                                  rating: 4.7,
                                                  image: UIImage(named: "tea7")),
                                                  

                                         TeaPlace(name: "South Sip Chai",
                                                  phone: 9876543217,
                                                  location: "Bangalore",
                                                  type: "Filter Tea",
                                                  rating: 4.2,
                                                  image: UIImage(named: "tea8")),
                                                  

                                         TeaPlace(name: "Midnight Chai Hub",
                                                  phone: 9876543218,
                                                  location: "Hyderabad",
                                                  type: "Late Night Tea",
                                                  rating: 4.1,
                                                  image: UIImage(named: "tea9")),
                                                  

                                         TeaPlace(name: "Urban Tea Café",
                                                  phone: 9876543219,
                                                  location: "Gurgaon",
                                                  type: "Modern Café",
                                                  rating: 4.3,
                                                  image: UIImage(named: "tea10")),
                                                  

                                         TeaPlace(name: "Classic Cutting Chai",
                                                  phone: 9876543220,
                                                  location: "Surat",
                                                  type: "Cutting Chai",
                                                  rating: 4.4,
                                                  image: UIImage(named: "tea11")),
                                                   

                                         TeaPlace(name: "Morning Brew Chai",
                                                  phone: 9876543221,
                                                  location: "Vadodara",
                                                  type: "Morning Tea",
                                                  rating: 3.9,
                                                  image: UIImage(named: "tea12")),
                                               

                                         TeaPlace(name: "Soulful Sips",
                                                  phone: 9876543222,
                                                  location: "Udaipur",
                                                  type: "Lake View Café",
                                                  rating: 4.6,
                                                  image: UIImage(named: "tea13")),
                                                  

                                         TeaPlace(name: "Campus Chai Stop",
                                                  phone: 9876543223,
                                                  location: "Gandhinagar",
                                                  type: "Student Favorite",
                                                  rating: 4.0,
                                                  image: UIImage(named: "tea14")),
                                                

                                         TeaPlace(name: "Vintage Tea Corner",
                                                  phone: 9876543224,
                                                  location: "Kolkata",
                                                  type: "Traditional Tea",
                                                  rating: 4.5,
                                                  image: UIImage(named: "tea15")),
                                               

                                         TeaPlace(name: "Highway Chai Dhaba",
                                                  phone: 9876543225,
                                                  location: "NH-8",
                                                  type: "Highway Tea",
                                                  rating: 4.2,
                                                  image: UIImage(named: "tea16")),
                                                

                                         TeaPlace(name: "Sunset Tea Garden",
                                                  phone: 9876543226,
                                                  location: "Mount Abu",
                                                  type: "Scenic Tea",
                                                  rating: 4.7,
                                                  image: UIImage(named: "tea17")),
                                                 
                                     ])

            
    }
}
