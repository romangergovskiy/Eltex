//
//  CurrencyPairsViewController.swift
//  eltex_dz_8
//
//  Created by Роман Герговский on 03.04.2026.
//

import UIKit

final class CurrencyPairsViewController: UIViewController {

    private enum SelectedSide {
        case first
        case second
    }

    private let headerView = UIView()
    private let firstCurrencyLabel = UILabel()
    private let secondCurrencyLabel = UILabel()
    private let rateLabel = UILabel()

    private let amountTextField = UITextField()
    private let resultLabel = UILabel()
    private let timerLabel = UILabel()
    private let timerProgressView = UIProgressView(progressViewStyle: .default)
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

    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private var filteredAssets: [PairAsset] = []
    private var selectedFilter: PairAssetFilter = .all
    private var favoriteCodes: Set<String> = []
    private var isFavoriteFilterEnabled = false

    private var firstAsset: PairAsset?
    private var secondAsset: PairAsset?
    private var selectedSide: SelectedSide = .first

    private var pairRate: Double = 1000.0

    private var updateTimer: Timer?
    private let updatePeriod = 5
    private var secondsLeft = 5
    private let favoritesStorageKey = "favoritePairAssets"

    // MARK: - Lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        title = "Валютные пары"
        loadFavorites()
        setupUI()
        applySelectedFiltersAndReload()
        refreshSelectedPairLabels()
        refreshActiveSideUI()
        refreshRate()
        startPriceTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPriceTimer()
    }

    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Setup UI
private extension CurrencyPairsViewController {

    func setupUI() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        setupHeaderView()
        setupFavoriteFilterView()
        setupFilterControl()
        setupEmptyStateLabel()
        setupCollectionView()
        setupKeyboardAccessory()
        addSubviews()
        makeConstraints()
    }

    func setupFavoriteFilterView() {
        favoriteFilterView.delegate = self
    }

    func setupHeaderView() {
        headerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        headerView.layer.cornerRadius = 16

        [firstCurrencyLabel, secondCurrencyLabel, rateLabel, amountTextField, resultLabel, timerLabel, timerProgressView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        firstCurrencyLabel.textAlignment = .center
        firstCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        firstCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        firstCurrencyLabel.layer.cornerRadius = 8
        firstCurrencyLabel.clipsToBounds = true
        firstCurrencyLabel.textColor = .white
        firstCurrencyLabel.isUserInteractionEnabled = true
        firstCurrencyLabel.tag = 0
        firstCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

        secondCurrencyLabel.textAlignment = .center
        secondCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        secondCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        secondCurrencyLabel.layer.cornerRadius = 8
        secondCurrencyLabel.clipsToBounds = true
        secondCurrencyLabel.textColor = .white
        secondCurrencyLabel.isUserInteractionEnabled = true
        secondCurrencyLabel.tag = 1
        secondCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

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

        headerView.addSubview(firstHintLabel)
        headerView.addSubview(secondHintLabel)
        headerView.addSubview(firstCurrencyLabel)
        headerView.addSubview(secondCurrencyLabel)
        headerView.addSubview(rateLabel)
        headerView.addSubview(amountTextField)
        headerView.addSubview(resultLabel)
        headerView.addSubview(timerLabel)
        headerView.addSubview(timerProgressView)

        NSLayoutConstraint.activate([
            firstHintLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            firstHintLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 14),
            firstHintLabel.widthAnchor.constraint(equalToConstant: 72),

            firstCurrencyLabel.leadingAnchor.constraint(equalTo: firstHintLabel.trailingAnchor, constant: 12),
            firstCurrencyLabel.centerYAnchor.constraint(equalTo: firstHintLabel.centerYAnchor),
            firstCurrencyLabel.widthAnchor.constraint(equalToConstant: 96),
            firstCurrencyLabel.heightAnchor.constraint(equalToConstant: 40),

            secondHintLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            secondHintLabel.topAnchor.constraint(equalTo: firstHintLabel.bottomAnchor, constant: 12),
            secondHintLabel.widthAnchor.constraint(equalToConstant: 72),

            secondCurrencyLabel.leadingAnchor.constraint(equalTo: secondHintLabel.trailingAnchor, constant: 12),
            secondCurrencyLabel.centerYAnchor.constraint(equalTo: secondHintLabel.centerYAnchor),
            secondCurrencyLabel.widthAnchor.constraint(equalToConstant: 96),
            secondCurrencyLabel.heightAnchor.constraint(equalToConstant: 40),

            amountTextField.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            amountTextField.topAnchor.constraint(equalTo: secondCurrencyLabel.bottomAnchor, constant: 10),
            amountTextField.widthAnchor.constraint(equalToConstant: 120),
            amountTextField.heightAnchor.constraint(equalToConstant: 35),

            resultLabel.leadingAnchor.constraint(equalTo: amountTextField.trailingAnchor, constant: 12),
            resultLabel.centerYAnchor.constraint(equalTo: amountTextField.centerYAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            resultLabel.heightAnchor.constraint(equalToConstant: 35),

            rateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            rateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            rateLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 6),
            rateLabel.heightAnchor.constraint(equalToConstant: 30),

            timerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            timerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            timerLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
            timerLabel.heightAnchor.constraint(equalToConstant: 28),

            timerProgressView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            timerProgressView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            timerProgressView.bottomAnchor.constraint(equalTo: timerLabel.topAnchor, constant: -6),
            timerProgressView.heightAnchor.constraint(equalToConstant: 4)
        ])
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

    func setupEmptyStateLabel() {
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "В избранном пока пусто"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
    }

    func setupCollectionView() {
        collectionView.layer.cornerRadius = 16
        collectionView.backgroundColor = UIColor(red: 0.1, green: 0.14, blue: 0.24, alpha: 1)
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
        view.addSubview(headerView)
        view.addSubview(favoriteFilterView)
        view.addSubview(filterSegmentControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 220),

            favoriteFilterView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            favoriteFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            favoriteFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            favoriteFilterView.heightAnchor.constraint(equalToConstant: 44),

            filterSegmentControl.topAnchor.constraint(equalTo: favoriteFilterView.bottomAnchor, constant: 10),
            filterSegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSegmentControl.heightAnchor.constraint(equalToConstant: 32),

            collectionView.topAnchor.constraint(equalTo: filterSegmentControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -16)
        ])
    }
}

// MARK: - Actions
private extension CurrencyPairsViewController {
    @objc func doneTapped() {
        amountTextField.resignFirstResponder()
    }

    @objc func selectedCurrencyTapped(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        selectedSide = label.tag == 0 ? .first : .second
        refreshActiveSideUI()
        collectionView.reloadData()
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

    // MARK: Pair selection

    func refreshSelectedPairLabels() {
        firstCurrencyLabel.text = firstAsset?.code ?? "Выберите"
        secondCurrencyLabel.text = secondAsset?.code ?? "Выберите"
    }

    func refreshActiveSideUI() {
        switch selectedSide {
        case .first:
            firstCurrencyLabel.layer.borderWidth = 2
            firstCurrencyLabel.layer.borderColor = UIColor.systemTeal.cgColor
            firstCurrencyLabel.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)

            secondCurrencyLabel.layer.borderWidth = 0
            secondCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        case .second:
            secondCurrencyLabel.layer.borderWidth = 2
            secondCurrencyLabel.layer.borderColor = UIColor.systemTeal.cgColor
            secondCurrencyLabel.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)

            firstCurrencyLabel.layer.borderWidth = 0
            firstCurrencyLabel.backgroundColor = UIColor(red: 0.16, green: 0.23, blue: 0.35, alpha: 1)
        }
    }

    // MARK: Filtering

    func applyFilter() {
        var typeFiltered: [PairAsset]
        switch selectedFilter {
        case .all:
            typeFiltered = allAssets
        case .fiat:
            typeFiltered = allAssets.filter { $0.category == .fiat }
        case .crypto:
            typeFiltered = allAssets.filter { $0.category == .crypto }
        }

        if isFavoriteFilterEnabled {
            filteredAssets = typeFiltered.filter { favoriteCodes.contains($0.code) }
        } else {
            filteredAssets = typeFiltered
        }
    }

    func applySelectedFiltersAndReload() {
        applyFilter()
        updateEmptyState()
        collectionView.reloadData()
    }

    func updateEmptyState() {
        let isEmptyFavorites = isFavoriteFilterEnabled && filteredAssets.isEmpty
        emptyStateLabel.isHidden = !isEmptyFavorites
        collectionView.isHidden = isEmptyFavorites
    }

    // MARK: Conversion & rate

    func refreshRate() {
        guard let firstAsset, let secondAsset else {
            rateLabel.text = "Курс: -"
            resultLabel.text = "Получите: 0"
            return
        }

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
            let code = secondAsset?.code ?? ""
            resultLabel.text = code.isEmpty ? "Получите: 0" : "Получите: 0 \(code)"
            return
        }

        let amountInSecond = amountInFirst / pairRate
        let code = secondAsset?.code ?? ""
        resultLabel.text = String(format: "Получите: %.6f %@", amountInSecond, code)
    }

    // MARK: Timer

    func startPriceTimer() {
        updateTimer?.invalidate()
        secondsLeft = updatePeriod
        timerLabel.text = "Обновление: \(secondsLeft)с"
        timerProgressView.progress = 0
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    func isDisabled(_ asset: PairAsset) -> Bool {
        switch selectedSide {
        case .first:
            return asset.code == secondAsset?.code
        case .second:
            return asset.code == firstAsset?.code
        }
    }

    // MARK: Alerts

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    // MARK: Favorites persistence

    func loadFavorites() {
        guard let saved = UserDefaults.standard.array(forKey: favoritesStorageKey) as? [String] else { return }
        favoriteCodes = Set(saved)
    }

    func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteCodes), forKey: favoritesStorageKey)
    }
}

// MARK: - Collection
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
        let disabled = isDisabled(asset)
        let selected = asset.code == firstAsset?.code || asset.code == secondAsset?.code
        let isFavorite = favoriteCodes.contains(asset.code)
        cell.configure(asset: asset, isDisabled: disabled, isSelectedPair: selected, isFavorite: isFavorite)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pickedAsset = filteredAssets[indexPath.item]
        if isDisabled(pickedAsset) {
            showError("Валюты в паре должны быть разными")
            return
        }

        switch selectedSide {
        case .first:
            firstAsset = pickedAsset
        case .second:
            secondAsset = pickedAsset
        }

        refreshSelectedPairLabels()
        refreshRate()
        collectionView.reloadData()
    }
}

// MARK: - PairAssetCollectionCellDelegate
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

// MARK: - FavoriteFilterViewDelegate
extension CurrencyPairsViewController: FavoriteFilterViewDelegate {
    func favoriteFilterView(_ view: FavoriteFilterView, didChangeState isEnabled: Bool) {
        isFavoriteFilterEnabled = isEnabled
        applySelectedFiltersAndReload()
    }
}

// MARK: - UITextFieldDelegate
extension CurrencyPairsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.contains("-") || string.contains("−") {
            return false
        }
        return true
    }
}

