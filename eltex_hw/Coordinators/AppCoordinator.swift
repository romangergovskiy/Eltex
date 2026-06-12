import UIKit
import SwiftUI

final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let authManager: AuthSessionManager
    private let sharedWallet: Wallet

    init(window: UIWindow, authManager: AuthSessionManager, wallet: Wallet) {
        self.window = window
        self.authManager = authManager
        self.sharedWallet = wallet
    }

    func start() {
        let splashViewController = SplashScreenViewController()
        splashViewController.onFinish = { [weak self] in
            self?.showInitialScreenAfterSplash()
        }
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
    }

    private func showInitialScreenAfterSplash() {
        if authManager.canAutoLogin() {
            showMainApplication()
            return
        }
        showAuthScreen()
    }

    private func showMainApplication() {
        let tabBarController = UITabBarController()

        let chartsViewController = ChartsViewController()
        chartsViewController.title = "График"
        let chartsNavigationController = UINavigationController(rootViewController: chartsViewController)
        chartsNavigationController.tabBarItem = UITabBarItem(
            title: "График",
            image: UIImage(systemName: "chart.bar.xaxis"),
            tag: 0
        )

        let tradeNavigationController = UINavigationController()
        tradeNavigationController.tabBarItem = UITabBarItem(
            title: "Торговля",
            image: UIImage(systemName: "arrow.left.arrow.right"),
            tag: 1
        )
        let tradeCoordinator = TradingCoordinator(navigationController: tradeNavigationController, wallet: sharedWallet)
        tradeCoordinator.start()

        let p2pNavigationController = UINavigationController()
        p2pNavigationController.tabBarItem = UITabBarItem(
            title: "P2P",
            image: UIImage(systemName: "person.3.sequence"),
            tag: 2
        )
        let p2pCoordinator = P2PCoordinator(navigationController: p2pNavigationController, wallet: sharedWallet)
        p2pCoordinator.start()

        let settingsViewController = SettingsViewController(authManager: authManager)
        settingsViewController.title = "Настройки"
        settingsViewController.onSignOutConfirmed = { [weak self] in
            self?.showAuthScreen()
        }
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        settingsNavigationController.tabBarItem = UITabBarItem(
            title: "Настройки",
            image: UIImage(systemName: "gearshape"),
            tag: 3
        )

        tabBarController.viewControllers = [
            chartsNavigationController,
            tradeNavigationController,
            p2pNavigationController,
            settingsNavigationController
        ]

        childCoordinators = [tradeCoordinator, p2pCoordinator]
        transition(to: tabBarController)
    }

    private func showAuthScreen() {
        let authViewController = AuthViewController(authManager: authManager)
        let authNavigationController = UINavigationController(rootViewController: authViewController)
        authViewController.onAuthorized = { [weak self] in
            self?.showMainApplication()
        }
        authViewController.onHelpRequested = { [weak authNavigationController] in
            let feedbackController = UIHostingController(rootView: FeedbackFormView())
            feedbackController.navigationItem.largeTitleDisplayMode = .never
            authNavigationController?.pushViewController(feedbackController, animated: true)
        }
        transition(to: authNavigationController)
    }

    private func transition(to controller: UIViewController) {
        UIView.animate(withDuration: 0.2, animations: {
            self.window.alpha = 0.0
        }) { _ in
            self.window.rootViewController = controller
            UIView.animate(withDuration: 0.2) {
                self.window.alpha = 1.0
            }
        }
    }
}
