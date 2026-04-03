//
//  FavoriteFilterView.swift
//  eltex_dz_8
//
//  Created by Роман Герговский on 03.04.2026.
//

import UIKit

// MARK: - FavoriteFilterViewDelegate

protocol FavoriteFilterViewDelegate: AnyObject {
    func favoriteFilterView(_ view: FavoriteFilterView, didChangeState isEnabled: Bool)
}

// MARK: - FavoriteFilterView

final class FavoriteFilterView: UIView {
    weak var delegate: FavoriteFilterViewDelegate?

    var isEnabled: Bool {
        filterSwitch.isOn
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Только избранное"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()

    private let filterSwitch = UISwitch()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 8
        translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, filterSwitch].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        filterSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            filterSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            filterSwitch.centerYAnchor.constraint(equalTo: centerYAnchor),
            filterSwitch.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])
    }

    @objc private func switchChanged() {
        delegate?.favoriteFilterView(self, didChangeState: filterSwitch.isOn)
    }
}
