import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let appCoordinatorAuthManager = AuthSessionManager.shared
    private let appCoordinatorWallet = Wallet(
        initialBalances: AppConfig.initialWalletBalances,
        autoCreditAmount: AppConfig.autoCreditAmount
    )
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        let coordinator = AppCoordinator(
            window: window,
            authManager: appCoordinatorAuthManager,
            wallet: appCoordinatorWallet
        )
        appCoordinator = coordinator
        coordinator.start()
    }
}
