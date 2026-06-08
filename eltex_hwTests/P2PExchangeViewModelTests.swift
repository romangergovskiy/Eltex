import XCTest
@testable import eltex_hw

final class P2PExchangeViewModelTests: XCTestCase {
    private var loadAssetsUseCase: LoadP2PAssetsUseCaseMock!
    private var loadOffersUseCase: LoadP2POffersUseCaseMock!
    private var executeTradeUseCase: ExecuteP2PTradeUseCaseMock!
    private var wallet: Wallet!
    private var sut: P2PExchangeViewModel!
    private var capturedStates: [P2PExchangeViewState]!
    private let defaultAssets = [
        PairAsset(code: "USD", category: .fiat),
        PairAsset(code: "BTC", category: .crypto),
        PairAsset(code: "EUR", category: .fiat)
    ]

    override func setUp() {
        super.setUp()
        loadAssetsUseCase = LoadP2PAssetsUseCaseMock()
        loadOffersUseCase = LoadP2POffersUseCaseMock()
        executeTradeUseCase = ExecuteP2PTradeUseCaseMock()
        wallet = Wallet(initialBalances: ["USD": 1000, "BTC": 2, "EUR": 300], autoCreditAmount: 500)
        sut = P2PExchangeViewModel(
            wallet: wallet,
            loadAssetsUseCase: loadAssetsUseCase,
            loadOffersUseCase: loadOffersUseCase,
            executeTradeUseCase: executeTradeUseCase
        )
        capturedStates = []
        sut.onStateChange = { [weak self] state in
            self?.capturedStates.append(state)
        }
    }

    override func tearDown() {
        sut = nil
        wallet = nil
        executeTradeUseCase = nil
        loadOffersUseCase = nil
        loadAssetsUseCase = nil
        capturedStates = nil
        super.tearDown()
    }

    func test_viewWillAppear_emitsCurrentIdleState() {
        sut.viewWillAppear()

        guard case let .idle(data)? = capturedStates.last else {
            return XCTFail("Expected idle state")
        }
        XCTAssertEqual(data.pairText, "USD-BTC")
        XCTAssertEqual(data.offers.count, 0)
    }

    func test_viewDidLoad_requestsAssetsThenOffersAndEmitsContent() {
        let offer = makeOffer(name: "seller", rate: 1.1, reserve: 500)

        sut.viewDidLoad()

        XCTAssertEqual(loadAssetsUseCase.executeCallCount, 1)
        loadAssetsUseCase.complete(with: .success(defaultAssets))

        XCTAssertEqual(loadOffersUseCase.executeCallCount, 1)
        XCTAssertEqual(loadOffersUseCase.receivedPairs.first?.sourceCode, "USD")
        XCTAssertEqual(loadOffersUseCase.receivedPairs.first?.targetCode, "BTC")

        loadOffersUseCase.complete(with: .success([offer]))

        guard case let .content(data)? = capturedStates.last else {
            return XCTFail("Expected content state")
        }
        XCTAssertEqual(data.pairText, "USD-BTC")
        XCTAssertEqual(data.offers.count, 1)
        XCTAssertEqual(data.offers.first?.sellerName, "seller")
    }

    func test_viewDidLoad_whenAssetsFail_emitsErrorAndSkipsOffersRequest() {
        sut.viewDidLoad()

        loadAssetsUseCase.complete(with: .failure(.noInternet))

        XCTAssertEqual(loadOffersUseCase.executeCallCount, 0)
        guard case let .error(_, error)? = capturedStates.last else {
            return XCTFail("Expected error state")
        }
        assertError(error, equals: .noInternet)
    }

    func test_viewDidLoad_whenOffersFail_emitsErrorState() {
        sut.viewDidLoad()

        loadAssetsUseCase.complete(with: .success(defaultAssets))
        loadOffersUseCase.complete(with: .failure(.server))

        guard case let .error(data, error)? = capturedStates.last else {
            return XCTFail("Expected error state")
        }
        XCTAssertEqual(data.pairText, "USD-BTC")
        XCTAssertEqual(data.offers.count, 0)
        assertError(error, equals: .server)
    }

    func test_viewDidLoad_whenOffersEmpty_emitsEmptyState() {
        sut.viewDidLoad()

        loadAssetsUseCase.complete(with: .success(defaultAssets))
        loadOffersUseCase.complete(with: .success([]))

        guard case let .empty(data)? = capturedStates.last else {
            return XCTFail("Expected empty state")
        }
        XCTAssertEqual(data.pairText, "USD-BTC")
        XCTAssertTrue(data.offers.isEmpty)
    }

    func test_pairSelectionInput_returnsCurrentAndApiAssets() {
        sut.viewDidLoad()
        loadAssetsUseCase.complete(with: .success(defaultAssets))

        let input = sut.pairSelectionInput()

        XCTAssertEqual(input.first.code, "USD")
        XCTAssertEqual(input.second.code, "BTC")
        XCTAssertEqual(input.apiAssets.map(\.code), ["USD", "BTC", "EUR"])
        XCTAssertGreaterThanOrEqual(input.allAssets.count, 140)
    }

    func test_refreshOffers_requestsOffersForCurrentPair() {
        sut.viewDidLoad()
        loadAssetsUseCase.complete(with: .success(defaultAssets))
        loadOffersUseCase.complete(with: .success([]), at: 0)

        sut.refreshOffers()

        XCTAssertEqual(loadOffersUseCase.executeCallCount, 2)
        XCTAssertEqual(loadOffersUseCase.receivedPairs[1].sourceCode, "USD")
        XCTAssertEqual(loadOffersUseCase.receivedPairs[1].targetCode, "BTC")
    }

    func test_applyPair_whenCodesMatch_doesNothing() {
        sut.applyPair(
            first: PairAsset(code: "USD", category: .fiat),
            second: PairAsset(code: "USD", category: .fiat)
        )

        XCTAssertEqual(sut.pairCodes().source, "USD")
        XCTAssertEqual(sut.pairCodes().target, "BTC")
        XCTAssertEqual(loadOffersUseCase.executeCallCount, 0)
    }

    func test_applyPair_whenCodesDiffer_updatesPairAndReloadsOffers() {
        sut.applyPair(
            first: PairAsset(code: "EUR", category: .fiat),
            second: PairAsset(code: "BTC", category: .crypto)
        )

        XCTAssertEqual(sut.pairCodes().source, "EUR")
        XCTAssertEqual(sut.pairCodes().target, "BTC")
        XCTAssertEqual(loadOffersUseCase.executeCallCount, 1)
        XCTAssertEqual(loadOffersUseCase.receivedPairs.first?.sourceCode, "EUR")
        XCTAssertEqual(loadOffersUseCase.receivedPairs.first?.targetCode, "BTC")
    }

    func test_executeTrade_onSuccess_callsTradeSuccessCallback() {
        var callbackResult: WalletExchangeResult?
        let offer = makeOffer(name: "seller", rate: 2.0, reserve: 50)
        sut.onTradeSuccess = { result in
            callbackResult = result
        }

        sut.executeTrade(amount: 10, offer: offer)

        XCTAssertEqual(executeTradeUseCase.executeCallCount, 1)
        XCTAssertEqual(executeTradeUseCase.requests.first?.pair.sourceCode, "USD")
        XCTAssertEqual(executeTradeUseCase.requests.first?.pair.targetCode, "BTC")
        XCTAssertEqual(executeTradeUseCase.requests.first?.amount, 10)
        XCTAssertEqual(executeTradeUseCase.requests.first?.rate, 2.0)

        executeTradeUseCase.complete(with: .success(WalletExchangeResult(spent: 10, received: 20)))

        XCTAssertEqual(callbackResult?.spent, 10)
        XCTAssertEqual(callbackResult?.received, 20)
        if case .error = capturedStates.last {
            XCTFail("Expected non error state")
        }
    }

    func test_executeTrade_onFailure_emitsErrorState() {
        let offer = makeOffer(name: "seller", rate: 2.0, reserve: 50)

        sut.executeTrade(amount: 8, offer: offer)
        executeTradeUseCase.complete(with: .failure(.forbidden))

        guard case let .error(_, error)? = capturedStates.last else {
            return XCTFail("Expected error state")
        }
        assertError(error, equals: .forbidden)
    }

    func test_reloadOffers_ignoresOutdatedResponse() {
        let oldOffer = makeOffer(name: "old", rate: 1.0, reserve: 10)
        let newOffer = makeOffer(name: "new", rate: 2.0, reserve: 100)

        sut.viewDidLoad()
        loadAssetsUseCase.complete(with: .success(defaultAssets))
        sut.applyPair(
            first: PairAsset(code: "EUR", category: .fiat),
            second: PairAsset(code: "BTC", category: .crypto)
        )

        loadOffersUseCase.complete(with: .success([newOffer]), at: 1)
        loadOffersUseCase.complete(with: .success([oldOffer]), at: 0)

        guard case let .content(data)? = capturedStates.last else {
            return XCTFail("Expected content state")
        }
        XCTAssertEqual(data.pairText, "EUR-BTC")
        XCTAssertEqual(data.offers.count, 1)
        XCTAssertEqual(data.offers.first?.sellerName, "new")
        XCTAssertFalse(capturedStates.last?.isLoading ?? true)
    }

    func test_viewModel_doesNotRetainItself_duringAssetsRequest() {
        let assetsUseCase = LoadP2PAssetsUseCaseMock()
        let offersUseCase = LoadP2POffersUseCaseMock()
        let tradeUseCase = ExecuteP2PTradeUseCaseMock()
        weak var weakViewModel: P2PExchangeViewModel?

        autoreleasepool {
            var viewModel: P2PExchangeViewModel? = P2PExchangeViewModel(
                wallet: wallet,
                loadAssetsUseCase: assetsUseCase,
                loadOffersUseCase: offersUseCase,
                executeTradeUseCase: tradeUseCase
            )
            weakViewModel = viewModel
            viewModel?.viewDidLoad()
            viewModel = nil
        }

        XCTAssertNil(weakViewModel)
    }

    func test_viewModel_doesNotRetainItself_duringTradeRequest() {
        let assetsUseCase = LoadP2PAssetsUseCaseMock()
        let offersUseCase = LoadP2POffersUseCaseMock()
        let tradeUseCase = ExecuteP2PTradeUseCaseMock()
        weak var weakViewModel: P2PExchangeViewModel?
        let offer = makeOffer(name: "seller", rate: 2.0, reserve: 500)

        autoreleasepool {
            var viewModel: P2PExchangeViewModel? = P2PExchangeViewModel(
                wallet: wallet,
                loadAssetsUseCase: assetsUseCase,
                loadOffersUseCase: offersUseCase,
                executeTradeUseCase: tradeUseCase
            )
            weakViewModel = viewModel
            viewModel?.executeTrade(amount: 20, offer: offer)
            viewModel = nil
        }

        XCTAssertNil(weakViewModel)
    }

    private func assertError(_ error: NetworkServiceError, equals expected: NetworkServiceError) {
        switch (error, expected) {
        case (.noInternet, .noInternet),
             (.parsing, .parsing),
             (.forbidden, .forbidden),
             (.server, .server),
             (.unknown, .unknown):
            return
        default:
            XCTFail("Unexpected error case")
        }
    }

    private func makeOffer(name: String, rate: Double, reserve: Double) -> P2POffer {
        P2POffer(id: UUID(), sellerName: name, rate: rate, reserve: reserve)
    }
}
