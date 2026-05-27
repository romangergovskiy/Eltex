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
        label.textColor = .white
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
            contentView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.24)
            codeLabel.textColor = .systemGray2
            contentView.layer.borderWidth = 0
            return
        }

        codeLabel.textColor = .white
        contentView.backgroundColor = isSelectedPair
            ? UIColor.systemTeal.withAlphaComponent(0.45)
            : UIColor(red: 0.18, green: 0.24, blue: 0.36, alpha: 1)
        contentView.layer.borderWidth = isSelectedPair ? 2 : 0
        contentView.layer.borderColor = isSelectedPair ? UIColor.systemTeal.cgColor : nil
    }

    func playSelectionAnimation(completion: (() -> Void)? = nil) {
        let startColor = contentView.backgroundColor
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut]) {
            self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                self.transform = .identity
                self.contentView.backgroundColor = startColor
            } completion: { _ in
                completion?()
            }
        }
    }

    // MARK: - Private

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        contentView.layer.borderColor = UIColor.clear.cgColor

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

