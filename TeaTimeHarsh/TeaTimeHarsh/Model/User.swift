//
//  User.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 08/01/26.
//
 
// MARK: - 🆔 Identity
// 🔗 LINKING LOGIC: This 'id' is what you will save inside TeaModel as 'createdByUserID'
// @DocumentID automatically maps the Firestore Document ID to this variable.

import Foundation
import FirebaseFirestore

enum AuthProviderType: String, Codable {
    case facebook
    case google
    case apple
    case email   // 👈 We will use this as default
    case unknown
}

struct User: Identifiable, Codable {
    
    // MARK: - 🆔 Identity
    @DocumentID var id: String?
    
    // ⚠️ Made Optional.
    // Reason: When registering via Email/Pass, you might not ask for a username immediately.
    var username: String?
    
    var email: String
    
    // MARK: - 📝 Profile Details (All Optionals)
    var bio: String?
    var phoneNumber: String?
    var city: String?
    var profileImageUrl: String?
    var birthDate: Date?
    
    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.year], from: birthDate, to: Date()).year
    }
    
    // MARK: - 🔗 Social Login Info
    // ⚠️ Made Optional.
    // Reason: Email/Pass users don't have an external Provider ID.
    var providerID: String?
    
    var providerType: AuthProviderType
    
    // MARK: - 🚦 Status Flags
    // We provide DEFAULT values for these in the init logic below
    var isEmailVerified: Bool
    var isActive: Bool
    var isOnBoardingDone: Bool
    var isSubscribed: Bool
    
    var isSocialLogin: Bool {
        return providerType != .email && providerType != .unknown
    }
    
    // MARK: - ⌚️ Metadata
    var createdAt: Date
    var lastLoginAt: Date?
    var fcmToken: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case bio
        case phoneNumber = "phone_number"
        case city
        case profileImageUrl = "profile_image_url"
        case birthDate = "birth_date"
        case providerID = "provider_id"
        case providerType = "provider_type"
        case isEmailVerified = "is_email_verified"
        case isActive = "is_active"
        case isOnBoardingDone = "is_onboarding_done"
        case isSubscribed = "is_subscribed"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
        case fcmToken = "fcm_token"
    }
}
