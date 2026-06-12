import Foundation

struct OptimizationCurrencyPair: Identifiable, Equatable {
    let id: UUID
    let name: String
    var value: Double
    var previousValue: Double
    var history: [Double]
    var isRisky: Bool
    var priceText: String

    var isGrowing: Bool {
        value >= previousValue
    }

    var changePercent: Double {
        guard previousValue != 0 else { return 0 }
        return (value - previousValue) / previousValue * 100
    }
}
