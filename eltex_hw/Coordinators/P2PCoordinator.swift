import UIKit

protocol P2PExchangeRouting: AnyObject {
    func showP2PPairSelector(
        delegate: CurrencyPairsViewControllerDelegate,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        apiAssets: [PairAsset]
    )
    func showP2PWallet()
    func showSellerInfo(offer: P2POffer, sourceCode: String, targetCode: String)
}

final class P2PCoordinator: Coordinator, P2PExchangeRouting {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    private let wallet: Wallet
    private let viewModel: P2PExchangeViewModel

    init(navigationController: UINavigationController, wallet: Wallet) {
        self.navigationController = navigationController
        self.wallet = wallet
        self.viewModel = P2PExchangeViewModel(wallet: wallet)
    }

    func start() {
        let controller = P2PExchangeViewController(viewModel: viewModel)
        controller.coordinator = self
        controller.title = "P2P обмен"
        navigationController.setViewControllers([controller], animated: false)
    }

    func showP2PPairSelector(
        delegate: CurrencyPairsViewControllerDelegate,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        apiAssets: [PairAsset]
    ) {
        let controller = CurrencyPairsViewController(
            mode: .full,
            allAssets: allAssets,
            firstAsset: firstAsset,
            secondAsset: secondAsset,
            selectedSide: .first,
            startsWithFavoritesOnly: false,
            apiAssets: apiAssets
        )
        controller.delegate = delegate
        navigationController.pushViewController(controller, animated: true)
    }

    func showP2PWallet() {
        let walletController = WalletViewController(wallet: wallet)
        let navController = UINavigationController(rootViewController: walletController)
        navController.modalPresentationStyle = .pageSheet
        navigationController.topViewController?.present(navController, animated: true)
    }

    func showSellerInfo(offer: P2POffer, sourceCode: String, targetCode: String) {
        let profile = makeProfile(offer: offer, sourceCode: sourceCode, targetCode: targetCode)
        let controller = SellerInfoViewController(profile: profile)
        navigationController.pushViewController(controller, animated: true)
    }

    private func makeProfile(offer: P2POffer, sourceCode: String, targetCode: String) -> SellerProfile {
        let ascii = offer.sellerName.unicodeScalars.map(\.value).reduce(0, +)
        let completion = 92 + Int(ascii % 8)
        let orders = 150 + Int(ascii % 800)
        let releaseMinutes = 4 + Int(ascii % 11)
        let year = 2018 + Int(ascii % 7)
        return SellerProfile(
            name: offer.sellerName,
            completionRate: completion,
            ordersCount: orders,
            averageReleaseMinutes: releaseMinutes,
            verifiedSince: "01.\(String(format: "%02d", (ascii % 12) + 1)).\(year)",
            aboutText: "Пара: \(sourceCode)-\(targetCode)\nТекущий курс: \(String(format: "%.6f", offer.rate))\nРезерв: \(String(format: "%.2f", offer.reserve)) \(targetCode)\nРаботает быстро, подтверждает сделки вручную и онлайн в дневное время."
        )
    }
}
