//
//  UserPlacesListTableCell.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 07/01/26.
//

import Foundation
import UIKit

class UserPlacesListTableCell: UITableViewCell {

    // 🟢 Static ID for easy reuse
    static let identifier = "UserPlacesListTableCell"

    // 🖼️ UI Elements
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8 // Slight curve like modern iOS apps
        iv.backgroundColor = .systemGray5 // Placeholder color
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold) // Standard Title size
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular) // Standard Subtitle size
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 📦 StackView to hold Title & Subtitle vertically
    private let textStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4 // Gap between title and subtitle
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // 🛠️ Init Method
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 📐 Setup UI & Constraints
    private func setupUI() {
        // Add subviews
        contentView.addSubview(iconImageView)
        contentView.addSubview(textStackView)
        
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        
        // 📏 Constraints
        NSLayoutConstraint.activate([
            // Image Constraints (Fixed size mimic default look)
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // StackView Constraints
            textStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    // 📤 Configuration Method
    func configure(place:TeaPlace) {
        titleLabel.text = place.name
        subtitleLabel.text = place.location
        ImageManagerKF.setImage(
                from: place.imageURL,
                into: iconImageView,
                placeholderName: "photo")
    }
}
