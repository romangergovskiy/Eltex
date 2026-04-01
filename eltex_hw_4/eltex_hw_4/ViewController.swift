import UIKit

// MARK: - ViewController

final class ViewController: UIViewController {

    private let headerImageView = UIImageView()
    private let containerView = UIView()
    private let filterStack = UIStackView()
    private let runButton = UIButton(type: .system)
    private let outputTextView = UITextView()
    private let botSwitch = UISwitch()
    private let emptyStateLabel = UILabel()

    private var isFirstRun = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - Setup

private extension ViewController {

    func setupUI() {
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        runButton.translatesAutoresizingMaskIntoConstraints = false
        outputTextView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = .darkGray

        setupHeader()
        setupContainer()
        setupFilter()
        setupRunButton()
        setupOutput()
        setupEmptyState()

        addSubviews()
        makeConstraints()
    }

    func setupHeader() {
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.layer.cornerRadius = 10
        headerImageView.image = UIImage(named: "fordz")
    }

    func setupContainer() {
        containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        containerView.layer.cornerRadius = 10
    }

    func setupFilter() {
        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterStack.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = "Торговый бот"

        filterStack.addArrangedSubview(titleLabel)
        filterStack.addArrangedSubview(botSwitch)
        filterStack.addArrangedSubview(UIView())
    }

    func setupRunButton() {
        runButton.setTitle("Начать торговлю", for: .normal)
        runButton.setTitleColor(.black, for: .normal)
        runButton.backgroundColor = .systemBlue
        runButton.layer.cornerRadius = 12
        runButton.contentHorizontalAlignment = .center
        runButton.contentVerticalAlignment = .center
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
    }

    func setupOutput() {
        outputTextView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        outputTextView.font = .systemFont(ofSize: 16)
        outputTextView.layer.cornerRadius = 10
        outputTextView.isEditable = false
        outputTextView.isScrollEnabled = true
    }

    func setupEmptyState() {
        emptyStateLabel.text = "Нет данных"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = false
    }

    func addSubviews() {
        view.addSubview(headerImageView)
        view.addSubview(containerView)
        view.addSubview(outputTextView)
        view.addSubview(emptyStateLabel)

        containerView.addSubview(filterStack)
        containerView.addSubview(runButton)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            // Header
            NSLayoutConstraint(item: headerImageView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: headerImageView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: headerImageView, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: headerImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 160),

            // Container
            NSLayoutConstraint(item: containerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: containerView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal, toItem: headerImageView, attribute: .bottom, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 180),

            // Filter stack
            NSLayoutConstraint(item: filterStack, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: filterStack, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -10),
            NSLayoutConstraint(item: filterStack, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: filterStack, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40),

            // Run button
            NSLayoutConstraint(item: runButton, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: runButton, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: runButton, attribute: .top, relatedBy: .equal, toItem: filterStack, attribute: .bottom, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: runButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50),

            // Output
            NSLayoutConstraint(item: outputTextView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: outputTextView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: outputTextView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: outputTextView, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: -20),

            // Empty state
            NSLayoutConstraint(item: emptyStateLabel, attribute: .centerX, relatedBy: .equal, toItem: outputTextView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: emptyStateLabel, attribute: .centerY, relatedBy: .equal, toItem: outputTextView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: emptyStateLabel, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: view.safeAreaLayoutGuide, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: emptyStateLabel, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: view.safeAreaLayoutGuide, attribute: .trailing, multiplier: 1, constant: -20),
        ])
    }
}

// MARK: - Actions

private extension ViewController {
    
    @objc func runTapped() {
        outputTextView.text = ""

        if isFirstRun {
            emptyStateLabel.isHidden = true
            isFirstRun = false
        }

        let trader = Trader(balance: 10000, currency: .usd)
        let bot = TradingBot(trader: trader)

        bot.onUpdate = { message in
            self.appendText(message)
        }

        bot.startTrading()
    }


    func appendText(_ text: String) {
        outputTextView.text += text + "\n"
        let range = NSRange(location: max(outputTextView.text.count - 1, 0), length: 0)
        outputTextView.scrollRangeToVisible(range)
    }
}
