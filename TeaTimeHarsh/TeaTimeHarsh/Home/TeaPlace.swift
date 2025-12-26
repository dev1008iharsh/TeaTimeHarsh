//
//  TeaPlace.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 26/12/25.
//

import Foundation
import UIKit

 

struct TeaPlace {
    let id: String        // Unique ID
    let name: String?
    let phone: Int?
    let location : String?
    let type : String?
    let rating : Double?
    let image : UIImage?
    private(set) var isFav : Bool = false
    private(set) var isVisited : Bool = false

    init(name: String?, phone: Int?, location: String?, type: String?, rating: Double?, image: UIImage?){
        self.id = UUID().uuidString
        self.name = name
        self.phone = phone
        self.location = location
        self.type = type
        self.rating = rating
        self.image = image
    }
    
    mutating func toggleIsVisisted(){
        isVisited.toggle()
    }
    mutating func toggleIsFav(){
        isFav.toggle()
    }
}
