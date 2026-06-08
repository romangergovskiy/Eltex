import UIKit

struct SellerProfile {
    let name: String
    let completionRate: Int
    let ordersCount: Int
    let averageReleaseMinutes: Int
    let verifiedSince: String
    let aboutText: String
}

final class SellerInfoViewController: UIViewController {
    private let profile: SellerProfile

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let completionLabel = UILabel()
    private let ordersLabel = UILabel()
    private let releaseLabel = UILabel()
    private let verifiedLabel = UILabel()
    private let aboutLabel = UILabel()

    init(profile: SellerProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        render()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        title = "О продавце"

        [cardView, nameLabel, completionLabel, ordersLabel, releaseLabel, verifiedLabel, aboutLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        cardView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .white

        [completionLabel, ordersLabel, releaseLabel, verifiedLabel].forEach {
            $0.font = .systemFont(ofSize: 16, weight: .medium)
            $0.textColor = UIColor.white.withAlphaComponent(0.95)
            $0.numberOfLines = 0
        }

        aboutLabel.font = .systemFont(ofSize: 15, weight: .regular)
        aboutLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        aboutLabel.numberOfLines = 0

        view.addSubview(cardView)
        [nameLabel, completionLabel, ordersLabel, releaseLabel, verifiedLabel, aboutLabel].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            completionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            completionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            completionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            ordersLabel.topAnchor.constraint(equalTo: completionLabel.bottomAnchor, constant: 10),
            ordersLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            ordersLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            releaseLabel.topAnchor.constraint(equalTo: ordersLabel.bottomAnchor, constant: 10),
            releaseLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            releaseLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            verifiedLabel.topAnchor.constraint(equalTo: releaseLabel.bottomAnchor, constant: 10),
            verifiedLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            verifiedLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            aboutLabel.topAnchor.constraint(equalTo: verifiedLabel.bottomAnchor, constant: 16),
            aboutLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            aboutLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            aboutLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    private func render() {
        nameLabel.text = profile.name
        completionLabel.text = "Успешных сделок: \(profile.completionRate)%"
        ordersLabel.text = "Количество ордеров: \(profile.ordersCount)"
        releaseLabel.text = "Среднее время подтверждения: \(profile.averageReleaseMinutes) мин"
        verifiedLabel.text = "Верифицирован с: \(profile.verifiedSince)"
        aboutLabel.text = profile.aboutText
    }
}
