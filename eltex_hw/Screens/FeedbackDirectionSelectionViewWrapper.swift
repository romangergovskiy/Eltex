import SwiftUI
import UIKit

struct FeedbackDirectionSelectionViewWrapper: UIViewRepresentable {
    @Binding var selectedDirections: Set<FeedbackDirection>

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedDirections: $selectedDirections)
    }

    func makeUIView(context: Context) -> FeedbackDirectionSelectionView {
        let view = FeedbackDirectionSelectionView()
        view.delegate = context.coordinator
        view.setSelectedDirections(selectedDirections)
        return view
    }

    func updateUIView(_ uiView: FeedbackDirectionSelectionView, context: Context) {
        uiView.setSelectedDirections(selectedDirections)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, FeedbackDirectionSelectionViewDelegate {
        @Binding private var selectedDirections: Set<FeedbackDirection>

        init(selectedDirections: Binding<Set<FeedbackDirection>>) {
            _selectedDirections = selectedDirections
        }

        func feedbackDirectionSelectionView(
            _ view: FeedbackDirectionSelectionView,
            didChangeSelection directions: Set<FeedbackDirection>
        ) {
            selectedDirections = directions
        }
    }
}
