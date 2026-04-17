import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var mainController: UIViewController?

    // MARK: - UIWindowSceneDelegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let splashViewController = SplashScreenViewController()
        splashViewController.onFinish = { [weak self] in
            self?.showMainApplication()
        }

        let chartsViewController = ChartsViewController()
        chartsViewController.title = "График"
        let chartsNavigationController = UINavigationController(rootViewController: chartsViewController)
        chartsNavigationController.tabBarItem = UITabBarItem(
            title: "График",
            image: UIImage(systemName: "chart.bar.xaxis"),
            tag: 0
        )

        let tradeViewController = ViewController()
        tradeViewController.title = "Торговля"

        let tradeNavigationController = UINavigationController(rootViewController: tradeViewController)
        tradeNavigationController.tabBarItem = UITabBarItem(
            title: "Торговля",
            image: UIImage(systemName: "arrow.left.arrow.right"),
            tag: 1
        )

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [chartsNavigationController, tradeNavigationController]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
        self.window = window
        self.mainController = tabBarController
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}

private extension SceneDelegate {
    // MARK: - Flow

    func showMainApplication() {
        guard let window else { return }
        guard let mainController else { return }

        UIView.animate(withDuration: 0.2, animations: {
            window.alpha = 0.0
        }) { _ in
            window.rootViewController = mainController
            UIView.animate(withDuration: 0.2) {
                window.alpha = 1.0
            }
        }
    }
}

