//
//  PairAssetCollectionCell.swift
//  eltex_dz_8
//
//  Created by Роман Герговский on 03.04.2026.
//

import UIKit

// MARK: - PairAssetCollectionCellDelegate

protocol PairAssetCollectionCellDelegate: AnyObject {
    func pairAssetCollectionCell(_ cell: PairAssetCollectionCell, didTapFavoriteFor code: String, isFavorite: Bool)
}

// MARK: - PairAssetCollectionCell

final class PairAssetCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "PairAssetCollectionCell"

    weak var delegate: PairAssetCollectionCellDelegate?

    private let codeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 15)
        return label
    }()

    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .systemYellow
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()

    private var currentCode = ""
    private var currentFavoriteState = false

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentCode = ""
        currentFavoriteState = false
        updateFavoriteIcon()
    }

    // MARK: - Configuration

    func configure(asset: PairAsset, isDisabled: Bool, isSelectedPair: Bool, isFavorite: Bool) {
        currentCode = asset.code
        currentFavoriteState = isFavorite
        updateFavoriteIcon()
        codeLabel.text = asset.code

        if isDisabled {
            contentView.backgroundColor = .systemGray3
            codeLabel.textColor = .systemGray
            contentView.layer.borderWidth = 0
            return
        }

        codeLabel.textColor = .black
        contentView.backgroundColor = isSelectedPair ? .systemGreen : .lightGray
        contentView.layer.borderWidth = isSelectedPair ? 2 : 0
        contentView.layer.borderColor = isSelectedPair ? UIColor.systemBlue.cgColor : nil
    }

    // MARK: - Private

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(codeLabel)
        contentView.addSubview(favoriteButton)

        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            favoriteButton.widthAnchor.constraint(equalToConstant: 16),
            favoriteButton.heightAnchor.constraint(equalToConstant: 16),

            codeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func updateFavoriteIcon() {
        let symbolName = currentFavoriteState ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: symbolName), for: .normal)
    }

    @objc private func favoriteTapped() {
        guard !currentCode.isEmpty else { return }
        currentFavoriteState.toggle()
        updateFavoriteIcon()
        delegate?.pairAssetCollectionCell(self, didTapFavoriteFor: currentCode, isFavorite: currentFavoriteState)
    }
}

