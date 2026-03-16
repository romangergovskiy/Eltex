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
    
    init(trader: Trader) {
        self.trader = trader
        self.currentPrice = Double.random(in: 2000...8000)
    }
    
    func startTrading() {
        for _ in 0...10 {
            
            if trader.balance <= 0 {
                print("Баланс закончился, бот останавливает торговлю.")
                break
            }
            
            let previousPrice = currentPrice
            let priceChange = generatePriceChange()
            currentPrice += priceChange
            
            let action = makeDecision(priceChange: priceChange)
            
            print("\(currentPrice.formatted) \(trader.currency.rawValue) - \(action.rawValue)")
            
            if action != .ignore {
                let tradeResult: Double
                
                if action == .buy {
                    tradeResult = -priceChange
                } else {
                    tradeResult = priceChange
                }
                
                trader.balance += tradeResult
                
                print("\(action.rawValue.capitalized) FROM = \(previousPrice.formatted) -> TO = \(currentPrice.formatted), INCOME = \(tradeResult.formatted)")
            }
        }
        
        print("Final balance: \(trader.balance.formatted)")
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

let trader = Trader(balance: 10000, currency: .usd)
let bot = TradingBot(trader: trader)

bot.startTrading()
