//
//  HomeListingTipVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import UIKit

enum AppLaunchTracker {
    static let homeListingTipLaunchCount = "homeListingTipLaunchCount"
    //tool tip screen show only 3 times
}

struct HomeListingTipManager {
    static func shouldShowTip() -> Bool {
        UserDefaults.standard.integer(forKey: AppLaunchTracker.homeListingTipLaunchCount) <= 3
    }
}

class HomeListingTipVC: UIViewController {
    @IBOutlet var lblQuickTip: UILabel! {
        didSet {
            lblQuickTip.text = """

            • Long-press a place for more actions
            • Swipe left for mark visited and favourite
            • Swipe Right for share and delete

            """
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        addDismissGesture()
        // Do any additional setup after loading the view.
    }

    private func addDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTip))
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissTip() {
        dismiss(animated: true)
    }
}
