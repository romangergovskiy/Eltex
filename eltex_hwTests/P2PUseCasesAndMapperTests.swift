import XCTest
@testable import eltex_hw

final class P2PUseCasesAndMapperTests: XCTestCase {
    func test_mapper_mapsDTOToDomain() {
        let mapper = DefaultP2POfferDataMapper()
        let dto = [
            P2POfferDTO(id: UUID(), seller: "seller1", price: 1.5, reserveAmount: 1000),
            P2POfferDTO(id: UUID(), seller: "seller2", price: 1.8, reserveAmount: 500)
        ]

        let offers = mapper.map(dto)

        XCTAssertEqual(offers.count, 2)
        XCTAssertEqual(offers[0].sellerName, "seller1")
        XCTAssertEqual(offers[0].rate, 1.5)
        XCTAssertEqual(offers[0].reserve, 1000)
        XCTAssertEqual(offers[1].sellerName, "seller2")
        XCTAssertEqual(offers[1].rate, 1.8)
        XCTAssertEqual(offers[1].reserve, 500)
    }

    func test_mapper_mapsEmptyDTOToEmptyDomain() {
        let mapper = DefaultP2POfferDataMapper()

        let offers = mapper.map([])

        XCTAssertTrue(offers.isEmpty)
    }

    func test_loadAssetsUseCase_callsRepositoryLoadAssets() {
        let repository = P2PExchangeRepositoryMock()
        let sut = DefaultLoadP2PAssetsUseCase(repository: repository)
        let expectation = expectation(description: "load assets")

        sut.execute { _ in
            expectation.fulfill()
        }

        XCTAssertEqual(repository.loadAssetsCallCount, 1)
        repository.loadAssetsCompletions.first?(.success([PairAsset(code: "USD", category: .fiat)]))

        wait(for: [expectation], timeout: 1.0)
    }

    func test_loadAssetsUseCase_propagatesFailureFromRepository() {
        let repository = P2PExchangeRepositoryMock()
        let sut = DefaultLoadP2PAssetsUseCase(repository: repository)
        let expectation = expectation(description: "load assets failure")
        var receivedError: NetworkServiceError?

        sut.execute { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        repository.loadAssetsCompletions.first?(.failure(.forbidden))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .forbidden)
    }

    func test_loadOffersUseCase_callsRepositoryLoadOffersWithPair() {
        let repository = P2PExchangeRepositoryMock()
        let sut = DefaultLoadP2POffersUseCase(repository: repository)
        let expectation = expectation(description: "load offers")
        let pair = P2PPair(sourceCode: "EUR", targetCode: "BTC")

        sut.execute(pair: pair) { _ in
            expectation.fulfill()
        }

        XCTAssertEqual(repository.loadOffersCallCount, 1)
        XCTAssertEqual(repository.receivedPairs.first?.sourceCode, "EUR")
        XCTAssertEqual(repository.receivedPairs.first?.targetCode, "BTC")
        repository.loadOffersCompletions.first?(.success([]))

        wait(for: [expectation], timeout: 1.0)
    }

    func test_loadOffersUseCase_propagatesFailureFromRepository() {
        let repository = P2PExchangeRepositoryMock()
        let sut = DefaultLoadP2POffersUseCase(repository: repository)
        let expectation = expectation(description: "load offers failure")
        let pair = P2PPair(sourceCode: "EUR", targetCode: "BTC")
        var receivedError: NetworkServiceError?

        sut.execute(pair: pair) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        repository.loadOffersCompletions.first?(.failure(.noInternet))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .noInternet)
    }

    func test_executeTradeUseCase_callsRepositoryExecuteTrade() {
        let repository = P2PExchangeRepositoryMock()
        let sut = DefaultExecuteP2PTradeUseCase(repository: repository)
        let expectation = expectation(description: "execute trade")
        let wallet = Wallet(initialBalances: ["USD": 100], autoCreditAmount: 50)
        let pair = P2PPair(sourceCode: "USD", targetCode: "BTC")

        sut.execute(wallet: wallet, pair: pair, amount: 20, rate: 2) { _ in
            expectation.fulfill()
        }

        XCTAssertEqual(repository.executeTradeCallCount, 1)
        XCTAssertEqual(repository.tradeRequests.first?.pair.sourceCode, "USD")
        XCTAssertEqual(repository.tradeRequests.first?.pair.targetCode, "BTC")
        XCTAssertEqual(repository.tradeRequests.first?.amount, 20)
        XCTAssertEqual(repository.tradeRequests.first?.rate, 2)
        repository.executeTradeCompletions.first?(.success(WalletExchangeResult(spent: 20, received: 40)))

        wait(for: [expectation], timeout: 1.0)
    }

    func test_executeTradeUseCase_propagatesFailureFromRepository() {
        let repository = P2PExchangeRepositoryMock()
        let sut = DefaultExecuteP2PTradeUseCase(repository: repository)
        let expectation = expectation(description: "execute trade failure")
        let wallet = Wallet(initialBalances: ["USD": 100], autoCreditAmount: 50)
        let pair = P2PPair(sourceCode: "USD", targetCode: "BTC")
        var receivedError: NetworkServiceError?

        sut.execute(wallet: wallet, pair: pair, amount: 20, rate: 2) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        repository.executeTradeCompletions.first?(.failure(.server))

        wait(for: [expectation], timeout: 1.0)
        guard let error = receivedError else {
            return XCTFail("Expected error")
        }
        assertError(error, equals: .server)
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
