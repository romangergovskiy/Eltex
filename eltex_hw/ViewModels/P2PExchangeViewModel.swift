import Foundation

struct P2PExchangeViewData {
    let pairText: String
    let balancesText: String
    let offers: [P2POffer]
}

enum P2PExchangeViewState {
    case idle(P2PExchangeViewData)
    case loading(P2PExchangeViewData)
    case content(P2PExchangeViewData)
    case empty(P2PExchangeViewData)
    case error(P2PExchangeViewData, NetworkServiceError)

    var viewData: P2PExchangeViewData {
        switch self {
        case let .idle(data), let .loading(data), let .content(data), let .empty(data), let .error(data, _):
            return data
        }
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

struct P2PPair {
    let sourceCode: String
    let targetCode: String
}

struct P2POfferDTO {
    let id: UUID
    let seller: String
    let price: Double
    let reserveAmount: Double
}

protocol P2PExchangeGateway {
    func fetchAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void)
    func fetchOffers(pair: P2PPair, completion: @escaping (Result<[P2POfferDTO], NetworkServiceError>) -> Void)
    func trade(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    )
}

final class NetworkP2PExchangeGateway: P2PExchangeGateway {
    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func fetchAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        networkService.loadAvailableAssets(completion: completion)
    }

    func fetchOffers(pair: P2PPair, completion: @escaping (Result<[P2POfferDTO], NetworkServiceError>) -> Void) {
        networkService.loadOffers(from: pair.sourceCode, to: pair.targetCode) { result in
            switch result {
            case let .success(offers):
                let dto = offers.map {
                    P2POfferDTO(id: $0.id, seller: $0.sellerName, price: $0.rate, reserveAmount: $0.reserve)
                }
                completion(.success(dto))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func trade(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        networkService.executeExchange(
            wallet: wallet,
            from: pair.sourceCode,
            to: pair.targetCode,
            amount: amount,
            rate: rate,
            completion: completion
        )
    }
}

protocol P2POfferDataMapper {
    func map(_ dto: [P2POfferDTO]) -> [P2POffer]
}

final class DefaultP2POfferDataMapper: P2POfferDataMapper {
    func map(_ dto: [P2POfferDTO]) -> [P2POffer] {
        dto.map {
            P2POffer(
                id: $0.id,
                sellerName: $0.seller,
                rate: $0.price,
                reserve: $0.reserveAmount
            )
        }
    }
}

protocol P2PExchangeRepository {
    func loadAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void)
    func loadOffers(pair: P2PPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void)
    func executeTrade(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    )
}

final class DefaultP2PExchangeRepository: P2PExchangeRepository {
    private let gateway: P2PExchangeGateway
    private let mapper: P2POfferDataMapper

    init(gateway: P2PExchangeGateway, mapper: P2POfferDataMapper) {
        self.gateway = gateway
        self.mapper = mapper
    }

    func loadAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        gateway.fetchAssets(completion: completion)
    }

    func loadOffers(pair: P2PPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        gateway.fetchOffers(pair: pair) { [mapper] result in
            switch result {
            case let .success(dto):
                completion(.success(mapper.map(dto)))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func executeTrade(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        gateway.trade(wallet: wallet, pair: pair, amount: amount, rate: rate, completion: completion)
    }
}

protocol LoadP2PAssetsUseCase {
    func execute(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void)
}

final class DefaultLoadP2PAssetsUseCase: LoadP2PAssetsUseCase {
    private let repository: P2PExchangeRepository

    init(repository: P2PExchangeRepository) {
        self.repository = repository
    }

    func execute(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        repository.loadAssets(completion: completion)
    }
}

protocol LoadP2POffersUseCase {
    func execute(pair: P2PPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void)
}

final class DefaultLoadP2POffersUseCase: LoadP2POffersUseCase {
    private let repository: P2PExchangeRepository

    init(repository: P2PExchangeRepository) {
        self.repository = repository
    }

    func execute(pair: P2PPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        repository.loadOffers(pair: pair, completion: completion)
    }
}

protocol ExecuteP2PTradeUseCase {
    func execute(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    )
}

final class DefaultExecuteP2PTradeUseCase: ExecuteP2PTradeUseCase {
    private let repository: P2PExchangeRepository

    init(repository: P2PExchangeRepository) {
        self.repository = repository
    }

    func execute(
        wallet: Wallet,
        pair: P2PPair,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        repository.executeTrade(wallet: wallet, pair: pair, amount: amount, rate: rate, completion: completion)
    }
}

final class P2PExchangeViewModel {
    var onStateChange: ((P2PExchangeViewState) -> Void)?
    var onTradeSuccess: ((WalletExchangeResult) -> Void)?

    private let wallet: Wallet
    private let loadAssetsUseCase: LoadP2PAssetsUseCase
    private let loadOffersUseCase: LoadP2POffersUseCase
    private let executeTradeUseCase: ExecuteP2PTradeUseCase
    private let allAssets = PairAssetFactory.makeList(minCount: 140)

    private var apiAssets: [PairAsset] = []
    private var offers: [P2POffer] = []
    private var firstAsset = PairAsset(code: "USD", category: .fiat)
    private var secondAsset = PairAsset(code: "BTC", category: .crypto)
    private var activeOperationsCount = 0
    private var hasLoadedOffers = false
    private var lastError: NetworkServiceError?
    private var offersRequestToken = UUID()

    init(
        wallet: Wallet,
        loadAssetsUseCase: LoadP2PAssetsUseCase,
        loadOffersUseCase: LoadP2POffersUseCase,
        executeTradeUseCase: ExecuteP2PTradeUseCase
    ) {
        self.wallet = wallet
        self.loadAssetsUseCase = loadAssetsUseCase
        self.loadOffersUseCase = loadOffersUseCase
        self.executeTradeUseCase = executeTradeUseCase
    }

    func viewDidLoad() {
        emitState()
        loadAssetsAndOffers()
    }

    func viewWillAppear() {
        emitState()
    }

    func refreshOffers() {
        reloadOffers()
    }

    func pairSelectionInput() -> (allAssets: [PairAsset], first: PairAsset, second: PairAsset, apiAssets: [PairAsset]) {
        (allAssets, firstAsset, secondAsset, apiAssets)
    }

    func applyPair(first: PairAsset, second: PairAsset) {
        guard first.code != second.code else { return }
        firstAsset = first
        secondAsset = second
        lastError = nil
        emitState()
        reloadOffers()
    }

    func executeTrade(amount: Double, offer: P2POffer) {
        let pair = P2PPair(sourceCode: firstAsset.code, targetCode: secondAsset.code)
        beginLoading()
        lastError = nil
        executeTradeUseCase.execute(wallet: wallet, pair: pair, amount: amount, rate: offer.rate) { [weak self] result in
            guard let self else { return }
            self.finishLoading()
            switch result {
            case let .success(exchangeResult):
                self.emitState()
                self.onTradeSuccess?(exchangeResult)
            case let .failure(error):
                self.lastError = error
                self.emitState()
            }
        }
    }

    func pairCodes() -> (source: String, target: String) {
        (firstAsset.code, secondAsset.code)
    }

    private func loadAssetsAndOffers() {
        beginLoading()
        lastError = nil
        loadAssetsUseCase.execute { [weak self] result in
            guard let self else { return }
            self.finishLoading()
            switch result {
            case let .success(assets):
                self.apiAssets = assets
                self.alignPairWithAvailableAssets()
                self.reloadOffers()
            case let .failure(error):
                self.lastError = error
                self.emitState()
            }
        }
    }

    private func alignPairWithAvailableAssets() {
        guard !apiAssets.isEmpty else { return }
        if !apiAssets.contains(where: { $0.code == firstAsset.code }) {
            firstAsset = apiAssets.first ?? firstAsset
        }
        if !apiAssets.contains(where: { $0.code == secondAsset.code }) || secondAsset.code == firstAsset.code {
            secondAsset = apiAssets.first(where: { $0.code != firstAsset.code }) ?? secondAsset
        }
        emitState()
    }

    private func reloadOffers() {
        let requestToken = UUID()
        offersRequestToken = requestToken
        let pair = P2PPair(sourceCode: firstAsset.code, targetCode: secondAsset.code)
        beginLoading()
        lastError = nil
        loadOffersUseCase.execute(pair: pair) { [weak self] result in
            guard let self else { return }
            guard self.offersRequestToken == requestToken else { return }
            self.finishLoading()
            self.hasLoadedOffers = true
            switch result {
            case let .success(offers):
                self.offers = offers
                self.lastError = nil
                self.emitState()
            case let .failure(error):
                self.offers = []
                self.lastError = error
                self.emitState()
            }
        }
    }

    private func beginLoading() {
        activeOperationsCount += 1
        emitState()
    }

    private func finishLoading() {
        activeOperationsCount = max(0, activeOperationsCount - 1)
        emitState()
    }

    private func emitState() {
        let pairBalances = wallet.pairBalances(base: firstAsset.code, quote: secondAsset.code)
        let source = pairBalances[firstAsset.code, default: 0]
        let target = pairBalances[secondAsset.code, default: 0]
        let balances = String(
            format: "Баланс: %@ %.2f\nБаланс: %@ %.2f",
            firstAsset.code,
            source,
            secondAsset.code,
            target
        )
        let data = P2PExchangeViewData(
            pairText: "\(firstAsset.code)-\(secondAsset.code)",
            balancesText: balances,
            offers: offers
        )

        if activeOperationsCount > 0 {
            onStateChange?(.loading(data))
            return
        }
        if let error = lastError {
            onStateChange?(.error(data, error))
            return
        }
        if !hasLoadedOffers {
            onStateChange?(.idle(data))
            return
        }
        if offers.isEmpty {
            onStateChange?(.empty(data))
            return
        }
        onStateChange?(.content(data))
    }
}
