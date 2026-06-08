import Foundation
import Combine

// MARK: - Errors

enum NetworkServiceError: Error {
    case noInternet
    case parsing
    case forbidden
    case server
    case unknown

    var title: String {
        switch self {
        case .noInternet:
            return "Нет интернета"
        case .parsing:
            return "Ошибка данных"
        case .forbidden:
            return "Доступ ограничен"
        case .server:
            return "Ошибка сервера"
        case .unknown:
            return "Ошибка"
        }
    }

    var message: String {
        switch self {
        case .noInternet:
            return "Проверьте подключение к интернету и попробуйте снова."
        case .parsing:
            return "Что-то пошло не так, попробуйте позже."
        case .forbidden:
            return "У вас нет прав на просмотр данного раздела."
        case .server:
            return "Сервис временно недоступен."
        case .unknown:
            return "Не удалось выполнить запрос."
        }
    }
}

struct P2POffer {
    let id: UUID
    let sellerName: String
    let rate: Double
    let reserve: Double
}

// MARK: - Service

protocol NetworkServiceProtocol: AnyObject {
    func loadAvailableAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void)
    func loadOffers(
        from sourceCode: String,
        to targetCode: String,
        completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void
    )
    func executeExchange(
        wallet: Wallet,
        from sourceCode: String,
        to targetCode: String,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    )
}

final class NetworkService: NetworkServiceProtocol {

    private struct MarketPair {
        let base: String
        let quote: String
        let price: Double
    }

    private struct BinanceTickerDTO: Decodable {
        let symbol: String
        let price: String
    }

    private let session: URLSession
    private let cacheQueue = DispatchQueue(label: "network.service.cache.queue")
    private var cachedPairs: [MarketPair] = []
    private var cachedAssets: [PairAsset] = []
    private var activeRequests: [UUID: AnyCancellable] = [:]

    // MARK: Lifecycle

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Public

    func loadAvailableAssets(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        if AppConfig.isNetworkWithCombine {
            let requestID = UUID()
            let cancellable = loadAvailableAssetsPublisher()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completionResult in
                        self?.activeRequests.removeValue(forKey: requestID)
                        if case let .failure(error) = completionResult {
                            completion(.failure(error))
                        }
                    },
                    receiveValue: { assets in
                        completion(.success(assets))
                    }
                )
            activeRequests[requestID] = cancellable
            return
        }
        loadAvailableAssetsLegacy(completion: completion)
    }

    func loadOffers(
        from sourceCode: String,
        to targetCode: String,
        completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void
    ) {
        if AppConfig.isNetworkWithCombine {
            let requestID = UUID()
            let cancellable = loadOffersPublisher(from: sourceCode, to: targetCode)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completionResult in
                        self?.activeRequests.removeValue(forKey: requestID)
                        if case let .failure(error) = completionResult {
                            completion(.failure(error))
                        }
                    },
                    receiveValue: { offers in
                        completion(.success(offers))
                    }
                )
            activeRequests[requestID] = cancellable
            return
        }
        loadOffersLegacy(from: sourceCode, to: targetCode, completion: completion)
    }

    func loadAvailableAssetsPublisher() -> AnyPublisher<[PairAsset], NetworkServiceError> {
        loadMarketPairsPublisher()
            .tryMap { [weak self] pairs -> [PairAsset] in
                guard let self else {
                    throw NetworkServiceError.unknown
                }
                let assets = self.makeAssets(from: pairs)
                self.cacheQueue.async {
                    self.cachedAssets = assets
                }
                guard !assets.isEmpty else {
                    throw NetworkServiceError.parsing
                }
                return assets
            }
            .mapError { [weak self] error in
                self?.mapCombineError(error) ?? .unknown
            }
            .eraseToAnyPublisher()
    }

    func loadOffersPublisher(from sourceCode: String, to targetCode: String) -> AnyPublisher<[P2POffer], NetworkServiceError> {
        loadMarketPairsPublisher()
            .tryMap { [weak self] pairs in
                guard let self else {
                    throw NetworkServiceError.unknown
                }
                guard let marketRate = self.resolveRate(
                    from: sourceCode,
                    to: targetCode,
                    pairs: pairs
                ) else {
                    throw NetworkServiceError.parsing
                }
                return self.makeOffers(marketRate: marketRate)
            }
            .mapError { [weak self] error in
                self?.mapCombineError(error) ?? .unknown
            }
            .eraseToAnyPublisher()
    }

    private func loadAvailableAssetsLegacy(completion: @escaping (Result<[PairAsset], NetworkServiceError>) -> Void) {
        loadMarketPairs { [weak self] result in
            guard let self else {
                DispatchQueue.main.async {
                    completion(.failure(.unknown))
                }
                return
            }
            switch result {
            case let .success(pairs):
                let assets = self.makeAssets(from: pairs)
                self.cacheQueue.async {
                    self.cachedAssets = assets
                }
                DispatchQueue.main.async {
                    completion(.success(assets))
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func loadOffersLegacy(
        from sourceCode: String,
        to targetCode: String,
        completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void
    ) {
        loadMarketPairs { [weak self] result in
            guard let self else {
                DispatchQueue.main.async {
                    completion(.failure(.unknown))
                }
                return
            }
            switch result {
            case let .success(pairs):
                guard let marketRate = self.resolveRate(
                    from: sourceCode,
                    to: targetCode,
                    pairs: pairs
                ) else {
                    DispatchQueue.main.async {
                        completion(.failure(.parsing))
                    }
                    return
                }

                let offers = self.makeOffers(marketRate: marketRate)
                DispatchQueue.main.async {
                    completion(.success(offers))
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func executeExchange(
        wallet: Wallet,
        from sourceCode: String,
        to targetCode: String,
        amount: Double,
        rate: Double,
        completion: @escaping (Result<WalletExchangeResult, NetworkServiceError>) -> Void
    ) {
        guard amount > 0, rate > 0 else {
            completion(.failure(.parsing))
            return
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    completion(.failure(.unknown))
                }
                return
            }
            if Bool.random() {
                let result = wallet.exchange(
                    from: sourceCode,
                    to: targetCode,
                    amount: amount,
                    rate: rate
                )
                DispatchQueue.main.async {
                    completion(.success(result))
                }
                return
            }

            self.performFailedRequest { error in
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Private

private extension NetworkService {
    private func loadMarketPairsPublisher() -> AnyPublisher<[MarketPair], NetworkServiceError> {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price") else {
            return Fail(error: .unknown).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12

        return session.dataTaskPublisher(for: request)
            .tryMap { [weak self] output -> Data in
                if let mapped = self?.mapError(error: nil, response: output.response) {
                    throw mapped
                }
                return output.data
            }
            .decode(type: [BinanceTickerDTO].self, decoder: JSONDecoder())
            .tryMap { [weak self] decoded -> [MarketPair] in
                guard let self else {
                    throw NetworkServiceError.unknown
                }
                let pairs = decoded.compactMap { ticker -> MarketPair? in
                    guard let value = Double(ticker.price) else { return nil }
                    guard let parsed = self.parseSymbol(ticker.symbol) else { return nil }
                    guard value > 0 else { return nil }
                    return MarketPair(base: parsed.base, quote: parsed.quote, price: value)
                }
                guard !pairs.isEmpty else {
                    throw NetworkServiceError.parsing
                }
                self.cacheQueue.async {
                    self.cachedPairs = pairs
                }
                return pairs
            }
            .mapError { [weak self] error in
                self?.mapCombineError(error) ?? .unknown
            }
            .eraseToAnyPublisher()
    }

    private func loadMarketPairs(completion: @escaping (Result<[MarketPair], NetworkServiceError>) -> Void) {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price") else {
            completion(.failure(.unknown))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else {
                completion(.failure(.unknown))
                return
            }
            if let mapped = self.mapError(error: error, response: response) {
                completion(.failure(mapped))
                return
            }

            guard let data else {
                completion(.failure(.parsing))
                return
            }

            do {
                let decoded = try JSONDecoder().decode([BinanceTickerDTO].self, from: data)
                let pairs = decoded.compactMap { ticker -> MarketPair? in
                    guard let value = Double(ticker.price) else { return nil }
                    guard let parsed = self.parseSymbol(ticker.symbol) else { return nil }
                    guard value > 0 else { return nil }
                    return MarketPair(base: parsed.base, quote: parsed.quote, price: value)
                }
                guard !pairs.isEmpty else {
                    completion(.failure(.parsing))
                    return
                }
                self.cacheQueue.async {
                    self.cachedPairs = pairs
                }
                completion(.success(pairs))
            } catch {
                completion(.failure(.parsing))
            }
        }.resume()
    }

    func mapCombineError(_ error: Error) -> NetworkServiceError {
        if let serviceError = error as? NetworkServiceError {
            return serviceError
        }
        if let urlError = error as? URLError {
            return mapError(error: urlError, response: nil) ?? .unknown
        }
        if error is DecodingError {
            return .parsing
        }
        return .unknown
    }

    func performFailedRequest(completion: @escaping (NetworkServiceError) -> Void) {
        let urlString = "https://p2p-exchange.invalid/fail"

        guard let url = URL(string: urlString) else {
            completion(.unknown)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8

        session.dataTask(with: request) { [weak self] _, response, error in
            guard let self else {
                completion(.unknown)
                return
            }
            if let mapped = self.mapError(error: error, response: response) {
                completion(mapped)
                return
            }
            completion(.unknown)
        }.resume()
    }

    func mapError(error: Error?, response: URLResponse?) -> NetworkServiceError? {
        if let urlError = error as? URLError {
            if urlError.code == .notConnectedToInternet {
                return .noInternet
            }
            return .unknown
        }

        if let http = response as? HTTPURLResponse {
            if (400...499).contains(http.statusCode) {
                return .forbidden
            }
            if !(200...299).contains(http.statusCode) {
                return .server
            }
        }

        return nil
    }

    func parseSymbol(_ symbol: String) -> (base: String, quote: String)? {
        let suffixes = ["FDUSD", "USDT", "USDC", "BUSD", "BTC", "ETH", "EUR", "RUB", "TRY", "USD"]
        for suffix in suffixes {
            guard symbol.hasSuffix(suffix) else { continue }
            let baseRaw = String(symbol.dropLast(suffix.count))
            guard baseRaw.count >= 2 else { continue }
            let base = normalizeCode(baseRaw)
            let quote = normalizeCode(suffix)
            return (base: base, quote: quote)
        }
        return nil
    }

    func normalizeCode(_ code: String) -> String {
        let stable = ["USDT", "USDC", "BUSD", "FDUSD"]
        if stable.contains(code) {
            return "USD"
        }
        return code
    }

    private func makeAssets(from pairs: [MarketPair]) -> [PairAsset] {
        let allCodes = Set(pairs.flatMap { [$0.base, $0.quote] })
        return allCodes
            .map { code in
                PairAsset(code: code, category: category(for: code))
            }
            .sorted { $0.code < $1.code }
    }

    func category(for code: String) -> PairAssetCategory {
        let fiat: Set<String> = [
            "USD", "EUR", "RUB", "TRY", "GBP", "JPY", "CNY", "CHF",
            "CAD", "AUD", "NZD", "SGD", "HKD", "KZT"
        ]
        return fiat.contains(code) ? .fiat : .crypto
    }

    private func resolveRate(from sourceCode: String, to targetCode: String, pairs: [MarketPair]) -> Double? {
        let source = normalizeCode(sourceCode)
        let target = normalizeCode(targetCode)

        if let direct = directRate(from: source, to: target, pairs: pairs) {
            return direct
        }

        guard source != target else { return 1 }
        guard let sourceToUSD = directRate(from: source, to: "USD", pairs: pairs) else { return nil }
        guard let usdToTarget = directRate(from: "USD", to: target, pairs: pairs) else { return nil }
        return sourceToUSD * usdToTarget
    }

    private func directRate(from sourceCode: String, to targetCode: String, pairs: [MarketPair]) -> Double? {
        if let pair = pairs.first(where: { $0.base == sourceCode && $0.quote == targetCode }) {
            return pair.price
        }
        if let reversed = pairs.first(where: { $0.base == targetCode && $0.quote == sourceCode }), reversed.price > 0 {
            return 1 / reversed.price
        }
        return nil
    }

    func makeOffers(marketRate: Double) -> [P2POffer] {
        let names = [
            "AlexTrader", "CryptoJet", "FastSwap", "BlueExchange",
            "MoonDesk", "NovaPoint", "RubleHub", "CoinBridge", "BitFactory", "TradeFlow"
        ]

        let offers = names.map { name -> P2POffer in
            let discountPercent = Double.random(in: 0.003...0.04)
            let rate = marketRate * (1 - discountPercent)
            let reserve = Double.random(in: 500...20_000)
            return P2POffer(id: UUID(), sellerName: name, rate: rate, reserve: reserve)
        }

        return offers.sorted { $0.rate > $1.rate }
    }
}
