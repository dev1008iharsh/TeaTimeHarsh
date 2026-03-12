//
//  BiometricManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/03/26.
//
 
import Foundation
import LocalAuthentication

/// A singleton manager to handle biometric authentication (FaceID / TouchID)
class BiometricManager {
    static let shared = BiometricManager()
    
    private init() {}
    
    /// Checks if the device supports biometric authentication
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Presents the FaceID/TouchID prompt to the user
    func authenticateUser(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        let reason = AppConstants.Strings.unlockMessage
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
                // Always return on the main thread
                DispatchQueue.main.async {
                    completion(success, evalError)
                }
            }
        } else {
            // Biometrics not available or not enrolled
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
}
