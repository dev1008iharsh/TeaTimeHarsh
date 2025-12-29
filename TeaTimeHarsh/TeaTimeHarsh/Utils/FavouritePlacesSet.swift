//
//  ManageFavouriteSet.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//
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
