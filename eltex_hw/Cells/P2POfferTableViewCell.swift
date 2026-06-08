import UIKit

final class P2POfferTableViewCell: UITableViewCell {
    static let reuseIdentifier = "P2POfferTableViewCell"
    var onDetailsTap: (() -> Void)?

    private let cardView = UIView()
    private let sellerLabel = UILabel()
    private let rateTitleLabel = UILabel()
    private let rateValueLabel = UILabel()
    private let reserveTitleLabel = UILabel()
    private let reserveValueLabel = UILabel()
    private let verticalSeparator = UIView()
    private let detailsButton = UIButton(type: .system)
    private let contentStack = UIStackView()
    private let gradientLayer = CAGradientLayer()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDetailsTap = nil
        sellerLabel.text = nil
        rateValueLabel.text = nil
        reserveValueLabel.text = nil
    }

    func configure(offer: P2POffer, sourceCode: String, targetCode: String) {
        sellerLabel.text = offer.sellerName
        rateValueLabel.text = String(
            format: "1 %@ = %.6f %@",
            sourceCode,
            offer.rate,
            targetCode
        )
        reserveValueLabel.text = String(
            format: "%.2f %@",
            offer.reserve,
            targetCode
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = cardView.bounds
    }
}

private extension P2POfferTableViewCell {
    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        [
            cardView,
            sellerLabel,
            rateTitleLabel,
            rateValueLabel,
            reserveTitleLabel,
            reserveValueLabel,
            verticalSeparator,
            detailsButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        cardView.layer.cornerRadius = 18
        cardView.layer.masksToBounds = true
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(red: 0.26, green: 0.4, blue: 0.72, alpha: 0.45).cgColor
        gradientLayer.colors = [
            UIColor(red: 0.02, green: 0.09, blue: 0.23, alpha: 1).cgColor,
            UIColor(red: 0.01, green: 0.16, blue: 0.45, alpha: 1).cgColor,
            UIColor(red: 0.01, green: 0.08, blue: 0.24, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        cardView.layer.insertSublayer(gradientLayer, at: 0)

        sellerLabel.font = .systemFont(ofSize: 30, weight: .bold)
        sellerLabel.textColor = .white
        sellerLabel.adjustsFontSizeToFitWidth = true
        sellerLabel.minimumScaleFactor = 0.8

        rateTitleLabel.text = "Курс"
        rateTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        rateTitleLabel.textColor = UIColor.white.withAlphaComponent(0.86)

        rateValueLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        rateValueLabel.textColor = .white
        rateValueLabel.adjustsFontSizeToFitWidth = true
        rateValueLabel.minimumScaleFactor = 0.45

        reserveTitleLabel.text = "Резерв"
        reserveTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        reserveTitleLabel.textColor = UIColor.white.withAlphaComponent(0.86)

        reserveValueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        reserveValueLabel.textColor = UIColor(red: 0.32, green: 0.62, blue: 1, alpha: 1)
        reserveValueLabel.adjustsFontSizeToFitWidth = true
        reserveValueLabel.minimumScaleFactor = 0.45

        verticalSeparator.backgroundColor = UIColor.white.withAlphaComponent(0.22)

        var detailsConfig = UIButton.Configuration.plain()
        detailsConfig.title = "Подробнее"
        detailsConfig.baseForegroundColor = .white
        detailsConfig.image = UIImage(systemName: "chevron.right")
        detailsConfig.imagePlacement = .trailing
        detailsConfig.imagePadding = 8
        detailsConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        detailsButton.configuration = detailsConfig
        detailsButton.configurationUpdateHandler = { button in
            var updated = button.configuration
            let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            updated?.attributedTitle = AttributedString(
                "Подробнее",
                attributes: AttributeContainer([.font: font])
            )
            button.configuration = updated
        }
        detailsButton.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        detailsButton.layer.cornerRadius = 20
        detailsButton.layer.borderWidth = 1
        detailsButton.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        detailsButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        detailsButton.addTarget(self, action: #selector(detailsTapped), for: .touchUpInside)

        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(rateTitleLabel)
        contentStack.addArrangedSubview(rateValueLabel)

        let reserveStack = UIStackView(arrangedSubviews: [reserveTitleLabel, reserveValueLabel])
        reserveStack.axis = .vertical
        reserveStack.spacing = 6
        reserveStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(sellerLabel)
        cardView.addSubview(contentStack)
        cardView.addSubview(verticalSeparator)
        cardView.addSubview(reserveStack)
        cardView.addSubview(detailsButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.heightAnchor.constraint(equalToConstant: 190),

            sellerLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 22),
            sellerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            sellerLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -24),

            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            contentStack.topAnchor.constraint(equalTo: sellerLabel.bottomAnchor, constant: 20),
            contentStack.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.45),

            verticalSeparator.leadingAnchor.constraint(equalTo: contentStack.trailingAnchor, constant: 18),
            verticalSeparator.topAnchor.constraint(equalTo: contentStack.topAnchor, constant: 4),
            verticalSeparator.bottomAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: -4),
            verticalSeparator.widthAnchor.constraint(equalToConstant: 1),

            reserveStack.leadingAnchor.constraint(equalTo: verticalSeparator.trailingAnchor, constant: 18),
            reserveStack.topAnchor.constraint(equalTo: contentStack.topAnchor),
            reserveStack.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -24),

            detailsButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            detailsButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18),
            detailsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc
    func detailsTapped() {
        onDetailsTap?()
    }
}
