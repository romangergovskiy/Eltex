import Foundation

var balance: Double = 10000
let currency = "USD"
var currentPrice = Double.random(in: 2000...8000)

for _ in 0...10 {
    if balance <= 0 {
        print("Баланс закончился, бот останавливает торговлю.")
        break
    }
    let previousPrice = currentPrice
    let priceChange = Double.random(in: -500...500)
    currentPrice += priceChange

    var action: String = "игнорирование"
    if priceChange < -100 {
        action = "покупка"
    } else if priceChange > 100 {
        action = "продажа"
    }

    print("\(String(format: "%.2f", currentPrice)) \(currency) - \(action)")

    if action != "игнорирование" {
        let startPrice = previousPrice
        let endPrice = currentPrice
        let tradeResult: Double
        if action == "покупка" {
                  tradeResult = -priceChange
              } else {
                  tradeResult = priceChange
              }
        balance += tradeResult
        print("\(action.capitalized) FROM = \(String(format: "%.2f", startPrice)) -> TO = \(String(format: "%.2f", endPrice)), INCOME = \(String(format: "%.2f", tradeResult))")
    }
}

print("Final balance: \(String(format: "%.2f", balance))")




