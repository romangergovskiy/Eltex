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

    enum Mode {
        case compact
        case full
    }

    enum SelectionSide {
        case first
        case second
    }

    weak var delegate: CurrencyPairsViewControllerDelegate?

    private let mode: Mode
    private let allAssets: [PairAsset]
    private let favoritesStorageKey = "favoritePairAssets"
    private let compactFallbackAssets: [PairAsset]
    private let startsWithFavoritesOnly: Bool

    private var filteredAssets: [PairAsset] = []
    private var selectedFilter: PairAssetFilter = .all
    private var favoriteCodes: Set<String> = []
    private var isFavoriteFilterEnabled = false

    private var firstAsset: PairAsset
    private var secondAsset: PairAsset
    private var selectedSide: SelectionSide

    // compact mode
    private let compactPairContainerView = UIView()
    private let compactFirstCurrencyButton = UIButton(type: .system)
    private let compactSecondCurrencyButton = UIButton(type: .system)
    private let compactHintLabel = UILabel()
    private let allButton = UIButton(type: .system)

    // full mode (dz8-like header)
    private let fullHeaderView = UIView()
    private let fullFirstCurrencyLabel = UILabel()
    private let fullSecondCurrencyLabel = UILabel()
    private let rateLabel = UILabel()
    private let amountTextField = UITextField()
    private let resultLabel = UILabel()
    private let timerLabel = UILabel()
    private let timerProgressView = UIProgressView(progressViewStyle: .default)

    // common
    private let favoriteFilterView = FavoriteFilterView()
    private let filterSegmentControl = UISegmentedControl(items: ["Все", "Фиат", "Крипта"])
    private let emptyStateLabel = UILabel()
    private var collectionView: UICollectionView!

    private var pairRate: Double = 1000.0
    private var updateTimer: Timer?
    private let updatePeriod = 5
    private var secondsLeft = 5

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
        self.compactFallbackAssets = Array(allAssets.shuffled().prefix(10))
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

    deinit {
        updateTimer?.invalidate()
    }
}

private extension CurrencyPairsViewController {

    func setupUI() {
        view.backgroundColor = .darkGray
        title = mode == .compact ? "Быстрый выбор пары" : "Все валюты"

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

    func setupCompactUI() {
        compactPairContainerView.translatesAutoresizingMaskIntoConstraints = false
        compactPairContainerView.backgroundColor = .lightGray
        compactPairContainerView.layer.cornerRadius = 12

        [compactFirstCurrencyButton, compactSecondCurrencyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.tintColor = .black
            $0.backgroundColor = .white
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
        allButton.setTitleColor(.black, for: .normal)
        allButton.backgroundColor = .systemBlue
        allButton.layer.cornerRadius = 10
        allButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        allButton.addTarget(self, action: #selector(allButtonTapped), for: .touchUpInside)

        compactPairContainerView.addSubview(compactFirstCurrencyButton)
        compactPairContainerView.addSubview(compactSecondCurrencyButton)
    }

    func setupFullHeaderUI() {
        fullHeaderView.translatesAutoresizingMaskIntoConstraints = false
        fullHeaderView.backgroundColor = .lightGray
        fullHeaderView.layer.cornerRadius = 10

        [fullFirstCurrencyLabel, fullSecondCurrencyLabel, rateLabel, amountTextField, resultLabel, timerLabel, timerProgressView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        fullFirstCurrencyLabel.textAlignment = .center
        fullFirstCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        fullFirstCurrencyLabel.backgroundColor = .white
        fullFirstCurrencyLabel.layer.cornerRadius = 8
        fullFirstCurrencyLabel.clipsToBounds = true
        fullFirstCurrencyLabel.isUserInteractionEnabled = true
        fullFirstCurrencyLabel.tag = 0
        fullFirstCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

        fullSecondCurrencyLabel.textAlignment = .center
        fullSecondCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        fullSecondCurrencyLabel.backgroundColor = .white
        fullSecondCurrencyLabel.layer.cornerRadius = 8
        fullSecondCurrencyLabel.clipsToBounds = true
        fullSecondCurrencyLabel.isUserInteractionEnabled = true
        fullSecondCurrencyLabel.tag = 1
        fullSecondCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

        rateLabel.textAlignment = .center
        rateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        rateLabel.backgroundColor = .white
        rateLabel.layer.cornerRadius = 8
        rateLabel.clipsToBounds = true
        rateLabel.textColor = .black

        amountTextField.placeholder = "Введите сумму"
        amountTextField.borderStyle = .roundedRect
        amountTextField.keyboardType = .decimalPad
        amountTextField.backgroundColor = .white
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)

        resultLabel.textAlignment = .center
        resultLabel.backgroundColor = .white
        resultLabel.layer.cornerRadius = 8
        resultLabel.clipsToBounds = true
        resultLabel.font = .systemFont(ofSize: 14)
        resultLabel.text = "Получите: 0"

        timerLabel.textAlignment = .center
        timerLabel.backgroundColor = .white
        timerLabel.layer.cornerRadius = 8
        timerLabel.clipsToBounds = true
        timerLabel.font = .systemFont(ofSize: 12)
        timerLabel.text = "Обновление: 5с"

        timerProgressView.progress = 0
        timerProgressView.progressTintColor = .systemBlue
        timerProgressView.trackTintColor = .systemGray4

        let firstHintLabel = UILabel()
        firstHintLabel.translatesAutoresizingMaskIntoConstraints = false
        firstHintLabel.text = "Из какой:"
        firstHintLabel.font = .systemFont(ofSize: 16)
        firstHintLabel.textColor = .black

        let secondHintLabel = UILabel()
        secondHintLabel.translatesAutoresizingMaskIntoConstraints = false
        secondHintLabel.text = "В какую:"
        secondHintLabel.font = .systemFont(ofSize: 16)
        secondHintLabel.textColor = .black

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
            secondHintLabel.topAnchor.constraint(equalTo: firstHintLabel.bottomAnchor, constant: 12),
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
        filterSegmentControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PairAssetCollectionCell.self, forCellWithReuseIdentifier: PairAssetCollectionCell.reuseIdentifier)
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
        let favorites = allAssets.filter { favoriteCodes.contains($0.code) }
        if !favorites.isEmpty {
            return favorites
        }
        return compactFallbackAssets.sorted { $0.code < $1.code }
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
            compactFirstCurrencyButton.layer.borderColor = UIColor.systemBlue.cgColor
            compactSecondCurrencyButton.layer.borderWidth = 0

            fullFirstCurrencyLabel.layer.borderWidth = 2
            fullFirstCurrencyLabel.layer.borderColor = UIColor.systemBlue.cgColor
            fullFirstCurrencyLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            fullSecondCurrencyLabel.layer.borderWidth = 0
            fullSecondCurrencyLabel.backgroundColor = .white
        } else {
            compactSecondCurrencyButton.layer.borderWidth = 2
            compactSecondCurrencyButton.layer.borderColor = UIColor.systemBlue.cgColor
            compactFirstCurrencyButton.layer.borderWidth = 0

            fullSecondCurrencyLabel.layer.borderWidth = 2
            fullSecondCurrencyLabel.layer.borderColor = UIColor.systemBlue.cgColor
            fullSecondCurrencyLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            fullFirstCurrencyLabel.layer.borderWidth = 0
            fullFirstCurrencyLabel.backgroundColor = .white
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
        updateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectAsset(filteredAssets[indexPath.item])
    }
}

extension CurrencyPairsViewController: PairAssetCollectionCellDelegate {
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
    func favoriteFilterView(_ view: FavoriteFilterView, didChangeState isEnabled: Bool) {
        isFavoriteFilterEnabled = isEnabled
        applySelectedFiltersAndReload()
    }
}
