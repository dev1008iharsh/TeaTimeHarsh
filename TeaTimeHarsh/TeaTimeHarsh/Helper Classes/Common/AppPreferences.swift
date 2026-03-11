//
//  AppPreferences.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/03/26.
//
 

import Foundation

/// Manages user preferences using UserDefaults
struct AppPreferences {
    private static let biometricKey = "isBiometricEnabledAtLaunch"
    
    /// Save user's choice for biometric login at app launch
    static func setBiometricEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: biometricKey)
    }
    
    /// Check if biometric is enabled for app launch
    static func isBiometricEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: biometricKey)
    }
}
