import UIKit

final class P2POfferTableViewCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "P2POfferTableViewCell"

    private let cardView = UIView()
    private let sellerLabel = UILabel()
    private let rateLabel = UILabel()
    private let reserveLabel = UILabel()

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sellerLabel.text = nil
        rateLabel.text = nil
        reserveLabel.text = nil
    }

    // MARK: - Configuration

    func configure(offer: P2POffer, sourceCode: String, targetCode: String) {
        sellerLabel.text = offer.sellerName
        rateLabel.text = String(
            format: "Курс: 1 %@ = %.6f %@",
            sourceCode,
            offer.rate,
            targetCode
        )
        reserveLabel.text = String(
            format: "Резерв: %.2f %@",
            offer.reserve,
            targetCode
        )
    }
}

// MARK: - Private

private extension P2POfferTableViewCell {
    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        [cardView, sellerLabel, rateLabel, reserveLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        cardView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        sellerLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        sellerLabel.textColor = .white

        rateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        rateLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        rateLabel.numberOfLines = 0

        reserveLabel.font = .systemFont(ofSize: 13, weight: .regular)
        reserveLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        contentView.addSubview(cardView)
        cardView.addSubview(sellerLabel)
        cardView.addSubview(rateLabel)
        cardView.addSubview(reserveLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            sellerLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            sellerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            sellerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            rateLabel.topAnchor.constraint(equalTo: sellerLabel.bottomAnchor, constant: 8),
            rateLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            rateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            reserveLabel.topAnchor.constraint(equalTo: rateLabel.bottomAnchor, constant: 8),
            reserveLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            reserveLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            reserveLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }
}
