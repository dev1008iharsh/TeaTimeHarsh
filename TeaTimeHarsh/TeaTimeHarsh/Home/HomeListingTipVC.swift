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
    @IBOutlet var lblQuickTip: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        lblQuickTip.text = """

        • Long-press a place for more actions
        • Swipe left for mark visited and favourite
        • Swipe Right for share and delete

        """
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        addDismissGesture()
        // Do any additional setup after loading the view.
    }
    
    deinit {
        print("💀 deinit HomeListingTipVC is dead. Memory Free!")
    }

    private func addDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTip))
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissTip() {
        dismiss(animated: true)
    }
}
