import Foundation

enum Currency {
    case usd
    
    var code: String { "USD" }
}

enum TradeAction {
    case buy
    case sell
    case ignore
    
    var displayName: String {
        switch self {
        case .buy: return "покупка"
        case .sell: return "продажа"
        case .ignore: return "игнорирование"
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
    
    func withUpdatedBalance(_ newBalance: Double) -> Trader {
        Trader(balance: newBalance, currency: currency)
    }
}

protocol TradingBotProtocol {
    func startTrading()
}

final class TradingBot: TradingBotProtocol {
    
    private var trader: Trader
    private var currentPrice: Double
    var onUpdate: ((String) -> Void)?
    
    init(trader: Trader) {
        self.trader = trader
        self.currentPrice = Double.random(in: 2000...8000)
    }
    
    func startTrading() {
        for _ in 0...10 {
            guard shouldContinueTrading() else { break }
            
            let iterationResult = performTradingIteration()
            reportIteration(iterationResult)
            
            if iterationResult.action != .ignore {
                let tradeResult = iterationResult.action == .buy ? -iterationResult.priceChange : iterationResult.priceChange
                trader = trader.withUpdatedBalance(trader.balance + tradeResult)
                reportTrade(iterationResult: iterationResult, tradeResult: tradeResult)
            }
        }
        
        reportFinalBalance()
    }
}

private extension TradingBot {
    
    func shouldContinueTrading() -> Bool {
        guard trader.balance > 0 else {
            let message = "Баланс закончился, бот останавливает торговлю."
            onUpdate?(message)
            print(message)
            return false
        }
        return true
    }
    
    func performTradingIteration() -> (previousPrice: Double, priceChange: Double, currentPrice: Double, action: TradeAction) {
        let previousPrice = currentPrice
        let priceChange = generatePriceChange()
        currentPrice += priceChange
        let action = makeDecision(priceChange: priceChange)
        return (previousPrice, priceChange, currentPrice, action)
    }
    
    func reportIteration(_ result: (previousPrice: Double, priceChange: Double, currentPrice: Double, action: TradeAction)) {
        let status = "\(currentPrice.formatted) \(trader.currency.code) - \(result.action.displayName)"
        onUpdate?(status)
        print(status)
    }
    
    func reportTrade(iterationResult: (previousPrice: Double, priceChange: Double, currentPrice: Double, action: TradeAction), tradeResult: Double) {
        let tradeMessage = "\(iterationResult.action.displayName.capitalized) FROM = \(iterationResult.previousPrice.formatted) -> TO = \(iterationResult.currentPrice.formatted), INCOME = \(tradeResult.formatted)"
        onUpdate?(tradeMessage)
        print(tradeMessage)
    }
    
    func reportFinalBalance() {
        let final = "Final balance: \(trader.balance.formatted)"
        onUpdate?(final)
        print(final)
    }
    
    func generatePriceChange() -> Double {
        Double.random(in: -500...500)
    }
    
    func makeDecision(priceChange: Double) -> TradeAction {
        guard abs(priceChange) > 100 else { return .ignore }
        if priceChange < -100 {
            return .buy
        } else {
            return .sell
        }
    }
}

extension Double {
    var formatted: String {
        String(format: "%.2f", self)
    }
}
