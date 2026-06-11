import Foundation
import OSLog

// MARK: - Trading Config

enum AppConfig {
    private static let networkModeKey = "app.network.combine.enabled"
    static var isNetworkWithCombine: Bool {
        get {
            if UserDefaults.standard.object(forKey: networkModeKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: networkModeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: networkModeKey)
        }
    }
    static let minOperationsPerDay = 200
    static let maxOperationsPerDay = 500
    static let numberOfDays = 20
    static let maxConcurrentOperations = 6
    static let autoCreditAmount = 1000.0
    static let minTradeAmount = 5.0
    static let maxTradeAmount = 40.0
    static let defaultBotsPerPair = 5

    static let initialWalletBalances: [String: Double] = [
        "USD": 10_000,
        "RUB": 500_000,
        "BTC": 1_500,
        "ETH": 2_500
    ]

    static var tradingConfig: TradingConfig {
        TradingConfig(
            minOperationsPerDay: minOperationsPerDay,
            maxOperationsPerDay: maxOperationsPerDay,
            numberOfDays: numberOfDays,
            maxConcurrentOperations: maxConcurrentOperations
        )
    }
}

struct TradingConfig {
    let minOperationsPerDay: Int
    let maxOperationsPerDay: Int
    let numberOfDays: Int
    let maxConcurrentOperations: Int
}

struct WalletSnapshot {
    let balances: [String: Double]
    let credit: [String: Double]
}

struct WalletExchangeResult {
    let spent: Double
    let received: Double
}

struct BotDayResult {
    let botName: String
    let pairCode: String
    let quoteCurrency: String
    let day: Int
    let startBalances: [String: Double]
    let endBalances: [String: Double]
    let income: Double
}

struct BotSetup {
    let name: String
    let baseCurrency: String
    let quoteCurrency: String
    let baseCategory: PairAssetCategory
    let quoteCategory: PairAssetCategory

    var pairCode: String { "\(baseCurrency)-\(quoteCurrency)" }
}

final class Wallet {
    private let queue = DispatchQueue(label: "wallet.sync.queue")
    private var balances: [String: Double]
    private var credit: [String: Double]
    private let autoCreditAmount: Double

    init(initialBalances: [String: Double], autoCreditAmount: Double) {
        self.balances = initialBalances
        self.credit = [:]
        self.autoCreditAmount = autoCreditAmount
    }

    func reset(to initialBalances: [String: Double]) {
        queue.sync {
            balances = initialBalances
            credit = [:]
        }
    }

    func fullSnapshot() -> WalletSnapshot {
        queue.sync {
            WalletSnapshot(balances: balances, credit: credit)
        }
    }

    func pairBalances(base: String, quote: String) -> [String: Double] {
        queue.sync {
            [
                base: balances[base, default: 0],
                quote: balances[quote, default: 0]
            ]
        }
    }

    @discardableResult
    func exchange(from sourceCurrency: String, to targetCurrency: String, amount: Double, rate: Double) -> WalletExchangeResult {
        guard amount > 0, rate > 0 else {
            return WalletExchangeResult(spent: 0, received: 0)
        }

        return queue.sync {
            replenishIfNeeded(currency: sourceCurrency)

            let available = balances[sourceCurrency, default: 0]
            let spent = min(available, amount)
            guard spent > 0 else {
                return WalletExchangeResult(spent: 0, received: 0)
            }

            balances[sourceCurrency, default: 0] -= spent
            let received = spent * rate
            balances[targetCurrency, default: 0] += received

            replenishIfNeeded(currency: sourceCurrency)
            return WalletExchangeResult(spent: spent, received: received)
        }
    }

    private func replenishIfNeeded(currency: String) {
        guard balances[currency, default: 0] <= 0 else { return }
        balances[currency, default: 0] += autoCreditAmount
        credit[currency, default: 0] += autoCreditAmount
    }
}

final class TradingBot {
    let setup: BotSetup
    private let wallet: Wallet

    init(setup: BotSetup, wallet: Wallet) {
        self.setup = setup
        self.wallet = wallet
    }

    func runSingleOperation() {
        let sellBase = Bool.random()
        let price = generatePrice()

        if sellBase {
            let sellAmount = Double.random(in: AppConfig.minTradeAmount...AppConfig.maxTradeAmount)
            _ = wallet.exchange(
                from: setup.baseCurrency,
                to: setup.quoteCurrency,
                amount: sellAmount,
                rate: price
            )
            return
        }

        let spendQuote = Double.random(in: AppConfig.minTradeAmount...AppConfig.maxTradeAmount)
        _ = wallet.exchange(
            from: setup.quoteCurrency,
            to: setup.baseCurrency,
            amount: spendQuote,
            rate: 1 / price
        )
    }

    private func generatePrice() -> Double {
        Double.random(in: 0.5...1.6)
    }
}

final class TradingEngine {
    private let config: TradingConfig
    private let operationQueue: OperationQueue

    init(config: TradingConfig) {
        self.config = config
        self.operationQueue = OperationQueue()
        operationQueue.name = "trading.operations.queue"
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = max(1, config.maxConcurrentOperations)
    }

    func run(
        bots: [TradingBot],
        wallet: Wallet,
        progress: ((Int, Int) -> Void)? = nil,
        completion: @escaping ([BotDayResult]) -> Void
    ) {
        guard !bots.isEmpty else {
            completion([])
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var results: [BotDayResult] = []
            results.reserveCapacity(self.config.numberOfDays * bots.count)

            for day in 1...self.config.numberOfDays {
                for bot in bots {
                    let operationCount = Int.random(
                        in: self.config.minOperationsPerDay...self.config.maxOperationsPerDay
                    )
                    let startBalances = wallet.pairBalances(
                        base: bot.setup.baseCurrency,
                        quote: bot.setup.quoteCurrency
                    )

                    let operationsGroup = DispatchGroup()

                    for _ in 0..<operationCount {
                        operationsGroup.enter()
                        self.operationQueue.addOperation {
                            autoreleasepool {
                                bot.runSingleOperation()
                            }
                            operationsGroup.leave()
                        }
                    }

                    operationsGroup.wait()

                    let endBalances = wallet.pairBalances(
                        base: bot.setup.baseCurrency,
                        quote: bot.setup.quoteCurrency
                    )
                    let quoteCode = bot.setup.quoteCurrency
                    let income = endBalances[quoteCode, default: 0] - startBalances[quoteCode, default: 0]

                    results.append(
                        BotDayResult(
                            botName: bot.setup.name,
                            pairCode: bot.setup.pairCode,
                            quoteCurrency: bot.setup.quoteCurrency,
                            day: day,
                            startBalances: startBalances,
                            endBalances: endBalances,
                            income: income
                        )
                    )
                }

                DispatchQueue.main.async {
                    progress?(day, self.config.numberOfDays)
                }
            }

            let sorted = results.sorted {
                if $0.day == $1.day {
                    return $0.botName < $1.botName
                }
                return $0.day < $1.day
            }
            DispatchQueue.main.async {
                completion(sorted)
            }
        }
    }
}

// MARK: - Formatting

extension Double {
    var formatted: String {
        String(format: "%.2f", self)
    }
}

// MARK: - Pair assets

enum PairAssetCategory {
    case fiat
    case crypto
}

struct PairAsset: Hashable {
    let code: String
    let category: PairAssetCategory
}

enum PairAssetFilter: Int {
    case all = 0
    case fiat = 1
    case crypto = 2
}

enum PairAssetFactory {
    static func makeList(minCount: Int = 140) -> [PairAsset] {
        let fiatCodes = [
            "USD", "EUR", "RUB", "GBP", "JPY", "CNY", "CHF", "KZT", "TRY", "AED",
            "INR", "KRW", "SEK", "NOK", "DKK", "PLN", "CZK", "HUF", "UAH", "CAD",
            "AUD", "NZD", "HKD", "SGD", "THB", "BRL", "MXN", "ZAR", "ILS", "SAR"
        ]

        let cryptoCodes = [
            "BTC", "ETH", "USDT", "SOL", "TON", "XRP", "ADA", "DOGE", "DOT", "TRX",
            "BNB", "LTC", "AVAX", "LINK", "ATOM", "MATIC", "XMR", "ETC", "BCH", "UNI"
        ]

        var result = fiatCodes.map { PairAsset(code: $0, category: .fiat) }
        result += cryptoCodes.map { PairAsset(code: $0, category: .crypto) }

        var usedCodes = Set(result.map(\.code))
        while result.count < minCount {
            let code = randomCode()
            guard usedCodes.insert(code).inserted else { continue }
            let category: PairAssetCategory = Bool.random() ? .fiat : .crypto
            result.append(PairAsset(code: code, category: category))
        }

        return result.sorted { $0.code < $1.code }
    }

    private static func randomCode() -> String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let length = Int.random(in: 3...5)
        return String(
            (0..<length).compactMap { _ in
                letters.randomElement()
            }
        )
    }
}

// MARK: - Logging

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.roma.eltex-hw-10"
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let p2p = Logger(subsystem: subsystem, category: "p2p")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let common = Logger(subsystem: subsystem, category: "common")
}
