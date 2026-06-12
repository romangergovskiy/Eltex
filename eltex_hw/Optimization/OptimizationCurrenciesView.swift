import SwiftUI

// MARK: - Palette

private enum OptimizationPalette {
    static let screen = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let card = Color(red: 0.13, green: 0.18, blue: 0.29)
    static let border = Color.white.opacity(0.09)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
}

// MARK: - Layout

private enum OptimizationLayout {
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    static let cardSpacing: CGFloat = 10
    static let rowInnerSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14
    static let borderWidth: CGFloat = 1
    static let recentCardWidth: CGFloat = 150
    static let rowVerticalInset: CGFloat = 8
}

// MARK: - Screen

struct OptimizationCurrenciesView: View {
    @StateObject private var viewModel: OptimizationCurrenciesViewModel

    init(viewModel: OptimizationCurrenciesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .background(OptimizationPalette.screen.ignoresSafeArea())
            .onAppear {
                viewModel.dispatch(.onAppear)
            }
            .onDisappear {
                viewModel.dispatch(.onDisappear)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            loadingContent
        case .error(let message):
            errorContent(message)
        case .content(let state):
            screenContent(state)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(.white)
            Text("Загрузка валют")
                .font(.subheadline)
                .foregroundColor(OptimizationPalette.textSecondary)
            Spacer()
        }
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Ошибка")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(OptimizationPalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private extension OptimizationCurrenciesView {
    func screenContent(_ state: OptimizationCurrenciesContentState) -> some View {
        VStack(spacing: 0) {
            headerBlock(state)
            pairsList(state)
        }
    }

    func headerBlock(_ state: OptimizationCurrenciesContentState) -> some View {
        VStack(spacing: 0) {
            Toggle(
                "Подсвечивать рискованные пары",
                isOn: Binding(
                    get: { state.highlightRisk },
                    set: { newValue in
                        viewModel.dispatch(.highlightRiskChanged(newValue))
                    }
                )
            )
            .tint(.teal)
            .foregroundColor(OptimizationPalette.textPrimary)
            .padding(.horizontal, OptimizationLayout.horizontalPadding)
            .padding(.vertical, OptimizationLayout.verticalPadding)
            .background(OptimizationPalette.card)

            VStack(alignment: .leading, spacing: 8) {
                Text("Последние обновления")
                    .font(.headline)
                    .foregroundColor(OptimizationPalette.textPrimary)
                    .padding(.horizontal, OptimizationLayout.horizontalPadding)
                    .padding(.top, OptimizationLayout.verticalPadding)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: OptimizationLayout.cardSpacing) {
                        ForEach(state.lastUpdatedPairs) { pair in
                            OptimizationRecentPairCard(
                                pair: pair,
                                updateCycle: state.updateCycle
                            )
                        }
                    }
                    .padding(.horizontal, OptimizationLayout.horizontalPadding)
                    .padding(.bottom, OptimizationLayout.verticalPadding)
                }
            }
            .background(OptimizationPalette.card)
        }
    }

    func pairsList(_ state: OptimizationCurrenciesContentState) -> some View {
        List {
            ForEach(state.pairs) { pair in
                OptimizationPairRow(pair: pair, highlightRisk: state.highlightRisk)
                    .listRowInsets(
                        EdgeInsets(
                            top: OptimizationLayout.rowVerticalInset,
                            leading: OptimizationLayout.horizontalPadding,
                            bottom: OptimizationLayout.rowVerticalInset,
                            trailing: OptimizationLayout.horizontalPadding
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(OptimizationPalette.screen)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(OptimizationPalette.screen)
    }
}

// MARK: - Pair Row

private struct OptimizationPairRow: View, Equatable {
    let pair: OptimizationCurrencyPair
    let highlightRisk: Bool

    static func == (lhs: OptimizationPairRow, rhs: OptimizationPairRow) -> Bool {
        lhs.pair.id == rhs.pair.id
        && lhs.pair.value == rhs.pair.value
        && lhs.pair.previousValue == rhs.pair.previousValue
        && lhs.pair.isRisky == rhs.pair.isRisky
        && lhs.highlightRisk == rhs.highlightRisk
    }

    var body: some View {
        HStack(spacing: OptimizationLayout.rowInnerSpacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(pair.name)
                    .font(.headline)
                    .foregroundColor(OptimizationPalette.textPrimary)

                Text(pair.priceText)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(pair.isGrowing ? .green : .red)
            }

            Spacer()

            Text("\(pair.changePercent, specifier: "%.2f")%")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(pair.isGrowing ? .green : .red)
        }
        .padding(OptimizationLayout.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: OptimizationLayout.cardCornerRadius)
                .fill(rowBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OptimizationLayout.cardCornerRadius)
                .stroke(OptimizationPalette.border, lineWidth: OptimizationLayout.borderWidth)
        )
    }

    private var rowBackgroundColor: Color {
        if highlightRisk && pair.isRisky {
            return Color.orange.opacity(0.35)
        }
        return OptimizationPalette.card
    }
}

// MARK: - Recent Card

private struct OptimizationRecentPairCard: View, Equatable {
    let pair: OptimizationCurrencyPair
    let updateCycle: Int

    static func == (lhs: OptimizationRecentPairCard, rhs: OptimizationRecentPairCard) -> Bool {
        lhs.pair.id == rhs.pair.id
        && lhs.pair.value == rhs.pair.value
        && lhs.pair.previousValue == rhs.pair.previousValue
        && lhs.updateCycle == rhs.updateCycle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pair.name)
                    .font(.caption.bold())
                    .foregroundColor(OptimizationPalette.textPrimary)
                Spacer()
                Circle()
                    .fill(pair.isGrowing ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            Text(pair.priceText)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundColor(OptimizationPalette.textPrimary)

            Text("\(pair.changePercent, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(pair.isGrowing ? .green : .red)

            Text("Цикл \(updateCycle)")
                .font(.caption2)
                .foregroundColor(OptimizationPalette.textSecondary.opacity(0.9))
        }
        .frame(width: OptimizationLayout.recentCardWidth, alignment: .leading)
        .padding(OptimizationLayout.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: OptimizationLayout.cardCornerRadius)
                .fill(OptimizationPalette.screen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OptimizationLayout.cardCornerRadius)
                .stroke(OptimizationPalette.border, lineWidth: OptimizationLayout.borderWidth)
        )
    }
}
