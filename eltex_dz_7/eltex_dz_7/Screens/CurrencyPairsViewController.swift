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
    private let filterSegmentControl = UISegmentedControl(items: ["Все", "Фиат", "Крипта"])

    private var collectionView: UICollectionView!

    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private var filteredAssets: [PairAsset] = []
    private var selectedFilter: PairAssetFilter = .all

    private var firstAsset: PairAsset
    private var secondAsset: PairAsset
    private var selectedSide: SelectedSide = .first

    private var pairRate: Double = 1000.0

    private var updateTimer: Timer?
    private let updatePeriod = 5
    private var secondsLeft = 5

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let assets = PairAssetFactory.makeList(minCount: 140)
        let usd = assets.first(where: { $0.code == "USD" }) ?? assets[0]
        let btc = assets.first(where: { $0.code == "BTC" }) ?? assets.first(where: { $0.code != usd.code })!
        self.firstAsset = usd
        self.secondAsset = btc
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let assets = PairAssetFactory.makeList(minCount: 140)
        let usd = assets.first(where: { $0.code == "USD" }) ?? assets[0]
        let btc = assets.first(where: { $0.code == "BTC" }) ?? assets.first(where: { $0.code != usd.code })!
        self.firstAsset = usd
        self.secondAsset = btc
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        title = "Валютные пары"
        filteredAssets = allAssets
        setupUI()
        refreshSelectedPairLabels()
        refreshActiveSideUI()
        refreshRate()
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
        setupFilterControl()
        setupCollectionView()
        setupKeyboardAccessory()
        addSubviews()
        makeConstraints()
    }

    func setupHeaderView() {
        headerView.backgroundColor = .lightGray
        headerView.layer.cornerRadius = 10

        [firstCurrencyLabel, secondCurrencyLabel, rateLabel, amountTextField, resultLabel, timerLabel, timerProgressView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        firstCurrencyLabel.textAlignment = .center
        firstCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        firstCurrencyLabel.backgroundColor = .white
        firstCurrencyLabel.layer.cornerRadius = 8
        firstCurrencyLabel.clipsToBounds = true
        firstCurrencyLabel.isUserInteractionEnabled = true
        firstCurrencyLabel.tag = 0
        firstCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

        secondCurrencyLabel.textAlignment = .center
        secondCurrencyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        secondCurrencyLabel.backgroundColor = .white
        secondCurrencyLabel.layer.cornerRadius = 8
        secondCurrencyLabel.clipsToBounds = true
        secondCurrencyLabel.isUserInteractionEnabled = true
        secondCurrencyLabel.tag = 1
        secondCurrencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectedCurrencyTapped(_:))))

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

            rateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            rateLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 14),
            rateLabel.widthAnchor.constraint(equalToConstant: 220),
            rateLabel.heightAnchor.constraint(equalToConstant: 40),

            amountTextField.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            amountTextField.topAnchor.constraint(equalTo: secondCurrencyLabel.bottomAnchor, constant: 10),
            amountTextField.widthAnchor.constraint(equalToConstant: 120),
            amountTextField.heightAnchor.constraint(equalToConstant: 35),

            resultLabel.leadingAnchor.constraint(equalTo: amountTextField.trailingAnchor, constant: 12),
            resultLabel.centerYAnchor.constraint(equalTo: amountTextField.centerYAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            resultLabel.heightAnchor.constraint(equalToConstant: 35),

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

    func setupKeyboardAccessory() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton]
        amountTextField.inputAccessoryView = toolbar
    }

    func addSubviews() {
        view.addSubview(headerView)
        view.addSubview(filterSegmentControl)
        view.addSubview(collectionView)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 220),

            filterSegmentControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            filterSegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSegmentControl.heightAnchor.constraint(equalToConstant: 32),

            collectionView.topAnchor.constraint(equalTo: filterSegmentControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
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
        applyFilter()
        collectionView.reloadData()
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

// MARK: - Business
private extension CurrencyPairsViewController {
    func refreshSelectedPairLabels() {
        firstCurrencyLabel.text = firstAsset.code
        secondCurrencyLabel.text = secondAsset.code
    }

    func refreshActiveSideUI() {
        switch selectedSide {
        case .first:
            firstCurrencyLabel.layer.borderWidth = 2
            firstCurrencyLabel.layer.borderColor = UIColor.systemBlue.cgColor
            firstCurrencyLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)

            secondCurrencyLabel.layer.borderWidth = 0
            secondCurrencyLabel.backgroundColor = .white
        case .second:
            secondCurrencyLabel.layer.borderWidth = 2
            secondCurrencyLabel.layer.borderColor = UIColor.systemBlue.cgColor
            secondCurrencyLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)

            firstCurrencyLabel.layer.borderWidth = 0
            firstCurrencyLabel.backgroundColor = .white
        }
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredAssets = allAssets
        case .fiat:
            filteredAssets = allAssets.filter { $0.category == .fiat }
        case .crypto:
            filteredAssets = allAssets.filter { $0.category == .crypto }
        }
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

    func isDisabled(_ asset: PairAsset) -> Bool {
        switch selectedSide {
        case .first:
            return asset.code == secondAsset.code
        case .second:
            return asset.code == firstAsset.code
        }
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
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
        let selected = asset.code == firstAsset.code || asset.code == secondAsset.code
        cell.configure(asset: asset, isDisabled: disabled, isSelectedPair: selected)
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

