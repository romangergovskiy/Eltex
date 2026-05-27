import UIKit

final class TradeTableViewCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "TradeTableViewCell"

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let startLabel = UILabel()
    private let endLabel = UILabel()

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
        titleLabel.text = nil
        startLabel.text = nil
        endLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with result: BotDayResult) {
        let pairParts = result.pairCode.split(separator: "-").map(String.init)
        let base = pairParts.first ?? "BASE"
        let quote = pairParts.count > 1 ? pairParts[1] : result.quoteCurrency

        let incomeSign = result.income >= 0 ? "+" : ""
        titleLabel.text = "\(result.botName) (\(result.pairCode)), day = \(result.day), income = \(incomeSign)\(result.income.formatted) \(result.quoteCurrency)"
        startLabel.text = "Start: \(base)=\(result.startBalances[base, default: 0].formatted), \(quote)=\(result.startBalances[quote, default: 0].formatted)"
        endLabel.text = "End: \(base)=\(result.endBalances[base, default: 0].formatted), \(quote)=\(result.endBalances[quote, default: 0].formatted)"
        titleLabel.textColor = .white
        cardView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
    }

    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        [cardView, titleLabel, startLabel, endLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(startLabel)
        cardView.addSubview(endLabel)

        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        startLabel.font = .systemFont(ofSize: 12, weight: .regular)
        endLabel.font = .systemFont(ofSize: 12, weight: .regular)
        titleLabel.numberOfLines = 0
        startLabel.numberOfLines = 1
        endLabel.numberOfLines = 1
        startLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        endLabel.textColor = UIColor.white.withAlphaComponent(0.9)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            startLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            startLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            startLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            endLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 4),
            endLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            endLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            endLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10)
        ])
    }
}

