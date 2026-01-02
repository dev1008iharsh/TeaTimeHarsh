//
//  LaunchVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 27/12/25.
//

import UIKit

class LaunchVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.goToHome()
        }
    }

    deinit {
        print("💀 deinit LaunchVC is dead. Memory Free!")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func goToHome() {
        let homeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC")
        // homeVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(homeVC, animated: false)
    }
}
