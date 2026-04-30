import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let authManager = AuthSessionManager.shared
    private let sharedWallet = Wallet(
        initialBalances: AppConfig.initialWalletBalances,
        autoCreditAmount: AppConfig.autoCreditAmount
    )

    // MARK: - UIWindowSceneDelegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let splashViewController = SplashScreenViewController()
        splashViewController.onFinish = { [weak self] in
            self?.showInitialScreenAfterSplash()
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}

private extension SceneDelegate {
    // MARK: - Flow

    func showInitialScreenAfterSplash() {
        if authManager.canAutoLogin() {
            showMainApplication()
            return
        }
        showAuthScreen()
    }

    func showMainApplication() {
        let tabBarController = makeMainTabBarController()
        transition(to: tabBarController)
    }

    func showAuthScreen() {
        let authViewController = AuthViewController(authManager: authManager)
        authViewController.onAuthorized = { [weak self] in
            self?.showMainApplication()
        }
        transition(to: authViewController)
    }

    func transition(to controller: UIViewController) {
        guard let window else { return }

        UIView.animate(withDuration: 0.2, animations: {
            window.alpha = 0.0
        }) { _ in
            window.rootViewController = controller
            UIView.animate(withDuration: 0.2) {
                window.alpha = 1.0
            }
        }
    }

    func makeMainTabBarController() -> UITabBarController {
        let chartsViewController = ChartsViewController()
        chartsViewController.title = "График"
        let chartsNavigationController = UINavigationController(rootViewController: chartsViewController)
        chartsNavigationController.tabBarItem = UITabBarItem(
            title: "График",
            image: UIImage(systemName: "chart.bar.xaxis"),
            tag: 0
        )

        let tradeViewController = ViewController(wallet: sharedWallet)
        tradeViewController.title = "Торговля"
        let tradeNavigationController = UINavigationController(rootViewController: tradeViewController)
        tradeNavigationController.tabBarItem = UITabBarItem(
            title: "Торговля",
            image: UIImage(systemName: "arrow.left.arrow.right"),
            tag: 1
        )

        let p2pViewController = P2PExchangeViewController(wallet: sharedWallet)
        p2pViewController.title = "P2P обмен"
        let p2pNavigationController = UINavigationController(rootViewController: p2pViewController)
        p2pNavigationController.tabBarItem = UITabBarItem(
            title: "P2P",
            image: UIImage(systemName: "person.3.sequence"),
            tag: 2
        )

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

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            chartsNavigationController,
            tradeNavigationController,
            p2pNavigationController,
            settingsNavigationController
        ]
        return tabBarController
    }
}

