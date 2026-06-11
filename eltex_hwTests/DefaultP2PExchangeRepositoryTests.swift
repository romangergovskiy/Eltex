import XCTest
@testable import eltex_hw

final class DefaultP2PExchangeRepositoryTests: XCTestCase {
    private var gateway: P2PExchangeGatewayMock!
    private var mapper: P2POfferDataMapperMock!
    private var sut: DefaultP2PExchangeRepository!

    override func setUp() {
        super.setUp()
        gateway = P2PExchangeGatewayMock()
        mapper = P2POfferDataMapperMock()
        sut = DefaultP2PExchangeRepository(gateway: gateway, mapper: mapper)
    }

    override func tearDown() {
        sut = nil
        mapper = nil
        gateway = nil
        super.tearDown()
    }

    func test_loadAssets_passesResultFromGateway() {
        let expectation = expectation(description: "load assets")
        var resultAssets: [PairAsset]?

        sut.loadAssets { result in
            if case let .success(assets) = result {
                resultAssets = assets
            }
            expectation.fulfill()
        }

        XCTAssertEqual(gateway.fetchAssetsCallCount, 1)
        gateway.fetchAssetsCompletions.first?(.success([PairAsset(code: "USD", category: .fiat)]))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(resultAssets?.map(\.code), ["USD"])
    }

    func test_loadAssets_whenGatewayFails_returnsFailure() {
        let expectation = expectation(description: "load assets failure")
        var receivedError: NetworkServiceError?

        sut.loadAssets { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        XCTAssertEqual(gateway.fetchAssetsCallCount, 1)
        gateway.fetchAssetsCompletions.first?(.failure(.noInternet))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .noInternet)
    }

    func test_loadOffers_mapsDTOUsingMapper() {
        let expectation = expectation(description: "load offers")
        let pair = P2PPair(sourceCode: "USD", targetCode: "BTC")
        let dto = [P2POfferDTO(id: UUID(), seller: "dtoSeller", price: 1.2, reserveAmount: 500)]
        mapper.mappedOffers = [P2POffer(id: UUID(), sellerName: "mappedSeller", rate: 1.1, reserve: 400)]
        var offers: [P2POffer] = []

        sut.loadOffers(pair: pair) { result in
            if case let .success(value) = result {
                offers = value
            }
            expectation.fulfill()
        }

        XCTAssertEqual(gateway.fetchOffersCallCount, 1)
        XCTAssertEqual(gateway.receivedPairs.first?.sourceCode, "USD")
        XCTAssertEqual(gateway.receivedPairs.first?.targetCode, "BTC")

        gateway.fetchOffersCompletions.first?(.success(dto))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mapper.receivedDTO.first?.first?.seller, "dtoSeller")
        XCTAssertEqual(offers.first?.sellerName, "mappedSeller")
    }

    func test_loadOffers_whenGatewayFails_returnsFailureWithoutMapping() {
        let expectation = expectation(description: "load offers failure")
        let pair = P2PPair(sourceCode: "USD", targetCode: "BTC")
        var receivedError: NetworkServiceError?

        sut.loadOffers(pair: pair) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        gateway.fetchOffersCompletions.first?(.failure(.server))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mapper.receivedDTO.isEmpty)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .server)
    }

    func test_executeTrade_passesParametersAndResultFromGateway() {
        let expectation = expectation(description: "execute trade")
        let wallet = Wallet(initialBalances: ["USD": 100], autoCreditAmount: 50)
        let pair = P2PPair(sourceCode: "USD", targetCode: "BTC")
        var tradeResult: WalletExchangeResult?

        sut.executeTrade(wallet: wallet, pair: pair, amount: 30, rate: 2) { result in
            if case let .success(value) = result {
                tradeResult = value
            }
            expectation.fulfill()
        }

        XCTAssertEqual(gateway.tradeCallCount, 1)
        XCTAssertEqual(gateway.tradeRequests.first?.pair.sourceCode, "USD")
        XCTAssertEqual(gateway.tradeRequests.first?.pair.targetCode, "BTC")
        XCTAssertEqual(gateway.tradeRequests.first?.amount, 30)
        XCTAssertEqual(gateway.tradeRequests.first?.rate, 2)

        gateway.tradeCompletions.first?(.success(WalletExchangeResult(spent: 30, received: 60)))

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(tradeResult?.spent, 30)
        XCTAssertEqual(tradeResult?.received, 60)
    }

    func test_executeTrade_whenGatewayFails_returnsFailure() {
        let expectation = expectation(description: "execute trade failure")
        let wallet = Wallet(initialBalances: ["USD": 100], autoCreditAmount: 50)
        let pair = P2PPair(sourceCode: "USD", targetCode: "BTC")
        var receivedError: NetworkServiceError?

        sut.executeTrade(wallet: wallet, pair: pair, amount: 30, rate: 2) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        XCTAssertEqual(gateway.tradeCallCount, 1)
        gateway.tradeCompletions.first?(.failure(.forbidden))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .forbidden)
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
