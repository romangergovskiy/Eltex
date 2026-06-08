import Foundation

struct P2PExchangeViewState {
    let pairText: String
    let balancesText: String
    let offers: [P2POffer]
    let isLoading: Bool
}

final class P2PExchangeViewModel {
    var onStateChange: ((P2PExchangeViewState) -> Void)?
    var onError: ((NetworkServiceError) -> Void)?
    var onTradeSuccess: ((WalletExchangeResult) -> Void)?

    private let wallet: Wallet
    private let networkService: NetworkService
    private let allAssets = PairAssetFactory.makeList(minCount: 140)

    private var apiAssets: [PairAsset] = []
    private var offers: [P2POffer] = []
    private var firstAsset = PairAsset(code: "USD", category: .fiat)
    private var secondAsset = PairAsset(code: "BTC", category: .crypto)
    private var isLoading = false

    init(wallet: Wallet, networkService: NetworkService = NetworkService()) {
        self.wallet = wallet
        self.networkService = networkService
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

    func offer(at index: Int) -> P2POffer? {
        guard offers.indices.contains(index) else { return nil }
        return offers[index]
    }

    func pairSelectionInput() -> (allAssets: [PairAsset], first: PairAsset, second: PairAsset, apiAssets: [PairAsset]) {
        (allAssets, firstAsset, secondAsset, apiAssets)
    }

    func applyPair(first: PairAsset, second: PairAsset) {
        firstAsset = first
        secondAsset = second
        emitState()
        reloadOffers()
    }

    func executeTrade(amount: Double, offer: P2POffer) {
        setLoading(true)
        networkService.executeExchange(
            wallet: wallet,
            from: firstAsset.code,
            to: secondAsset.code,
            amount: amount,
            rate: offer.rate
        ) { [weak self] result in
            guard let self else { return }
            self.setLoading(false)
            switch result {
            case let .success(exchangeResult):
                self.emitState()
                self.onTradeSuccess?(exchangeResult)
            case let .failure(error):
                self.onError?(error)
            }
        }
    }

    func pairCodes() -> (source: String, target: String) {
        (firstAsset.code, secondAsset.code)
    }

    private func loadAssetsAndOffers() {
        setLoading(true)
        networkService.loadAvailableAssets { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(assets):
                self.apiAssets = assets
                self.alignPairWithAvailableAssets()
                self.reloadOffers()
            case let .failure(error):
                self.setLoading(false)
                self.onError?(error)
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
        setLoading(true)
        networkService.loadOffers(from: firstAsset.code, to: secondAsset.code) { [weak self] result in
            guard let self else { return }
            self.setLoading(false)
            switch result {
            case let .success(offers):
                self.offers = offers
                self.emitState()
            case let .failure(error):
                self.offers = []
                self.emitState()
                self.onError?(error)
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
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
        onStateChange?(
            P2PExchangeViewState(
                pairText: "\(firstAsset.code)-\(secondAsset.code)",
                balancesText: balances,
                offers: offers,
                isLoading: isLoading
            )
        )
    }
}
