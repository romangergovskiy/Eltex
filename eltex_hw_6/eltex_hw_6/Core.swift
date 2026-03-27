import Foundation

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
    private var trader: Trader
    private var currentPrice: Double

    init(trader: Trader) {
        self.trader = trader
        self.currentPrice = Double.random(in: 2000...8000)
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

extension Double {
    var formatted: String {
        String(format: "%.2f", self)
    }
}
