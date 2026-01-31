//
//  UploadProgressHUD.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//

import UIKit

/// A singleton view to show upload progress (0% to 100%) in the center of the screen.
class UploadProgressHUD: UIView {
    static let shared = UploadProgressHUD()

    // MARK: - UI Components

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let percentLabel = UILabel()

    override private init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6) // Semi-transparent background

        // White Card Container
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // Title Label
        titleLabel.text = "Uploading Media... ☁️"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Progress Bar
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false

        // Percentage Label
        percentLabel.text = "0%"
        percentLabel.font = .systemFont(ofSize: 14)
        percentLabel.textAlignment = .center
        percentLabel.textColor = .secondaryLabel
        percentLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(percentLabel)

        // Layout Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 260),
            containerView.heightAnchor.constraint(equalToConstant: 140),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            progressView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            percentLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
            percentLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])
    }

    // MARK: - Public Functions

    /// Shows the loader on the given view (usually view.window)
    func show(on view: UIView) {
        frame = view.bounds
        progressView.progress = 0.0
        percentLabel.text = "0%"
        view.addSubview(self)
    }

    /// Updates the progress bar and label text
    /// - Parameter progress: Value between 0.0 and 1.0
    func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.progressView.setProgress(Float(progress), animated: true)
            let percentage = Int(progress * 100)
            self.percentLabel.text = "\(percentage)%"
        }
    }

    /// Removes the loader from screen
    func dismiss() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }
}
