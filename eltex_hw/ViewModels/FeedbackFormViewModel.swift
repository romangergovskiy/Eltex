import Combine
import CoreGraphics
import Foundation

enum FeedbackField: Hashable {
    case authorName
    case message
}

enum BotSwipeDirection: String, CaseIterable, Hashable {
    case topToBottom
    case bottomToTop
    case leftToRight
    case rightToLeft

    var title: String {
        switch self {
        case .topToBottom:
            return "сверху-вниз"
        case .bottomToTop:
            return "снизу-вверх"
        case .leftToRight:
            return "слева-направо"
        case .rightToLeft:
            return "справа-налево"
        }
    }
}

enum FeedbackSubmitAlert: Identifiable {
    case success
    case failure

    var id: String {
        switch self {
        case .success:
            return "success"
        case .failure:
            return "failure"
        }
    }

    var title: String {
        switch self {
        case .success:
            return "Готово"
        case .failure:
            return "Ошибка"
        }
    }

    var message: String {
        switch self {
        case .success:
            return "Сообщение отправлено"
        case .failure:
            return "Проверка не пройдена, попробуйте еще раз"
        }
    }
}

final class FeedbackFormViewModel: ObservableObject {
    @Published var authorName = ""
    @Published var messageText = ""
    @Published var isAgreementAccepted = false
    @Published var isAgreementPresented = false
    @Published var selectedFeedbackDirections = Set<FeedbackDirection>()
    @Published var isBotCheckPresented = false
    @Published var submitAlert: FeedbackSubmitAlert?
    @Published private(set) var authorNameError: String?
    @Published private(set) var messageTextError: String?
    @Published private(set) var botCheckCommands: [BotSwipeDirection] = []
    @Published private(set) var currentBotCheckIndex = 0

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
        guard canSubmit else { return false }
        startBotCheck()
        return true
    }

    func currentBotCheckDirectionTitle() -> String {
        guard currentBotCheckIndex < botCheckCommands.count else { return "" }
        return botCheckCommands[currentBotCheckIndex].title
    }

    func handleBotSwipe(translationWidth: CGFloat, translationHeight: CGFloat) {
        guard isBotCheckPresented else { return }
        guard let actualDirection = botSwipeDirection(
            translationWidth: translationWidth,
            translationHeight: translationHeight
        ) else {
            return
        }
        guard currentBotCheckIndex < botCheckCommands.count else { return }

        let expectedDirection = botCheckCommands[currentBotCheckIndex]
        guard actualDirection == expectedDirection else {
            finishBotCheck(success: false)
            return
        }

        currentBotCheckIndex += 1
        if currentBotCheckIndex >= botCheckCommands.count {
            finishBotCheck(success: true)
        }
    }
}

// MARK: - Validation

private extension FeedbackFormViewModel {
    enum Limits {
        static let minLength = 3
        static let maxNameLength = 30
        static let maxMessageLength = 150
        static let botCheckCommandsCount = 3
        static let minSwipeDistance: CGFloat = 40
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

    func startBotCheck() {
        botCheckCommands = Array(BotSwipeDirection.allCases.shuffled().prefix(Limits.botCheckCommandsCount))
        currentBotCheckIndex = 0
        isBotCheckPresented = true
    }

    func finishBotCheck(success: Bool) {
        isBotCheckPresented = false
        if success {
            resetForm()
            submitAlert = .success
        } else {
            submitAlert = .failure
        }
        botCheckCommands = []
        currentBotCheckIndex = 0
    }

    func resetForm() {
        authorName = ""
        messageText = ""
        selectedFeedbackDirections = []
        isAgreementAccepted = false
        authorNameError = nil
        messageTextError = nil
    }

    func botSwipeDirection(translationWidth: CGFloat, translationHeight: CGFloat) -> BotSwipeDirection? {
        if abs(translationWidth) > abs(translationHeight) {
            guard abs(translationWidth) >= Limits.minSwipeDistance else { return nil }
            return translationWidth > 0 ? .leftToRight : .rightToLeft
        } else {
            guard abs(translationHeight) >= Limits.minSwipeDistance else { return nil }
            return translationHeight > 0 ? .topToBottom : .bottomToTop
        }
    }
}
