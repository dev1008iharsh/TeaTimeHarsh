//
//  SelectPlaceOnMapVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import UIKit

class SelectPlaceOnMapVC: UIViewController {

    
    let locationManager = LocationManager.shared
 
    override func viewDidLoad() {
        super.viewDidLoad()
 
    }
    
    
    func manageLocation(){
        locationManager.checkAuthorizationStatus(from: self)
        locationManager.onLocationUpdate = { location in
            // Handle location update
            print("New location: \(location)")
        }
        
        locationManager.onLocationFailure = { error in
            // Handle location update failure
            print("Location update failed: \(error)")
        }
        
        //NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription
        //"We want use your current location to provide personalized experiences and improve our service."
    } 

}
