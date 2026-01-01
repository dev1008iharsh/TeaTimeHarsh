//
//  Constants.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/01/26.
//

import UIKit
// 1. Create the Enum and tell it to use 'String' as its backing type
enum Constant: String {
    
    // 2. Define your static URLs here
    case currentUserID = "firstUser1"
    case imageUrlToUploadDummy = "https://images.unsplash.com/photo-1544787219-7f47ccb76574?q=80&w=1000&auto=format&fit=crop"
    
    
    case termsOfService = "https://www.teafinder.com/terms"
    case support = "https://www.teafinder.com/support"
    case google = "https://www.google.com"
    
    // 3. Pro Trick: A computed property to give you the actual URL object
    // This saves you from typing "URL(string: ...)" everywhere!
    var url: URL {
        // We use a force unwrap (!) here ONLY because we know these strings are 100% correct.
        // In a real app, if you type a bad URL above, you want it to crash in testing so you fix it instantly.
        return URL(string: self.rawValue)!
    }
}


