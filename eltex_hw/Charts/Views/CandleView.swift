import UIKit

final class CandleView: UIView {
    // MARK: - Properties

    private let bodyView = UIView()
    private let tailView = UIView()

    private var bodyTopConstraint: NSLayoutConstraint?
    private var bodyHeightConstraint: NSLayoutConstraint?
    private var tailTopConstraint: NSLayoutConstraint?
    private var tailBottomConstraint: NSLayoutConstraint?

    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        bodyView.translatesAutoresizingMaskIntoConstraints = false
        tailView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.layer.cornerRadius = 6
        tailView.layer.cornerRadius = 1.5

        addSubview(tailView)
        addSubview(bodyView)

        bodyTopConstraint = bodyView.topAnchor.constraint(equalTo: topAnchor, constant: 60)
        bodyHeightConstraint = bodyView.heightAnchor.constraint(equalToConstant: 70)
        tailTopConstraint = tailView.topAnchor.constraint(equalTo: topAnchor, constant: 45)
        tailBottomConstraint = tailView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -45)

        NSLayoutConstraint.activate([
            bodyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bodyView.widthAnchor.constraint(equalToConstant: 30),
            bodyTopConstraint,
            bodyHeightConstraint,

            tailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tailView.widthAnchor.constraint(equalToConstant: 3),
            tailTopConstraint,
            tailBottomConstraint
        ].compactMap { $0 })

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPress)
    }

    // MARK: - Configure

    func configure(with candle: CandleData) {
        let candleColor: UIColor = candle.isGrowing ? .systemGreen : .systemRed
        bodyView.backgroundColor = candleColor
        tailView.backgroundColor = candleColor

        let bodyBottom = candle.bodyTop + candle.bodyHeight
        bodyTopConstraint?.constant = candle.bodyTop
        bodyHeightConstraint?.constant = candle.bodyHeight
        tailTopConstraint?.constant = max(8, candle.bodyTop - candle.topTailExtra)
        tailBottomConstraint?.constant = -max(8, 220 - bodyBottom + candle.bottomTailExtra)
    }

    // MARK: - Actions

    @objc func handleTap() {
        onTap?()
    }

    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        onLongPress?()
    }
}
