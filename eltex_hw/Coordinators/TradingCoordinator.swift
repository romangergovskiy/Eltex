import UIKit
import SwiftUI

protocol TradingBotRouting: AnyObject {
    func showCompactPairSelector(
        delegate: CurrencyPairsViewControllerDelegate,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset
    )
    func showFullPairSelector(
        delegate: CurrencyPairsViewControllerDelegate,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: CurrencyPairsViewController.SelectionSide
    )
    func showCharts()
    func showWallet()
    func showHeatmap()
}

final class TradingCoordinator: Coordinator, TradingBotRouting {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    private let wallet: Wallet
    private let viewModel: TradingBotViewModel

    init(navigationController: UINavigationController, wallet: Wallet) {
        self.navigationController = navigationController
        self.wallet = wallet
        self.viewModel = TradingBotViewModel(wallet: wallet)
    }

    func start() {
        let controller = ViewController(viewModel: viewModel)
        controller.coordinator = self
        controller.title = "Торговля"
        navigationController.setViewControllers([controller], animated: false)
    }

    func showCompactPairSelector(
        delegate: CurrencyPairsViewControllerDelegate,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset
    ) {
        let compactSelector = CurrencyPairsViewController(
            mode: .compact,
            allAssets: allAssets,
            firstAsset: firstAsset,
            secondAsset: secondAsset,
            selectedSide: .first
        )
        compactSelector.delegate = delegate
        let presentedNavigation = UINavigationController(rootViewController: compactSelector)
        presentedNavigation.modalPresentationStyle = .pageSheet
        if let sheet = presentedNavigation.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        navigationController.topViewController?.present(presentedNavigation, animated: true)
    }

    func showFullPairSelector(
        delegate: CurrencyPairsViewControllerDelegate,
        allAssets: [PairAsset],
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: CurrencyPairsViewController.SelectionSide
    ) {
        let fullSelector = CurrencyPairsViewController(
            mode: .full,
            allAssets: allAssets,
            firstAsset: firstAsset,
            secondAsset: secondAsset,
            selectedSide: selectedSide,
            startsWithFavoritesOnly: true
        )
        fullSelector.navigationItem.largeTitleDisplayMode = .never
        fullSelector.delegate = delegate
        navigationController.pushViewController(fullSelector, animated: true)
    }

    func showCharts() {
        let chartsViewController = ChartsViewController()
        chartsViewController.title = "График"
        chartsViewController.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(chartsViewController, animated: true)
    }

    func showWallet() {
        let walletController = WalletViewController(wallet: wallet)
        let navController = UINavigationController(rootViewController: walletController)
        navController.modalPresentationStyle = .pageSheet
        navigationController.topViewController?.present(navController, animated: true)
    }

    func showHeatmap() {
        let heatmapController = UIHostingController(rootView: HeatmapView())
        heatmapController.title = "Heatmap"
        heatmapController.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(heatmapController, animated: true)
    }
}
