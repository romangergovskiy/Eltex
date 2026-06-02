import SwiftUI
import UIKit

struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FeedbackFormViewModel()
    @FocusState private var focusedField: FeedbackField?
    @State private var previousFocusedField: FeedbackField?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    authorNameField
                    messageField
                    directionSelectionField
                    agreementRow
                    submitButton
                }
                .frame(maxWidth: .infinity)
                .padding(16)
            }

            if viewModel.isAgreementPresented {
                agreementOverlay
            }
        }
        .navigationTitle("Обратная связь")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    focusedField = nil
                }
            }
        }
        .onChange(of: focusedField) { newValue in
            viewModel.focusChanged(from: previousFocusedField, to: newValue)
            previousFocusedField = newValue
        }
        .onChange(of: viewModel.authorName) { _ in
            viewModel.textDidChange(.authorName)
        }
        .onChange(of: viewModel.messageText) { _ in
            viewModel.textDidChange(.message)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            guard let focusedField else { return }
            viewModel.keyboardWillHide(for: focusedField)
        }
    }
}

// MARK: - Fields

private extension FeedbackFormView {
    var authorNameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Имя автора", text: $viewModel.authorName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .authorName)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.fieldDidBecomeActive(.authorName)
                })

            if let authorNameError = viewModel.authorNameError {
                Text(authorNameError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    var directionSelectionField: some View {
        FeedbackDirectionSelectionViewWrapper(selectedDirections: $viewModel.selectedFeedbackDirections)
            .frame(height: FeedbackDirectionSelectionView.Layout.totalHeight)
    }

    var messageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Текст обращения")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextEditor(text: $viewModel.messageText)
                .frame(minHeight: 140, maxHeight: 180)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
                .focused($focusedField, equals: .message)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.fieldDidBecomeActive(.message)
                })

            if let messageTextError = viewModel.messageTextError {
                Text(messageTextError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    var agreementRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: {
                viewModel.isAgreementAccepted.toggle()
            }) {
                Image(systemName: viewModel.isAgreementAccepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(viewModel.isAgreementAccepted ? .blue : .secondary)
            }

            HStack(spacing: 0) {
                Text("Я согласен на ")
                    .foregroundColor(.primary)
                Button("обработку данных") {
                    viewModel.isAgreementPresented = true
                }
                .foregroundColor(.blue)
            }
            .font(.subheadline)

            Spacer(minLength: 0)
        }
    }

    var submitButton: some View {
        Button(action: {
            if viewModel.submit() {
                dismiss()
            }
        }) {
            Text("Отправить")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(viewModel.isAgreementAccepted ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!viewModel.isAgreementAccepted)
    }
}

// MARK: - Agreement

private extension FeedbackFormView {
    var agreementOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Соглашение об обработке персональных данных")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                ScrollView {
                    Text(agreementText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                Button("Закрыть") {
                    viewModel.isAgreementPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(16)
            .frame(maxWidth: 360, maxHeight: 480)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    var agreementText: String {
        """
        Настоящим вы подтверждаете, что предоставленные вами данные могут быть использованы для обработки обращения, связи с вами и улучшения качества сервиса.

        Персональные данные не передаются третьим лицам без законных оснований. Доступ к данным имеют только сотрудники, которым это необходимо для выполнения рабочих задач.

        Вы можете отозвать согласие в любой момент, направив соответствующий запрос через форму обратной связи.

        Срок хранения данных определяется целями обработки и требованиями законодательства.
        """
    }
}
