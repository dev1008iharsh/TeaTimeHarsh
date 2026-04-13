//
//  ReviewHandler.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 13/04/26.
//

import UIKit
import StoreKit

final class ReviewManager {

    static let shared = ReviewManager()

    private init() {}

    private let userDefaults = UserDefaults.standard
    private let reviewActionCounterKey = "reviewActionCounter"
    private let lastReviewRequestAppVersionKey = "lastReviewRequestAppVersion"

    func logReviewEligibleEvent(in scene: UIWindowScene?) {
        let currentCount = userDefaults.integer(forKey: reviewActionCounterKey)
        let updatedCount = currentCount + 1
        userDefaults.set(updatedCount, forKey: reviewActionCounterKey)

        if updatedCount >= 3 {
            checkAndPresentReviewRequest(in: scene)
        }
    }

    private func checkAndPresentReviewRequest(in scene: UIWindowScene?) {
        guard let scene = scene else { return }

        let infoDictionaryKey = kCFBundleVersionKey as String
        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
        let lastVersionThatShowedReview = userDefaults.string(forKey: lastReviewRequestAppVersionKey)

        if currentAppVersion != lastVersionThatShowedReview {
            // Modern StoreKit 2 API for iOS 17+
            SKStoreReviewController.requestReview(in: scene)

            userDefaults.set(currentAppVersion, forKey: lastReviewRequestAppVersionKey)
            userDefaults.set(0, forKey: reviewActionCounterKey)
        }
    }

    func redirectToAppStoreForReview(appID: String) {
        let appStoreReviewURL = "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"
        if let url = URL(string: appStoreReviewURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
