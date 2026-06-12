import Foundation

protocol OptimizationCurrenciesUseCaseProtocol: AnyObject {
    func makeInitialPairs() -> [OptimizationCurrencyPair]
    func startUpdates(
        onUpdate: @escaping (_ pairs: [OptimizationCurrencyPair], _ lastUpdatedPairs: [OptimizationCurrencyPair], _ updateCycle: Int) -> Void
    )
    func stopUpdates()
}

final class OptimizationCurrenciesUseCase: OptimizationCurrenciesUseCaseProtocol {
    private enum Constants {
        static let pairsCount = 500
        static let maxHistoryCount = 240
        static let latestPairsCount = 12
        static let recentWindow = 14
        static let volatilityRiskThreshold = 0.06
        static let rangeRiskThresholdPercent = 2.2
    }

    private var timer: Timer?
    private var pairs: [OptimizationCurrencyPair] = []
    private var updateCycle = 0
    private var onUpdate: ((_ pairs: [OptimizationCurrencyPair], _ lastUpdatedPairs: [OptimizationCurrencyPair], _ updateCycle: Int) -> Void)?

    deinit {
        timer?.invalidate()
    }

    func makeInitialPairs() -> [OptimizationCurrencyPair] {
        if pairs.isEmpty {
            pairs = makePairs()
        }
        return pairs
    }

    func startUpdates(
        onUpdate: @escaping (_ pairs: [OptimizationCurrencyPair], _ lastUpdatedPairs: [OptimizationCurrencyPair], _ updateCycle: Int) -> Void
    ) {
        self.onUpdate = onUpdate
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.updateRandomPairs()
        }
    }

    func stopUpdates() {
        timer?.invalidate()
        timer = nil
        onUpdate = nil
    }
}

private extension OptimizationCurrenciesUseCase {
    func updateRandomPairs() {
        guard !pairs.isEmpty else { return }

        var updatedPairs = pairs
        let updateCount = Int.random(in: 8...35)
        var indexes = Set<Int>()

        while indexes.count < updateCount {
            indexes.insert(Int.random(in: updatedPairs.indices))
        }

        for index in indexes {
            updatedPairs[index].previousValue = updatedPairs[index].value
            updatedPairs[index].value = max(
                0.0001,
                updatedPairs[index].value * Double.random(in: 0.985...1.015)
            )

            updatedPairs[index].history.append(updatedPairs[index].value)
            if updatedPairs[index].history.count > Constants.maxHistoryCount {
                let overflow = updatedPairs[index].history.count - Constants.maxHistoryCount
                updatedPairs[index].history.removeFirst(overflow)
            }

            updatedPairs[index].isRisky = Self.isRisky(history: updatedPairs[index].history)
            updatedPairs[index].priceText = Self.priceFormatter.string(
                from: NSNumber(value: updatedPairs[index].value)
            ) ?? "\(updatedPairs[index].value)"
        }

        let sortedIndexes = indexes.sorted { left, right in
            updatedPairs[left].name < updatedPairs[right].name
        }
        let lastUpdatedPairs = sortedIndexes
            .prefix(Constants.latestPairsCount)
            .map { updatedPairs[$0] }

        pairs = updatedPairs
        updateCycle += 1
        onUpdate?(updatedPairs, lastUpdatedPairs, updateCycle)
    }

    func makePairs() -> [OptimizationCurrencyPair] {
        (0..<Constants.pairsCount).map { _ in
            var value = Double.random(in: 0.5...180)
            var history: [Double] = []

            for _ in 0..<120 {
                value = max(0.0001, value * Double.random(in: 0.995...1.005))
                history.append(value)
            }

            return OptimizationCurrencyPair(
                id: UUID(),
                name: "\(Self.randomCode())/\(Self.randomCode())",
                value: value,
                previousValue: history.dropLast().last ?? value,
                history: history,
                isRisky: Self.isRisky(history: history),
                priceText: Self.priceFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
            )
        }
        .sorted { $0.name < $1.name }
    }

    static func randomCode() -> String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String((0..<3).compactMap { _ in letters.randomElement() })
    }

    static func isRisky(history: [Double]) -> Bool {
        guard history.count > 1 else { return false }

        var returns: [Double] = []
        returns.reserveCapacity(history.count - 1)
        for index in 1..<history.count {
            let previous = max(history[index - 1], 0.0001)
            returns.append(log(history[index] / previous))
        }

        let average = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { partialResult, value in
            partialResult + pow(value - average, 2)
        } / Double(returns.count)
        let volatility = sqrt(variance) * sqrt(252)

        let recent = history.suffix(Constants.recentWindow)
        let maxPrice = recent.max() ?? 0
        let minPrice = recent.min() ?? 0
        let averagePrice = recent.reduce(0, +) / Double(max(recent.count, 1))
        let rangePercent = averagePrice > 0 ? ((maxPrice - minPrice) / averagePrice) * 100 : 0

        return volatility > Constants.volatilityRiskThreshold
            || rangePercent > Constants.rangeRiskThresholdPercent
    }

    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        return formatter
    }()
}
