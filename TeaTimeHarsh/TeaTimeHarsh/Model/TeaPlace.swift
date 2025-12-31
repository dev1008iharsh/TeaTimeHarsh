//
//  TeaPlace.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import Foundation
import UIKit
 

struct TeaPlace {
    let id: String // Unique ID
    let name: String?
    let phone: Int?
    let location: String?        // e.g. city
    let address: String?         // full address selected by user
    let latitude: Double?        // lat from map
    let longitude: Double?       // long from map
    let desc: String?
    let rating: Double?
    let image: UIImage?
    private(set) var isVisited: Bool = false
    private(set) var isFav: Bool = false

    init(name: String?,
         phone: Int?,
         location: String?,
         address: String?,
         latitude: Double?,
         longitude: Double?,
         desc: String?,
         rating: Double?,
         image: UIImage?) {
        id = UUID().uuidString
        self.name = name
        self.phone = phone
        self.location = location
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.desc = desc
        self.rating = rating
        self.image = image
    }

    mutating func toggleIsVisited() {
        isVisited.toggle()
    }
    mutating func toggleIsFav() {
        isFav.toggle()
    }
}
