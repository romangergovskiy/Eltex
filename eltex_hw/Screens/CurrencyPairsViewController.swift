import UIKit

protocol CurrencyPairsViewControllerDelegate: AnyObject {
    func currencyPairsViewController(
        _ controller: CurrencyPairsViewController,
        didUpdateFirstAsset firstAsset: PairAsset,
        secondAsset: PairAsset
    )

    func currencyPairsViewControllerDidRequestFullList(
        _ controller: CurrencyPairsViewController,
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: CurrencyPairsViewController.SelectionSide
    )
}

final class CurrencyPairsViewController: UIViewController {

    // MARK: - Types

    enum Mode {
        case compact
        case full
    }

    enum SelectionSide {
        case first
        case second
    }

    // MARK: - Properties

    weak var delegate: CurrencyPairsViewControllerDelegate?

    private let mode: Mode
    private let allAssets: [PairAsset]
    private let favoritesStorageKey = "favoritePairAssets"
    private let startsWithFavoritesOnly: Bool

    private var filteredAssets: [PairAsset] = []
    private var selectedFilter: PairAssetFilter = .all
    private var favoriteCodes: Set<String> = []
    private var isFavoriteFilterEnabled = false

    private var firstAsset: PairAsset
    private var secondAsset: PairAsset
    private var selectedSide: SelectionSide

    // MARK: UI (Compact mode)

    private let compactPairContainerView = UIView()
    private let compactFirstCurrencyButton = UIButton(type: .system)
    private let compactSecondCurrencyButton = UIButton(type: .system)
    private let compactHintLabel = UILabel()
    private let allButton = UIButton(type: .system)

    // MARK: UI (Full mode)

    private let fullHeaderView = UIView()
    private let fullFirstCurrencyLabel = UILabel()
    private let fullSecondCurrencyLabel = UILabel()
    private let rateLabel = UILabel()
    private let amountTextField = UITextField()
    private let resultLabel = UILabel()
    private let timerLabel = UILabel()
    private let timerProgressView = UIProgressView(progressViewStyle: .default)

    // MARK: UI (Common)

    private let favoriteFilterView = FavoriteFilterView()
    private let filterSegmentControl = UISegmentedControl(items: ["Все", "Фиат", "Крипта"])
    private let emptyStateLabel = UILabel()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PairAssetCollectionCell.self, forCellWithReuseIdentifier: PairAssetCollectionCell.reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private var pairRate: Double = 1000.0
    private var updateTimer: Timer?
    private let updatePeriod = 5
    private var secondsLeft = 5

    // MARK: - Lifecycle

    init(
        mode: Mode,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: SelectionSide = .first,
        startsWithFavoritesOnly: Bool = false
    ) {
        self.mode = mode
        self.allAssets = allAssets
        self.firstAsset = firstAsset
        self.secondAsset = secondAsset
        self.selectedSide = selectedSide
        self.startsWithFavoritesOnly = startsWithFavoritesOnly
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadFavorites()
        if mode == .full {
            isFavoriteFilterEnabled = startsWithFavoritesOnly
        }
        setupUI()
        applySelectedFiltersAndReload()
        refreshSelectedPairUI()
        if mode == .full {
            refreshRate()
            startPriceTimer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if mode == .full {
            startPriceTimer()
        }
    }

    deinit {
        updateTimer?.invalidate()
    }
}

private extension CurrencyPairsViewController {

    // MARK: - Setup

    func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        title = mode == .compact ? "Быстрый выбор пары" : "Все валюты"
        setupNavigationBarAppearance()

        setupCompactUI()
        setupFullHeaderUI()
        setupFavoriteFilterView()
        setupFilterControl()
        setupCollectionView()
        setupEmptyStateLabel()
        setupKeyboardAccessory()
        addSubviews()
        makeConstraints()
        updateModeSpecificVisibility()
    }

    func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    func setupCompactUI() {
        compactPairContainerView.translatesAutoresizingMaskIntoConstraints = false
        compactPairContainerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        compactPairContainerView.layer.cornerRadius = 12

        [compactFirstCurrencyButton, compactSecondCurrencyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
            $0.layer.cornerRadius = 10
            $0.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        }
        compactFirstCurrencyButton.addTarget(self, action: #selector(firstSideTapped), for: .touchUpInside)
        compactSecondCurrencyButton.addTarget(self, action: #selector(secondSideTapped), for: .touchUpInside)

        compactHintLabel.translatesAutoresizingMaskIntoConstraints = false
        compactHintLabel.text = "Показываем избранные пары. Если не подходит, откройте полный список."
        compactHintLabel.textColor = .white
        compactHintLabel.font = .systemFont(ofSize: 14)
        compactHintLabel.numberOfLines = 0

        allButton.translatesAutoresizingMaskIntoConstraints = false
        allButton.setTitle("Все", for: .normal)
        allButton.setTitleColor(.white, for: .normal)
        allButton.backgroundColor = UIColor(red: 0.19, green: 0.48, blue: 0.96, alpha: 1)
        allButton.layer.cornerRadius = 10
        allButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        allButton.addTarget(self, action: #selector(allButtonTapped), for: .touchUpInside)

        compactPairContainerView.addSubview(compactFirstCurrencyButton)
        compactPairContainerView.addSubview(compactSecondCurrencyButton)
    }

    func setupFullHeaderUI() {
        fullHeaderView.translatesAutoresizingMaskIntoConstraints = false
        fullHeaderView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        fullHeaderView.layer.cornerRadius = 16

        [fullFirstCurrencyLabel, fullSecondCurrencyLabel, rateLabel, amountTextField, resultLabel, timerLabel, timerProgressView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        fullFirstCurrencyLabel.textAlignment = .center
        fullFirstCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        fullFirstCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        fullFirstCurrencyLabel.layer.cornerRadius = 8
        fullFirstCurrencyLabel.clipsToBounds = true
        fullFirstCurrencyLabel.textColor = .white
        fullFirstCurrencyLabel.isUserInteractionEnabled = true
        fullFirstCurrencyLabel.tag = 0
        fullFirstCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

        fullSecondCurrencyLabel.textAlignment = .center
        fullSecondCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        fullSecondCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        fullSecondCurrencyLabel.layer.cornerRadius = 8
        fullSecondCurrencyLabel.clipsToBounds = true
        fullSecondCurrencyLabel.textColor = .white
        fullSecondCurrencyLabel.isUserInteractionEnabled = true
        fullSecondCurrencyLabel.tag = 1
        fullSecondCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

        rateLabel.textAlignment = .center
        rateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        rateLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        rateLabel.layer.cornerRadius = 8
        rateLabel.clipsToBounds = true
        rateLabel.textColor = .white

        amountTextField.placeholder = "Введите сумму"
        amountTextField.borderStyle = .roundedRect
        amountTextField.keyboardType = .decimalPad
        amountTextField.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        amountTextField.textColor = .white
        amountTextField.attributedPlaceholder = NSAttributedString(
            string: "Введите сумму",
            attributes: [.foregroundColor: UIColor.systemGray]
        )
        amountTextField.delegate = self
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)

        resultLabel.textAlignment = .center
        resultLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        resultLabel.layer.cornerRadius = 8
        resultLabel.clipsToBounds = true
        resultLabel.font = .systemFont(ofSize: 14)
        resultLabel.textColor = .white
        resultLabel.text = "Получите: 0"

        timerLabel.textAlignment = .center
        timerLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        timerLabel.layer.cornerRadius = 8
        timerLabel.clipsToBounds = true
        timerLabel.font = .systemFont(ofSize: 12)
        timerLabel.textColor = .white
        timerLabel.text = "Обновление: 5с"

        timerProgressView.progress = 0
        timerProgressView.progressTintColor = .systemTeal
        timerProgressView.trackTintColor = .systemGray

        let firstHintLabel = UILabel()
        firstHintLabel.translatesAutoresizingMaskIntoConstraints = false
        firstHintLabel.text = "Из какой:"
        firstHintLabel.font = .systemFont(ofSize: 16)
        firstHintLabel.textColor = .white

        let secondHintLabel = UILabel()
        secondHintLabel.translatesAutoresizingMaskIntoConstraints = false
        secondHintLabel.text = "В какую:"
        secondHintLabel.font = .systemFont(ofSize: 16)
        secondHintLabel.textColor = .white

        fullHeaderView.addSubview(firstHintLabel)
        fullHeaderView.addSubview(secondHintLabel)
        fullHeaderView.addSubview(fullFirstCurrencyLabel)
        fullHeaderView.addSubview(fullSecondCurrencyLabel)
        fullHeaderView.addSubview(rateLabel)
        fullHeaderView.addSubview(amountTextField)
        fullHeaderView.addSubview(resultLabel)
        fullHeaderView.addSubview(timerLabel)
        fullHeaderView.addSubview(timerProgressView)

        NSLayoutConstraint.activate([
            firstHintLabel.leadingAnchor.constraint(equalTo: fullHeaderView.leadingAnchor, constant: 16),
            firstHintLabel.topAnchor.constraint(equalTo: fullHeaderView.topAnchor, constant: 14),
            firstHintLabel.widthAnchor.constraint(equalToConstant: 72),

            fullFirstCurrencyLabel.leadingAnchor.constraint(equalTo: firstHintLabel.trailingAnchor, constant: 12),
            fullFirstCurrencyLabel.centerYAnchor.constraint(equalTo: firstHintLabel.centerYAnchor),
            fullFirstCurrencyLabel.widthAnchor.constraint(equalToConstant: 96),
            fullFirstCurrencyLabel.heightAnchor.constraint(equalToConstant: 40),

            secondHintLabel.leadingAnchor.constraint(equalTo: fullHeaderView.leadingAnchor, constant: 16),
            secondHintLabel.topAnchor.constraint(equalTo: fullFirstCurrencyLabel.bottomAnchor, constant: 12),
            secondHintLabel.widthAnchor.constraint(equalToConstant: 72),

            fullSecondCurrencyLabel.leadingAnchor.constraint(equalTo: secondHintLabel.trailingAnchor, constant: 12),
            fullSecondCurrencyLabel.centerYAnchor.constraint(equalTo: secondHintLabel.centerYAnchor),
            fullSecondCurrencyLabel.widthAnchor.constraint(equalToConstant: 96),
            fullSecondCurrencyLabel.heightAnchor.constraint(equalToConstant: 40),

            amountTextField.leadingAnchor.constraint(equalTo: fullHeaderView.leadingAnchor, constant: 16),
            amountTextField.topAnchor.constraint(equalTo: fullSecondCurrencyLabel.bottomAnchor, constant: 10),
            amountTextField.widthAnchor.constraint(equalToConstant: 120),
            amountTextField.heightAnchor.constraint(equalToConstant: 35),

            resultLabel.leadingAnchor.constraint(equalTo: amountTextField.trailingAnchor, constant: 12),
            resultLabel.centerYAnchor.constraint(equalTo: amountTextField.centerYAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: fullHeaderView.trailingAnchor, constant: -16),
            resultLabel.heightAnchor.constraint(equalToConstant: 35),

            rateLabel.leadingAnchor.constraint(equalTo: fullHeaderView.leadingAnchor, constant: 16),
            rateLabel.trailingAnchor.constraint(equalTo: fullHeaderView.trailingAnchor, constant: -16),
            rateLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 6),
            rateLabel.heightAnchor.constraint(equalToConstant: 30),

            timerLabel.leadingAnchor.constraint(equalTo: fullHeaderView.leadingAnchor, constant: 16),
            timerLabel.trailingAnchor.constraint(equalTo: fullHeaderView.trailingAnchor, constant: -16),
            timerLabel.bottomAnchor.constraint(equalTo: fullHeaderView.bottomAnchor, constant: -12),
            timerLabel.heightAnchor.constraint(equalToConstant: 28),

            timerProgressView.leadingAnchor.constraint(equalTo: fullHeaderView.leadingAnchor, constant: 16),
            timerProgressView.trailingAnchor.constraint(equalTo: fullHeaderView.trailingAnchor, constant: -16),
            timerProgressView.bottomAnchor.constraint(equalTo: timerLabel.topAnchor, constant: -6),
            timerProgressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    func setupFavoriteFilterView() {
        favoriteFilterView.delegate = self
        if mode == .full {
            favoriteFilterView.setEnabled(isFavoriteFilterEnabled)
        }
    }

    func setupFilterControl() {
        filterSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        filterSegmentControl.selectedSegmentIndex = PairAssetFilter.all.rawValue
        filterSegmentControl.selectedSegmentTintColor = .systemTeal
        filterSegmentControl.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        filterSegmentControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        filterSegmentControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        filterSegmentControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }

    func setupCollectionView() {
        collectionView.layer.cornerRadius = 16
        collectionView.backgroundColor = UIColor(red: 0.1, green: 0.14, blue: 0.24, alpha: 1)
    }

    func setupEmptyStateLabel() {
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "Список пуст"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
    }

    func setupKeyboardAccessory() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barTintColor = UIColor(red: 0.1, green: 0.14, blue: 0.24, alpha: 1)
        toolbar.tintColor = .white
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton]
        amountTextField.inputAccessoryView = toolbar
    }

    func addSubviews() {
        view.addSubview(compactPairContainerView)
        view.addSubview(compactHintLabel)
        view.addSubview(allButton)
        view.addSubview(fullHeaderView)
        view.addSubview(favoriteFilterView)
        view.addSubview(filterSegmentControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            compactPairContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            compactPairContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            compactPairContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            compactPairContainerView.heightAnchor.constraint(equalToConstant: 92),

            compactFirstCurrencyButton.leadingAnchor.constraint(equalTo: compactPairContainerView.leadingAnchor, constant: 14),
            compactFirstCurrencyButton.centerYAnchor.constraint(equalTo: compactPairContainerView.centerYAnchor),
            compactFirstCurrencyButton.widthAnchor.constraint(equalToConstant: 120),
            compactFirstCurrencyButton.heightAnchor.constraint(equalToConstant: 44),

            compactSecondCurrencyButton.trailingAnchor.constraint(equalTo: compactPairContainerView.trailingAnchor, constant: -14),
            compactSecondCurrencyButton.centerYAnchor.constraint(equalTo: compactPairContainerView.centerYAnchor),
            compactSecondCurrencyButton.widthAnchor.constraint(equalToConstant: 120),
            compactSecondCurrencyButton.heightAnchor.constraint(equalToConstant: 44),

            compactHintLabel.topAnchor.constraint(equalTo: compactPairContainerView.bottomAnchor, constant: 10),
            compactHintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            compactHintLabel.trailingAnchor.constraint(equalTo: allButton.leadingAnchor, constant: -10),

            allButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            allButton.centerYAnchor.constraint(equalTo: compactHintLabel.centerYAnchor),
            allButton.widthAnchor.constraint(equalToConstant: 68),
            allButton.heightAnchor.constraint(equalToConstant: 36),

            fullHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            fullHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            fullHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            fullHeaderView.heightAnchor.constraint(equalToConstant: 220),

            favoriteFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            favoriteFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            favoriteFilterView.heightAnchor.constraint(equalToConstant: 44),

            filterSegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSegmentControl.heightAnchor.constraint(equalToConstant: 32),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -16)
        ])

        if mode == .compact {
            favoriteFilterView.topAnchor.constraint(equalTo: compactPairContainerView.bottomAnchor, constant: 10).isActive = true
            filterSegmentControl.topAnchor.constraint(equalTo: favoriteFilterView.bottomAnchor, constant: 10).isActive = true
            collectionView.topAnchor.constraint(equalTo: compactHintLabel.bottomAnchor, constant: 10).isActive = true
        } else {
            favoriteFilterView.topAnchor.constraint(equalTo: fullHeaderView.bottomAnchor, constant: 10).isActive = true
            filterSegmentControl.topAnchor.constraint(equalTo: favoriteFilterView.bottomAnchor, constant: 10).isActive = true
            collectionView.topAnchor.constraint(equalTo: filterSegmentControl.bottomAnchor, constant: 10).isActive = true
        }
    }

    func updateModeSpecificVisibility() {
        let isCompact = mode == .compact
        compactPairContainerView.isHidden = !isCompact
        compactHintLabel.isHidden = !isCompact
        allButton.isHidden = !isCompact

        fullHeaderView.isHidden = isCompact
        favoriteFilterView.isHidden = isCompact
        filterSegmentControl.isHidden = isCompact
    }
}

private extension CurrencyPairsViewController {

    // MARK: - Actions

    @objc func doneTapped() {
        amountTextField.resignFirstResponder()
    }

    @objc func selectedCurrencyTapped(_ sender: UITapGestureRecognizer) {
        guard mode == .full else { return }
        guard let label = sender.view as? UILabel else { return }
        selectedSide = label.tag == 0 ? .first : .second
        refreshSelectedPairUI()
    }

    @objc func firstSideTapped() {
        selectedSide = .first
        refreshSelectedPairUI()
    }

    @objc func secondSideTapped() {
        selectedSide = .second
        refreshSelectedPairUI()
    }

    @objc func allButtonTapped() {
        delegate?.currencyPairsViewControllerDidRequestFullList(
            self,
            firstAsset: firstAsset,
            secondAsset: secondAsset,
            selectedSide: selectedSide
        )
    }

    @objc func filterChanged() {
        selectedFilter = PairAssetFilter(rawValue: filterSegmentControl.selectedSegmentIndex) ?? .all
        applySelectedFiltersAndReload()
    }

    @objc func amountChanged() {
        if let text = amountTextField.text, text.contains("-") || text.contains("−") {
            amountTextField.text = text
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "−", with: "")
        }
        refreshConvertedAmount()
    }

    @objc func timerTick() {
        secondsLeft -= 1
        if secondsLeft <= 0 {
            refreshRate()
            secondsLeft = updatePeriod
        }
        timerLabel.text = "Обновление: \(secondsLeft)с"
        let elapsed = Float(updatePeriod - secondsLeft)
        timerProgressView.progress = min(max(elapsed / Float(updatePeriod), 0), 1)
    }
}

private extension CurrencyPairsViewController {

    // MARK: - Business Logic

    func applySelectedFiltersAndReload() {
        switch mode {
        case .compact:
            filteredAssets = compactSource()
        case .full:
            filteredAssets = fullSource()
        }
        updateEmptyState()
        collectionView.reloadData()
    }

    func compactSource() -> [PairAsset] {
        allAssets
            .filter { favoriteCodes.contains($0.code) }
            .sorted { $0.code < $1.code }
    }

    func fullSource() -> [PairAsset] {
        let typeFiltered: [PairAsset]
        switch selectedFilter {
        case .all:
            typeFiltered = allAssets
        case .fiat:
            typeFiltered = allAssets.filter { $0.category == .fiat }
        case .crypto:
            typeFiltered = allAssets.filter { $0.category == .crypto }
        }

        if isFavoriteFilterEnabled {
            return typeFiltered.filter { favoriteCodes.contains($0.code) }
        }
        return typeFiltered
    }

    func updateEmptyState() {
        let isEmpty = filteredAssets.isEmpty
        if mode == .full && isFavoriteFilterEnabled {
            emptyStateLabel.text = "В избранном пока пусто"
        } else {
            emptyStateLabel.text = "Список пуст"
        }
        emptyStateLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    func refreshSelectedPairUI() {
        compactFirstCurrencyButton.setTitle("Из: \(firstAsset.code)", for: .normal)
        compactSecondCurrencyButton.setTitle("В: \(secondAsset.code)", for: .normal)
        fullFirstCurrencyLabel.text = firstAsset.code
        fullSecondCurrencyLabel.text = secondAsset.code

        if selectedSide == .first {
            compactFirstCurrencyButton.layer.borderWidth = 2
            compactFirstCurrencyButton.layer.borderColor = UIColor.systemTeal.cgColor
            compactSecondCurrencyButton.layer.borderWidth = 0

            fullFirstCurrencyLabel.layer.borderWidth = 2
            fullFirstCurrencyLabel.layer.borderColor = UIColor.systemTeal.cgColor
            fullFirstCurrencyLabel.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)
            fullSecondCurrencyLabel.layer.borderWidth = 0
            fullSecondCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        } else {
            compactSecondCurrencyButton.layer.borderWidth = 2
            compactSecondCurrencyButton.layer.borderColor = UIColor.systemTeal.cgColor
            compactFirstCurrencyButton.layer.borderWidth = 0

            fullSecondCurrencyLabel.layer.borderWidth = 2
            fullSecondCurrencyLabel.layer.borderColor = UIColor.systemTeal.cgColor
            fullSecondCurrencyLabel.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)
            fullFirstCurrencyLabel.layer.borderWidth = 0
            fullFirstCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        }
        collectionView.reloadData()
    }

    func selectAsset(_ asset: PairAsset) {
        if selectedSide == .first {
            guard asset.code != secondAsset.code else {
                showError("Валюты в паре должны быть разными")
                return
            }
            firstAsset = asset
        } else {
            guard asset.code != firstAsset.code else {
                showError("Валюты в паре должны быть разными")
                return
            }
            secondAsset = asset
        }

        refreshSelectedPairUI()
        if mode == .full {
            refreshRate()
        }
        delegate?.currencyPairsViewController(self, didUpdateFirstAsset: firstAsset, secondAsset: secondAsset)
    }

    func isDisabled(_ asset: PairAsset) -> Bool {
        if selectedSide == .first {
            return asset.code == secondAsset.code
        }
        return asset.code == firstAsset.code
    }

    func refreshRate() {
        let firstCategory = firstAsset.category
        let secondCategory = secondAsset.category

        if firstCategory == .fiat && secondCategory == .crypto {
            pairRate = Double.random(in: 300...90000)
        } else if firstCategory == .crypto && secondCategory == .fiat {
            pairRate = Double.random(in: 0.00001...0.01)
        } else {
            pairRate = Double.random(in: 0.1...5000)
        }

        rateLabel.text = String(
            format: "Курс: 1 %@ = %.4f %@",
            secondAsset.code,
            pairRate,
            firstAsset.code
        )
        refreshConvertedAmount()
    }

    func refreshConvertedAmount() {
        let input = amountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? ""
        guard let amountInFirst = Double(input), pairRate > 0 else {
            resultLabel.text = "Получите: 0 \(secondAsset.code)"
            return
        }

        let amountInSecond = amountInFirst / pairRate
        resultLabel.text = String(format: "Получите: %.6f %@", amountInSecond, secondAsset.code)
    }

    func startPriceTimer() {
        updateTimer?.invalidate()
        secondsLeft = updatePeriod
        timerLabel.text = "Обновление: \(secondsLeft)с"
        timerProgressView.progress = 0
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    func loadFavorites() {
        guard let saved = UserDefaults.standard.array(forKey: favoritesStorageKey) as? [String] else { return }
        favoriteCodes = Set(saved)
    }

    func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteCodes), forKey: favoritesStorageKey)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension CurrencyPairsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let padding: CGFloat = 12
        let spacing: CGFloat = 10
        let itemsInRow: CGFloat = 4
        let totalPadding = padding * 2
        let totalSpacing = spacing * (itemsInRow - 1)
        let availableWidth = collectionView.bounds.width - totalPadding - totalSpacing
        let width = floor(availableWidth / itemsInRow)
        layout.itemSize = CGSize(width: width, height: 56)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PairAssetCollectionCell.reuseIdentifier,
            for: indexPath
        ) as? PairAssetCollectionCell else {
            return UICollectionViewCell()
        }

        let asset = filteredAssets[indexPath.item]
        let selected = asset.code == firstAsset.code || asset.code == secondAsset.code
        cell.configure(
            asset: asset,
            isDisabled: isDisabled(asset),
            isSelectedPair: selected,
            isFavorite: favoriteCodes.contains(asset.code)
        )
        cell.delegate = self
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = filteredAssets[indexPath.item]

        if isDisabled(asset) {
            selectAsset(asset)
            return
        }

        if let cell = collectionView.cellForItem(at: indexPath) as? PairAssetCollectionCell {
            cell.playSelectionAnimation { [weak self] in
                self?.selectAsset(asset)
            }
        } else {
            selectAsset(asset)
        }
    }
}

extension CurrencyPairsViewController: PairAssetCollectionCellDelegate {
    // MARK: - PairAssetCollectionCellDelegate

    func pairAssetCollectionCell(_ cell: PairAssetCollectionCell, didTapFavoriteFor code: String, isFavorite: Bool) {
        if isFavorite {
            favoriteCodes.insert(code)
        } else {
            favoriteCodes.remove(code)
        }
        saveFavorites()
        applySelectedFiltersAndReload()
    }
}

extension CurrencyPairsViewController: FavoriteFilterViewDelegate {
    // MARK: - FavoriteFilterViewDelegate

    func favoriteFilterView(_ view: FavoriteFilterView, didChangeState isEnabled: Bool) {
        isFavoriteFilterEnabled = isEnabled
        applySelectedFiltersAndReload()
    }
}

extension CurrencyPairsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.contains("-") || string.contains("−") {
            return false
        }
        return true
    }
}
