
import Foundation

enum Currency: String {
    case usd = "USD"
}

enum TradeAction: String {
    case buy = "покупка"
    case sell = "продажа"
    case ignore = "игнорирование"
}

struct Trader {
    var balance: Double
    var currency: Currency
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
            
            if trader.balance <= 0 {
                let message = "Баланс закончился, бот останавливает торговлю."
                onUpdate?(message)
                print(message)
                break
            }
            
            let previousPrice = currentPrice
            let priceChange = generatePriceChange()
            currentPrice += priceChange
            
            let action = makeDecision(priceChange: priceChange)
            
            let status = "\(currentPrice.formatted) \(trader.currency.rawValue) - \(action.rawValue)"
            onUpdate?(status)
            print(status)
            
            if action != .ignore {
                let tradeResult: Double
                
                if action == .buy {
                    tradeResult = -priceChange
                } else {
                    tradeResult = priceChange
                }
                
                trader.balance += tradeResult
                
                let tradeMessage = "\(action.rawValue.capitalized) FROM = \(previousPrice.formatted) -> TO = \(currentPrice.formatted), INCOME = \(tradeResult.formatted)"
                onUpdate?(tradeMessage)
                print(tradeMessage)
            }
        }
        
        let final = "Final balance: \(trader.balance.formatted)"
        onUpdate?(final)
        print(final)
    }
}

private extension TradingBot {
    
    func generatePriceChange() -> Double {
        Double.random(in: -500...500)
    }
    
    func makeDecision(priceChange: Double) -> TradeAction {
        if priceChange < -100 {
            return .buy
        } else if priceChange > 100 {
            return .sell
        } else {
            return .ignore
        }
    }
}

extension Double {
    var formatted: String {
        String(format: "%.2f", self)
    }
}

