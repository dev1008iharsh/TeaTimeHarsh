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

        // this launchvc for preload data from internet if needed
        fetchCurrentUserData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.goToHome()
        }
    }
    func fetchCurrentUserData() {
        LoaderManager.shared.startLoading()

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let userProfileData = try await UserDataManager.shared
                    .fetchCurrentUser()
                UserDataManager.shared.user = userProfileData

                print(
                    "fetch current user details using api at launch vc \(String(describing: UserDataManager.shared.user))"
                )
            } catch {
                Utility
                    .showAlert(
                        title: "Error",
                        message: error.localizedDescription,
                        viewController: self
                    )
            }

            LoaderManager.shared.stopLoading()
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
        navigationController?.setViewControllers([homeVC], animated: true)    }
}
