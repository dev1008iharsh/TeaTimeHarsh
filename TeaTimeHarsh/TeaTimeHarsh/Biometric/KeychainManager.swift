//
//  KeychainManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 11/03/26.
//

//
//  KeychainManager.swift
//  TeatimeHarsh
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let accountName = AppConstants.Strings.keychainAccountName
    
    private init() {}
    
    // Save MPIN securely to Keychain
    func saveMPIN(_ pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            // Makes sure the item is only accessible when the device is unlocked
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item before saving a new one
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // Retrieve MPIN from Keychain
    func getMPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
