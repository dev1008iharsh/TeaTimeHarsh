//
//  PlaceReview.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 12/01/26.
//

import FirebaseFirestore
import Foundation

// Mandatory : Rating, Comment, Image
struct PlaceReview: Identifiable, Codable {
    @DocumentID var id: String? // this will be UserID

    let userId: String
    let userName: String
    let userImage: String? // User's profile pic (Optional)

    // 🔥 The 3 Mandatory Things
    let rating: Double
    let reviewText: String
    let reviewImageURL: String // Only 1 Image Allowed

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userImage = "user_image"
        case rating
        case reviewText = "review_text"
        case reviewImageURL = "review_image_url"
        case createdAt = "created_at"
    }
}
