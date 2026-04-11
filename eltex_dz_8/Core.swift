//
//  Core.swift
//  eltex_dz_8
//
//  Created by Роман Герговский on 03.04.2026.
//

import Foundation

// MARK: - Trading

enum Currency {
    case usd

    var code: String { "USD" }
}

enum TradeAction {
    case buy
    case sell
    case ignore

    var title: String {
        switch self {
        case .buy: return "Покупка"
        case .sell: return "Продажа"
        case .ignore: return "Игнорирование"
        }
    }
}

struct Trader {
    private(set) var balance: Double
    let currency: Currency

    init(balance: Double, currency: Currency) {
        self.balance = balance
        self.currency = currency
    }

    mutating func apply(_ delta: Double) {
        balance += delta
    }
}

struct TradeRecord {
    let index: Int
    let action: TradeAction
    let previousPrice: Double
    let currentPrice: Double
    let tradeResult: Double?
    let balanceAfter: Double
}

final class TradingBot {
    private let initialTrader: Trader
    private var trader: Trader
    private var currentPrice: Double

    init(trader: Trader) {
        self.initialTrader = trader
        self.trader = trader
        self.currentPrice = Double.random(in: 2000...8000)
    }

    func resetSession() {
        trader = initialTrader
        currentPrice = Double.random(in: 2000...8000)
    }

    func greeting() -> String {
        "Торговый бот запущен. Стартовый баланс: \(trader.balance.formatted) \(trader.currency.code)"
    }

    func generateHistory(count: Int = 40) -> [TradeRecord] {
        var records: [TradeRecord] = []
        records.reserveCapacity(count)

        for index in 1...count {
            guard trader.balance > 0 else { break }

            let previous = currentPrice
            let priceChange = Double.random(in: -500...500)
            currentPrice += priceChange

            let action = makeDecision(priceChange: priceChange)

            let result: Double?
            switch action {
            case .buy:
                result = priceChange
                trader.apply(priceChange)
            case .sell:
                result = priceChange
                trader.apply(priceChange)
            case .ignore:
                result = nil
            }

            let record = TradeRecord(
                index: index,
                action: action,
                previousPrice: previous,
                currentPrice: currentPrice,
                tradeResult: result,
                balanceAfter: trader.balance
            )
            records.append(record)
        }

        return records
    }

    private func makeDecision(priceChange: Double) -> TradeAction {
        guard abs(priceChange) > 100 else { return .ignore }
        return priceChange < -100 ? .buy : .sell
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
