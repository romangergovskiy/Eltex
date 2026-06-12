import UIKit
import SwiftUI

// MARK: - Assembly

@MainActor
final class OptimizationCurrenciesAssembly {
    func makeViewController() -> UIViewController {
        let useCase = OptimizationCurrenciesUseCase()
        let viewModel = OptimizationCurrenciesViewModel(useCase: useCase)
        let view = OptimizationCurrenciesView(viewModel: viewModel)
        return UIHostingController(rootView: view)
    }
}
