import Combine
import Foundation

enum FeedbackField: Hashable {
    case authorName
    case message
}

final class FeedbackFormViewModel: ObservableObject {
    @Published var authorName = ""
    @Published var messageText = ""
    @Published var isAgreementAccepted = false
    @Published var isAgreementPresented = false
    @Published var selectedFeedbackDirections = Set<FeedbackDirection>()
    @Published private(set) var authorNameError: String?
    @Published private(set) var messageTextError: String?

    var canSubmit: Bool {
        isAgreementAccepted
            && authorNameValidationError == nil
            && messageTextValidationError == nil
    }

    func focusChanged(from previous: FeedbackField?, to current: FeedbackField?) {
        if let previous {
            showValidationError(for: previous)
        }
        if let current {
            hideValidationError(for: current)
        }
    }

    func keyboardWillHide(for field: FeedbackField) {
        showValidationError(for: field)
    }

    func textDidChange(_ field: FeedbackField) {
        hideValidationError(for: field)
    }

    func fieldDidBecomeActive(_ field: FeedbackField) {
        hideValidationError(for: field)
    }

    @discardableResult
    func submit() -> Bool {
        showValidationError(for: .authorName)
        showValidationError(for: .message)
        return canSubmit
    }
}

// MARK: - Validation

private extension FeedbackFormViewModel {
    enum Limits {
        static let minLength = 3
        static let maxNameLength = 30
        static let maxMessageLength = 150
    }

    var trimmedAuthorName: String {
        authorName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMessageText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var authorNameValidationError: String? {
        if trimmedAuthorName.count < Limits.minLength {
            return "поле имя должно содержать не менее 3-х символов"
        }
        if trimmedAuthorName.count > Limits.maxNameLength {
            return "поле имя не должно содержать более 30 символов"
        }
        return nil
    }

    var messageTextValidationError: String? {
        if trimmedMessageText.isEmpty {
            return "текст обращения не должен быть пустым"
        }
        if trimmedMessageText.count < Limits.minLength {
            return "текст обращения должен содержать не менее 3-х символов"
        }
        if trimmedMessageText.count > Limits.maxMessageLength {
            return "текст обращения не должен содержать более 150 символов"
        }
        return nil
    }

    func showValidationError(for field: FeedbackField) {
        switch field {
        case .authorName:
            authorNameError = authorNameValidationError
        case .message:
            messageTextError = messageTextValidationError
        }
    }

    func hideValidationError(for field: FeedbackField) {
        switch field {
        case .authorName:
            authorNameError = nil
        case .message:
            messageTextError = nil
        }
    }
}
