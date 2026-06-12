import XCTest
@testable import eltex_hw

final class NetworkP2PExchangeGatewayTests: XCTestCase {
    private var networkService: NetworkServiceMock!
    private var sut: NetworkP2PExchangeGateway!

    override func setUp() {
        super.setUp()
        networkService = NetworkServiceMock()
        sut = NetworkP2PExchangeGateway(networkService: networkService)
    }

    override func tearDown() {
        sut = nil
        networkService = nil
        super.tearDown()
    }

    func test_fetchAssets_returnsAssetsFromNetworkService() {
        let expectation = expectation(description: "fetch assets")
        var receivedAssets: [PairAsset] = []

        sut.fetchAssets { result in
            if case let .success(assets) = result {
                receivedAssets = assets
            }
            expectation.fulfill()
        }

        XCTAssertEqual(networkService.loadAvailableAssetsCallCount, 1)
        networkService.assetsCompletions.first?(.success([PairAsset(code: "USD", category: .fiat)]))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedAssets.map(\.code), ["USD"])
    }

    func test_fetchAssets_whenNetworkFails_returnsFailure() {
        let expectation = expectation(description: "fetch assets failure")
        var receivedError: NetworkServiceError?

        sut.fetchAssets { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        XCTAssertEqual(networkService.loadAvailableAssetsCallCount, 1)
        networkService.assetsCompletions.first?(.failure(.server))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .server)
    }

    func test_fetchOffers_mapsOfferToDTO() {
        let expectation = expectation(description: "fetch offers")
        var dto: [P2POfferDTO] = []

        sut.fetchOffers(pair: P2PPair(sourceCode: "USD", targetCode: "BTC")) { result in
            if case let .success(offers) = result {
                dto = offers
            }
            expectation.fulfill()
        }

        XCTAssertEqual(networkService.loadOffersCallCount, 1)
        XCTAssertEqual(networkService.requestedPairs.first?.source, "USD")
        XCTAssertEqual(networkService.requestedPairs.first?.target, "BTC")

        networkService.offersCompletions.first?(.success([
            P2POffer(id: UUID(), sellerName: "seller", rate: 1.5, reserve: 700)
        ]))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(dto.count, 1)
        XCTAssertEqual(dto.first?.seller, "seller")
        XCTAssertEqual(dto.first?.price, 1.5)
        XCTAssertEqual(dto.first?.reserveAmount, 700)
    }

    func test_fetchOffers_whenNetworkFails_returnsFailure() {
        let expectation = expectation(description: "fetch offers failure")
        var receivedError: NetworkServiceError?

        sut.fetchOffers(pair: P2PPair(sourceCode: "USD", targetCode: "BTC")) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        networkService.offersCompletions.first?(.failure(.forbidden))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .forbidden)
    }

    func test_trade_passesValuesToNetworkService() {
        let expectation = expectation(description: "trade")
        let wallet = Wallet(initialBalances: ["USD": 100], autoCreditAmount: 50)
        var result: WalletExchangeResult?

        sut.trade(
            wallet: wallet,
            pair: P2PPair(sourceCode: "USD", targetCode: "BTC"),
            amount: 25,
            rate: 2
        ) { response in
            if case let .success(value) = response {
                result = value
            }
            expectation.fulfill()
        }

        XCTAssertEqual(networkService.executeExchangeCallCount, 1)
        XCTAssertEqual(networkService.exchangeRequests.first?.source, "USD")
        XCTAssertEqual(networkService.exchangeRequests.first?.target, "BTC")
        XCTAssertEqual(networkService.exchangeRequests.first?.amount, 25)
        XCTAssertEqual(networkService.exchangeRequests.first?.rate, 2)

        networkService.exchangeCompletions.first?(.success(WalletExchangeResult(spent: 25, received: 50)))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(result?.spent, 25)
        XCTAssertEqual(result?.received, 50)
    }

    func test_trade_whenNetworkFails_returnsFailure() {
        let expectation = expectation(description: "trade failure")
        let wallet = Wallet(initialBalances: ["USD": 100], autoCreditAmount: 50)
        var receivedError: NetworkServiceError?

        sut.trade(
            wallet: wallet,
            pair: P2PPair(sourceCode: "USD", targetCode: "BTC"),
            amount: 25,
            rate: 2
        ) { response in
            if case let .failure(error) = response {
                receivedError = error
            }
            expectation.fulfill()
        }

        XCTAssertEqual(networkService.executeExchangeCallCount, 1)
        networkService.exchangeCompletions.first?(.failure(.noInternet))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .noInternet)
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
}
