import UIKit

final class CandleCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "CandleCollectionViewCell"

    private let candleView = CandleView()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(candleView)

        NSLayoutConstraint.activate([
            candleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            candleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            candleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            candleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(
        candle: CandleData,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) {
        candleView.configure(with: candle)
        candleView.onTap = onTap
        candleView.onLongPress = onLongPress
    }
}
