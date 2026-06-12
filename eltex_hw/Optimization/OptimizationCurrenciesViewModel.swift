import Foundation
import Combine

@MainActor
final class OptimizationCurrenciesViewModel: ObservableObject {
    @Published private(set) var state: OptimizationCurrenciesState = .idle

    private enum Constants {
        static let latestPairsCount = 12
    }

    private let useCase: OptimizationCurrenciesUseCaseProtocol
    private var hasStarted = false

    init(useCase: OptimizationCurrenciesUseCaseProtocol) {
        self.useCase = useCase
    }

    init() {
        self.useCase = OptimizationCurrenciesUseCase()
    }

    func dispatch(_ action: OptimizationCurrenciesAction) {
        switch action {
        case .onAppear:
            guard !hasStarted else { return }
            hasStarted = true
            if case .content = state {
                startUpdates()
                return
            }
            if case .error = state {
                state = .idle
            }
            reduce(action)
            if loadInitialData() {
                startUpdates()
            }
        case .onDisappear:
            useCase.stopUpdates()
            hasStarted = false
        case .initialLoaded:
            reduce(action)
        case .pairsUpdated:
            reduce(action)
        case .highlightRiskChanged:
            reduce(action)
        case .loadingFailed:
            reduce(action)
        }
    }
}

private extension OptimizationCurrenciesViewModel {
    func reduce(_ action: OptimizationCurrenciesAction) {
        switch action {
        case .onAppear:
            state = .loading
        case .onDisappear:
            break
        case .initialLoaded(let pairs):
            state = .content(
                OptimizationCurrenciesContentState(
                    pairs: pairs,
                    lastUpdatedPairs: Array(pairs.prefix(Constants.latestPairsCount)),
                    updateCycle: 0,
                    highlightRisk: false
                )
            )
        case .pairsUpdated(let pairs, let lastUpdatedPairs, let updateCycle):
            guard case .content(var content) = state else { return }
            content.pairs = pairs
            content.lastUpdatedPairs = lastUpdatedPairs
            content.updateCycle = updateCycle
            state = .content(content)
        case .highlightRiskChanged(let shouldHighlight):
            guard case .content(var content) = state else { return }
            content.highlightRisk = shouldHighlight
            state = .content(content)
        case .loadingFailed(let message):
            state = .error(message)
        }
    }

    @discardableResult
    func loadInitialData() -> Bool {
        let pairs = useCase.makeInitialPairs()
        if pairs.isEmpty {
            dispatch(.loadingFailed("Не удалось загрузить валюты"))
            return false
        }
        dispatch(.initialLoaded(pairs))
        return true
    }

    func startUpdates() {
        useCase.startUpdates { [weak self] pairs, lastUpdatedPairs, updateCycle in
            self?.dispatch(
                .pairsUpdated(
                    pairs: pairs,
                    lastUpdatedPairs: lastUpdatedPairs,
                    updateCycle: updateCycle
                )
            )
        }
    }
}
