//
//  UserPlacesListVC.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import UIKit

class UserPlacesListVC: UIViewController {
    // MARK: - Properties

    var places: [TeaPlace] = []
 
    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Delete All Places?"
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Here is the list of all the places you have added till now. 📝 These will all be deleted. This action cannot be undone. Once you delete, all data related to these places will be removed permanently. 🔴"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray2
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UserPlacesListTableCell.self, forCellReuseIdentifier: UserPlacesListTableCell.identifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.allowsSelection = false
        return table
    }()

    private let deleteAllButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Delete all places", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .systemRed
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .systemGray5
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfiguration()
        setupUI()
    }

    // MARK: - Setup & Configuration

    private func setupConfiguration() {
        view.backgroundColor = .systemBackground

        // Configure Sheet behavior
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

         

        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self

        // Setup Actions
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        deleteAllButton.addTarget(self, action: #selector(didTapDeleteAction), for: .touchUpInside)
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(tableView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(deleteAllButton)

        NSLayoutConstraint.activate([
            // Header
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Buttons (Pinned to bottom)
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // TableView (Fills remaining space)
            tableView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -10),
        ])
    }

    // MARK: - Actions

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapDeleteAction() {
        // Refactored: Now handles both cases correctly
     
            performDeleteAllPlaces()
        
    }

    // MARK: - Network Logic

 
    private func performDeleteAllPlaces() {
        Utility.showYesNoConfirmAlert(
            title: "Delete All Places?",
            message: "Wait! Do you really want to remove all your added places? You won't be able to recover them later.🔴",
            viewController: self
        ) { [weak self] _ in
            guard let self = self else { return }

            Task {
                LoaderManager.shared.startLoading()
                do {
                    defer {
                        DispatchQueue.main.async { LoaderManager.shared.stopLoading() }
                    }
                    try await FirebaseManager.shared.deleteAllPlacesCreatedByUser()

                    await MainActor.run {
                        HapticHelper.success()
                        self.dismiss(animated: true)
                        /*
                        Utility.showAlertHandler(
                            title: "All places deleted ✅",
                            message: "All places successfully deleted.  🍵 Tap the ➕ button on the Home screen to add new places ✨",
                            viewController: self
                        ) { _ in
                            self.dismiss(animated: true)
                        }*/
                    }
                } catch {
                    await MainActor.run {
                        HapticHelper.error()
                        Utility.showAlert(
                            title: "Error",
                            message: error.localizedDescription,
                            viewController: self
                        )
                    }
                }
            }
        } noAction: { _ in
            print("Delete cancelled by user")
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension UserPlacesListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserPlacesListTableCell.identifier, for: indexPath) as! UserPlacesListTableCell
        cell.configure(place: places[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
