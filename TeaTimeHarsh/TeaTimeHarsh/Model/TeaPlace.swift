import Foundation
import UIKit
 
/*
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
}*/

struct TeaPlace: Identifiable, Codable {
    
    // MARK: - Stored Properties (Saved in 'places' collection)
    let id: String
    let name: String
    let desc: String?
    
    let phone: String?
    let location: String?
    let address: String?
    
    let latitude: Double?
    let longitude: Double?
    
    let imageURL: String?
    let rating: Double?
    
    let priceRange: String?
    let openingTime: String?
    let closingTime: String?
    let holiday: String?
    
    let createdByUserId: String
    let createdAt: Date
    
    // MARK: - Local User State (Saved in 'users/harsh123/user_actions')
    // Note: These are 'var' because user can toggle them locally.
    var isVisited: Bool = false
    var isFav: Bool = false
    
    // MARK: - CodingKeys
    // We EXCLUDE 'isVisited' and 'isFav' here so they don't go into the main public list.
    enum CodingKeys: String, CodingKey {
        case id, name, desc, phone, location, address
        case latitude, longitude, imageURL, rating
        case priceRange, openingTime, closingTime, holiday
        case createdByUserId, createdAt
    }
    
    // MARK: - Logic (Computed Property)
    var isOpenNow: Bool {
        if let holiday = holiday, let todayName = getDayName(), holiday.lowercased() == todayName.lowercased() {
            return false
        }
        guard let openTime = openingTime, let closeTime = closingTime else {
            return false
        }
        return isCurrentTimeBetween(startTime: openTime, endTime: closeTime)
    }
    
    // MARK: - Helper Functions
    private func getDayName() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: Date())
    }
    
    private func isCurrentTimeBetween(startTime: String, endTime: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let start = dateFormatter.date(from: startTime),
              let end = dateFormatter.date(from: endTime) else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        guard let nowHour = nowComponents.hour, let nowMin = nowComponents.minute,
              let startHour = startComponents.hour, let startMin = startComponents.minute,
              let endHour = endComponents.hour, let endMin = endComponents.minute else {
            return false
        }
        
        let nowInMinutes = (nowHour * 60) + nowMin
        let startInMinutes = (startHour * 60) + startMin
        let endInMinutes = (endHour * 60) + endMin
        
        return nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes
    }
}
