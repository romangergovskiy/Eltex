import Foundation

struct TradingBotViewState {
    let pairText: String
    let botsCountText: String
    let statusText: String
    let dailyResults: [BotDayResult]
    let isFirstRun: Bool
    let controlsEnabled: Bool
}

final class TradingBotViewModel {
    var onStateChange: ((TradingBotViewState) -> Void)?
    var onError: ((String) -> Void)?

    private let wallet: Wallet
    private let tradingEngine: TradingEngine
    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private let defaultFirstCode = "USD"
    private let defaultSecondCode = "BTC"

    private var isFirstRun = true
    private var statusText = ""
    private var dailyResults: [BotDayResult] = []
    private var bots: [TradingBot] = []
    private var firstAsset = PairAsset(code: "USD", category: .fiat)
    private var secondAsset = PairAsset(code: "BTC", category: .crypto)
    private var controlsEnabled = true

    init(wallet: Wallet, tradingEngine: TradingEngine = TradingEngine(config: AppConfig.tradingConfig)) {
        self.wallet = wallet
        self.tradingEngine = tradingEngine
    }

    func viewDidLoad() {
        setupInitialPair()
        configureDefaultBotsForCurrentPairIfNeeded()
        emitState()
    }

    func pairSelectionInput() -> (allAssets: [PairAsset], first: PairAsset, second: PairAsset) {
        (allAssets, firstAsset, secondAsset)
    }

    func applyPair(first: PairAsset, second: PairAsset) {
        guard first.code != second.code else { return }
        let didChange = first.code != firstAsset.code || second.code != secondAsset.code
        firstAsset = first
        secondAsset = second
        if didChange {
            migrateSomeBotsToCurrentPair(count: 3)
            resetTradingState()
        }
        emitState()
    }

    func runTrading(isEnabled: Bool) {
        if bots.isEmpty {
            configureDefaultBotsForCurrentPairIfNeeded()
            emitState()
        }

        guard isEnabled else {
            onError?("Включите переключатель бота перед запуском.")
            return
        }

        controlsEnabled = false
        statusText = "Выполняем расчеты... Ботов: \(bots.count), дней: \(AppConfig.numberOfDays), операций в день: \(AppConfig.minOperationsPerDay)-\(AppConfig.maxOperationsPerDay)"
        isFirstRun = false
        dailyResults = []
        emitState()

        tradingEngine.run(
            bots: bots,
            wallet: wallet,
            progress: { [weak self] day, totalDays in
                guard let self else { return }
                self.statusText = "Выполняем расчеты... день \(day)/\(totalDays), ботов: \(self.bots.count), операций в день: \(AppConfig.minOperationsPerDay)-\(AppConfig.maxOperationsPerDay)"
                self.emitState()
            },
            completion: { [weak self] results in
                guard let self else { return }
                self.dailyResults = results
                self.controlsEnabled = true
                self.statusText = "Готово. Выполнено результатов: \(results.count)."
                self.emitState()
            }
        )
    }

    func reset() {
        setupInitialPair()
        bots = []
        wallet.reset(to: AppConfig.initialWalletBalances)
        resetTradingState()
        emitState()
    }

    func randomPair() {
        guard allAssets.count > 1 else { return }
        let first = allAssets.randomElement() ?? allAssets[0]
        let second = allAssets.first(where: { $0.code != first.code }) ?? first
        applyPair(first: first, second: second)
    }

    func addBot(name rawName: String) {
        let input = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            onError?("Имя бота не может быть пустым.")
            return
        }
        guard !bots.contains(where: { $0.setup.name.lowercased() == input.lowercased() }) else {
            onError?("Бот с таким именем уже есть.")
            return
        }

        let setup = BotSetup(
            name: input,
            baseCurrency: firstAsset.code,
            quoteCurrency: secondAsset.code,
            baseCategory: firstAsset.category,
            quoteCategory: secondAsset.category
        )
        bots.append(TradingBot(setup: setup, wallet: wallet))
        statusText = "Добавлен бот \(input) для пары \(setup.pairCode)."
        isFirstRun = false
        emitState()
    }

    private func emitState() {
        onStateChange?(
            TradingBotViewState(
                pairText: "\(firstAsset.code)-\(secondAsset.code)",
                botsCountText: "Ботов: \(bots.count)",
                statusText: statusText,
                dailyResults: dailyResults,
                isFirstRun: isFirstRun,
                controlsEnabled: controlsEnabled
            )
        )
    }

    private func setupInitialPair() {
        let fallback = allAssets.first ?? PairAsset(code: "USD", category: .fiat)
        firstAsset = allAssets.first(where: { $0.code == defaultFirstCode }) ?? fallback
        secondAsset = allAssets.first(where: { $0.code == defaultSecondCode }) ?? allAssets.first(where: { $0.code != firstAsset.code }) ?? fallback
    }

    private func configureDefaultBotsForCurrentPairIfNeeded() {
        guard bots.isEmpty else { return }
        let pairShort = "\(firstAsset.code)\(secondAsset.code)"
        bots = (1...AppConfig.defaultBotsPerPair).map { index in
            let setup = BotSetup(
                name: "Bot\(pairShort)\(index)",
                baseCurrency: firstAsset.code,
                quoteCurrency: secondAsset.code,
                baseCategory: firstAsset.category,
                quoteCategory: secondAsset.category
            )
            return TradingBot(setup: setup, wallet: wallet)
        }
    }

    private func migrateSomeBotsToCurrentPair(count: Int) {
        guard !bots.isEmpty else { return }
        let migrateCount = min(max(0, count), bots.count)
        guard migrateCount > 0 else { return }

        for index in 0..<migrateCount {
            let previous = bots[index]
            let updatedSetup = BotSetup(
                name: previous.setup.name,
                baseCurrency: firstAsset.code,
                quoteCurrency: secondAsset.code,
                baseCategory: firstAsset.category,
                quoteCategory: secondAsset.category
            )
            bots[index] = TradingBot(setup: updatedSetup, wallet: wallet)
        }
    }

    private func resetTradingState() {
        isFirstRun = true
        statusText = ""
        dailyResults = []
        controlsEnabled = true
    }
}
