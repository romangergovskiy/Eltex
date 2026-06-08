import UIKit

// MARK: - FeedbackDirection

enum FeedbackDirection: String, CaseIterable, Hashable {
    case withdrawalIssue
    case botIssue
    case p2pSellerNotResponding
    case depositIssue
    case other

    var title: String {
        switch self {
        case .withdrawalIssue:
            return "Проблема с выводом"
        case .botIssue:
            return "Проблема с ботом"
        case .p2pSellerNotResponding:
            return "P2P продавец не отвечает"
        case .depositIssue:
            return "Проблема с пополнением"
        case .other:
            return "Другое"
        }
    }
}

// MARK: - FeedbackDirectionSelectionViewDelegate

protocol FeedbackDirectionSelectionViewDelegate: AnyObject {
    func feedbackDirectionSelectionView(
        _ view: FeedbackDirectionSelectionView,
        didChangeSelection directions: Set<FeedbackDirection>
    )
}

// MARK: - FeedbackDirectionSelectionView

final class FeedbackDirectionSelectionView: UIView {
    enum Layout {
        static let titleHeight: CGFloat = 20
        static let titleBottomSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 44
        static let buttonSpacing: CGFloat = 8
        static let optionsCount = FeedbackDirection.allCases.count

        static let totalHeight: CGFloat = titleHeight
            + titleBottomSpacing
            + buttonHeight * CGFloat(optionsCount)
            + buttonSpacing * CGFloat(optionsCount - 1)
    }

    weak var delegate: FeedbackDirectionSelectionViewDelegate?

    private(set) var selectedDirections: Set<FeedbackDirection> = []

    func setSelectedDirections(_ directions: Set<FeedbackDirection>) {
        guard directions != selectedDirections else { return }
        selectedDirections = directions
        FeedbackDirection.allCases.forEach(updateAppearance)
    }

    private var optionButtons: [FeedbackDirection: UIButton] = [:]

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Направление обращения"
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        [titleLabel, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        FeedbackDirection.allCases.enumerated().forEach { index, direction in
            let button = makeOptionButton(for: direction, tag: index)
            optionButtons[direction] = button
            stackView.addArrangedSubview(button)
            updateAppearance(direction)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeOptionButton(for direction: FeedbackDirection, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = tag
        button.setTitle(direction.title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.heightAnchor.constraint(equalToConstant: Layout.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(optionTapped), for: .touchUpInside)
        return button
    }

    private func updateAppearance(_ direction: FeedbackDirection) {
        guard let button = optionButtons[direction] else { return }
        let isSelected = selectedDirections.contains(direction)
        button.backgroundColor = isSelected ? .systemBlue : .secondarySystemBackground
        button.setTitleColor(isSelected ? .white : .label, for: .normal)
        button.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.separator).cgColor
    }

    @objc private func optionTapped(_ sender: UIButton) {
        let direction = FeedbackDirection.allCases[sender.tag]
        if selectedDirections.contains(direction) {
            selectedDirections.remove(direction)
        } else {
            selectedDirections.insert(direction)
        }
        updateAppearance(direction)
        delegate?.feedbackDirectionSelectionView(self, didChangeSelection: selectedDirections)
    }
}
