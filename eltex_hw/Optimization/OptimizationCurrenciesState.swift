import Foundation

// MARK: - State

enum OptimizationCurrenciesState: Equatable {
    case idle
    case loading
    case content(OptimizationCurrenciesContentState)
    case error(String)
}

struct OptimizationCurrenciesContentState: Equatable {
    var pairs: [OptimizationCurrencyPair]
    var lastUpdatedPairs: [OptimizationCurrencyPair]
    var updateCycle: Int
    var highlightRisk: Bool
}

// MARK: - Action

enum OptimizationCurrenciesAction {
    case onAppear
    case onDisappear
    case initialLoaded([OptimizationCurrencyPair])
    case pairsUpdated(
        pairs: [OptimizationCurrencyPair],
        lastUpdatedPairs: [OptimizationCurrencyPair],
        updateCycle: Int
    )
    case highlightRiskChanged(Bool)
    case loadingFailed(String)
}
