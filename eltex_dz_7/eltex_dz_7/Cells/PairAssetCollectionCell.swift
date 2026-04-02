import UIKit

final class PairAssetCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "PairAssetCollectionCell"

    private let codeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 15)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(codeLabel)

        NSLayoutConstraint.activate([
            codeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(asset: PairAsset, isDisabled: Bool, isSelectedPair: Bool) {
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
}

