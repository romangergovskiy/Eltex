import Foundation
@testable import eltex_hw

final class LoadP2PAssetsUseCaseMock: LoadP2PAssetsUseCase {
    private(set) var executeCallCount = 0
    private(set) var completions: [(Result<[PairAsset], NetworkServiceError>) -> Void] = []

    func execute(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        executeCallCount += 1
        completions.append(completion)
    }

    func complete(with result: Result<[PairAsset], NetworkServiceError>, at index: Int = 0) {
        guard completions.indices.contains(index) else { return }
        let completion = completions[index]
        completion(result)
    }
}

final class LoadP2POffersUseCaseMock: LoadP2POffersUseCase {
    private(set) var executeCallCount = 0
    private(set) var receivedPairs: [P2PPair] = []
    private(set) var completions: [(Result<[P2POffer], NetworkServiceError>) -> Void] = []

    func execute(pair: P2PPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        executeCallCount += 1
        receivedPairs.append(pair)
        completions.append(completion)
    }

    func complete(with result: Result<[P2POffer], NetworkServiceError>, at index: Int = 0) {
        guard completions.indices.contains(index) else { return }
        let completion = completions[index]
        completion(result)
    }
}

final class ExecuteP2PTradeUseCaseMock: ExecuteP2PTradeUseCase {
    struct Request {
        let wallet: Wallet
        let pair: P2PPair
        let amount: Double
        let rate: Double
    }

    private(set) var executeCallCount = 0
    private(set) var requests: [Request] = []
    private(set) var completions: [(Result<WalletExchangeResult, NetworkServiceError>) -> Void] = []

    func execute(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        executeCallCount += 1
        requests.append(Request(wallet: wallet, pair: pair, amount: amount, rate: rate))
        completions.append(completion)
    }

    func complete(with result: Result<WalletExchangeResult, NetworkServiceError>, at index: Int = 0) {
        guard completions.indices.contains(index) else { return }
        let completion = completions[index]
        completion(result)
    }
}

final class P2PExchangeRepositoryMock: P2PExchangeRepository {
    private(set) var loadAssetsCallCount = 0
    private(set) var loadOffersCallCount = 0
    private(set) var executeTradeCallCount = 0
    private(set) var receivedPairs: [P2PPair] = []
    private(set) var tradeRequests: [(wallet: Wallet, pair: P2PPair, amount: Double, rate: Double)] = []
    private(set) var loadAssetsCompletions: [(Result<[PairAsset], NetworkServiceError>) -> Void] = []
    private(set) var loadOffersCompletions: [(Result<[P2POffer], NetworkServiceError>) -> Void] = []
    private(set) var executeTradeCompletions: [(Result<WalletExchangeResult, NetworkServiceError>) -> Void] = []

    func loadAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        loadAssetsCallCount += 1
        loadAssetsCompletions.append(completion)
    }

    func loadOffers(pair: P2PPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        loadOffersCallCount += 1
        receivedPairs.append(pair)
        loadOffersCompletions.append(completion)
    }

    func executeTrade(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        executeTradeCallCount += 1
        tradeRequests.append((wallet, pair, amount, rate))
        executeTradeCompletions.append(completion)
    }
}

final class P2PExchangeGatewayMock: P2PExchangeGateway {
    private(set) var fetchAssetsCallCount = 0
    private(set) var fetchOffersCallCount = 0
    private(set) var tradeCallCount = 0
    private(set) var receivedPairs: [P2PPair] = []
    private(set) var tradeRequests: [(wallet: Wallet, pair: P2PPair, amount: Double, rate: Double)] = []
    private(set) var fetchAssetsCompletions: [(Result<[PairAsset], NetworkServiceError>) -> Void] = []
    private(set) var fetchOffersCompletions: [(Result<[P2POfferDTO], NetworkServiceError>) -> Void] = []
    private(set) var tradeCompletions: [(Result<WalletExchangeResult, NetworkServiceError>) -> Void] = []

    func fetchAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        fetchAssetsCallCount += 1
        fetchAssetsCompletions.append(completion)
    }

    func fetchOffers(pair: P2PPair, completion: @escaping (Result<[P2POfferDTO], NetworkServiceError>) -> Void) {
        fetchOffersCallCount += 1
        receivedPairs.append(pair)
        fetchOffersCompletions.append(completion)
    }

    func trade(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        tradeCallCount += 1
        tradeRequests.append((wallet, pair, amount, rate))
        tradeCompletions.append(completion)
    }
}

final class P2POfferDataMapperMock: P2POfferDataMapper {
    private(set) var receivedDTO: [[P2POfferDTO]] = []
    var mappedOffers: [P2POffer] = []

    func map(_ dto: [P2POfferDTO]) -> [P2POffer] {
        receivedDTO.append(dto)
        return mappedOffers
    }
}

final class NetworkServiceMock: NetworkServiceProtocol {
    private(set) var loadAvailableAssetsCallCount = 0
    private(set) var loadOffersCallCount = 0
    private(set) var executeExchangeCallCount = 0
    private(set) var requestedPairs: [(source: String, target: String)] = []
    private(set) var exchangeRequests: [(wallet: Wallet, source: String, target: String, amount: Double, rate: Double)] = []
    private(set) var assetsCompletions: [(Result<[PairAsset], NetworkServiceError>) -> Void] = []
    private(set) var offersCompletions: [(Result<[P2POffer], NetworkServiceError>) -> Void] = []
    private(set) var exchangeCompletions: [(Result<WalletExchangeResult, NetworkServiceError>) -> Void] = []

    func loadAvailableAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        loadAvailableAssetsCallCount += 1
        assetsCompletions.append(completion)
    }

    func loadOffers(
        from sourceCode: String,
        to targetCode: String,
        completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void
    ) {
        loadOffersCallCount += 1
        requestedPairs.append((sourceCode, targetCode))
        offersCompletions.append(completion)
    }

    func executeExchange(
        wallet: Wallet,
        from sourceCode: String,
        to targetCode: String,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        executeExchangeCallCount += 1
        exchangeRequests.append((wallet, sourceCode, targetCode, amount, rate))
        exchangeCompletions.append(completion)
    }
}
