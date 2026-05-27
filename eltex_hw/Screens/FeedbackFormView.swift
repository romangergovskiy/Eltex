import SwiftUI

struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authorName = ""
    @State private var messageText = ""
    @State private var isAgreementAccepted = false
    @State private var isAgreementPresented = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                TextField("Имя автора", text: $authorName)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Текст обращения")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $messageText)
                        .frame(minHeight: 140, maxHeight: 180)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                }

                HStack(alignment: .top, spacing: 10) {
                    Button(action: {
                        isAgreementAccepted.toggle()
                    }) {
                        Image(systemName: isAgreementAccepted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundColor(isAgreementAccepted ? .blue : .secondary)
                    }

                    HStack(spacing: 0) {
                        Text("Я согласен на ")
                            .foregroundColor(.primary)
                        Button("обработку данных") {
                            isAgreementPresented = true
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.subheadline)

                    Spacer(minLength: 0)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Отправить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isAgreementAccepted ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isAgreementAccepted)

                Spacer()
            }
            .padding(16)

            if isAgreementPresented {
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
                        isAgreementPresented = false
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
        .navigationTitle("Обратная связь")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var agreementText: String {
        """
        Настоящим вы подтверждаете, что предоставленные вами данные могут быть использованы для обработки обращения, связи с вами и улучшения качества сервиса.

        Персональные данные не передаются третьим лицам без законных оснований. Доступ к данным имеют только сотрудники, которым это необходимо для выполнения рабочих задач.

        Вы можете отозвать согласие в любой момент, направив соответствующий запрос через форму обратной связи.

        Срок хранения данных определяется целями обработки и требованиями законодательства.
        """
    }
}
