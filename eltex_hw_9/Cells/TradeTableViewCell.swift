import UIKit

final class TradeTableViewCell: UITableViewCell {

    static let reuseIdentifier = "TradeTableViewCell"

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let detailsContainer = UIView()
    private let resultLabel = UILabel()
    private let balanceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        priceLabel.isHidden = false
        detailsContainer.isHidden = false
        priceLabel.text = nil
        resultLabel.text = nil
        balanceLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with trade: TradeRecord) {
        titleLabel.text = "#\(trade.index) • \(trade.action.title)"
        switch trade.action {
        case .buy:
            setupActionStyle(titleColor: .systemGreen, cardColor: UIColor.systemGreen.withAlphaComponent(0.12), trade: trade)
        case .sell:
            setupActionStyle(titleColor: .systemRed, cardColor: UIColor.systemRed.withAlphaComponent(0.12), trade: trade)
        case .ignore:
            titleLabel.textColor = .systemYellow
            cardView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
            priceLabel.isHidden = true
            detailsContainer.isHidden = true
            priceLabel.text = nil
            resultLabel.text = nil
            balanceLabel.text = nil
        }

        if let result = trade.tradeResult {
            detailsContainer.isHidden = false
            resultLabel.text = "Результат: \(formattedResult(result))"
            balanceLabel.text = "Баланс: \(trade.balanceAfter.formatted)"
        } else {
            detailsContainer.isHidden = true
        }
    }
}

// MARK: - Private
private extension TradeTableViewCell {

    func setupActionStyle(titleColor: UIColor, cardColor: UIColor, trade: TradeRecord) {
        titleLabel.textColor = titleColor
        cardView.backgroundColor = cardColor
        priceLabel.isHidden = false
        detailsContainer.isHidden = false
        priceLabel.text = "Цена: \(trade.previousPrice.formatted) → \(trade.currentPrice.formatted)"
    }

    func formattedResult(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(value.formatted)"
    }

    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        [cardView, titleLabel, priceLabel, detailsContainer, resultLabel, balanceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(detailsContainer)
        detailsContainer.addSubview(resultLabel)
        detailsContainer.addSubview(balanceLabel)

        cardView.layer.cornerRadius = 12

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        priceLabel.font = .systemFont(ofSize: 14, weight: .regular)
        resultLabel.font = .systemFont(ofSize: 14, weight: .medium)
        balanceLabel.font = .systemFont(ofSize: 14, weight: .regular)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            priceLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            priceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            detailsContainer.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 8),
            detailsContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            detailsContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            detailsContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),

            resultLabel.topAnchor.constraint(equalTo: detailsContainer.topAnchor),
            resultLabel.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),

            balanceLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 4),
            balanceLabel.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            balanceLabel.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            balanceLabel.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor)
        ])
    }
}

