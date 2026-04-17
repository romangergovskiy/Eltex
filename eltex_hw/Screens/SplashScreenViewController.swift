import UIKit

final class SplashScreenViewController: UIViewController {

    // MARK: - Properties

    var onFinish: (() -> Void)?

    private let logoImageView = UIImageView(image: UIImage(named: "logo"))
    private var didStartAnimation = false
    private var didFinishSplash = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSplashFlowIfNeeded()
    }
}

private extension SplashScreenViewController {

    // MARK: - Setup

    func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.356234),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 76.0 / 70.0)
        ])
    }

    // MARK: - Flow

    func startSplashFlowIfNeeded() {
        guard !didStartAnimation else { return }
        didStartAnimation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startLoadingAnimation()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.finishSplash()
        }
    }

    func startLoadingAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.1
        rotation.repeatCount = .infinity
        logoImageView.layer.add(rotation, forKey: "rotation")

        UIView.animate(
            withDuration: 0.75,
            delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut, .allowUserInteraction]
        ) {
            self.logoImageView.alpha = 0.5
        }
    }

    func finishSplash() {
        guard !didFinishSplash else { return }
        didFinishSplash = true

        logoImageView.layer.removeAnimation(forKey: "rotation")
        logoImageView.layer.removeAllAnimations()
        logoImageView.alpha = 1
        onFinish?()
    }
}
