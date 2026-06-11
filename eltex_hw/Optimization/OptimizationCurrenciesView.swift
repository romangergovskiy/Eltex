import SwiftUI
import UIKit
import Combine

// MARK: - Palette

private enum OptimizationPalette {
    static let screen = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let card = Color(red: 0.13, green: 0.18, blue: 0.29)
    static let border = Color.white.opacity(0.09)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
}

// MARK: - Model

struct OptimizationCurrencyPair: Identifiable {
    let id: UUID
    let name: String
    var value: Double
    var previousValue: Double
    var history: [Double]
    var isRisky: Bool
    var priceText: String

    var isGrowing: Bool {
        value >= previousValue
    }

    var changePercent: Double {
        guard previousValue != 0 else { return 0 }
        return (value - previousValue) / previousValue * 100
    }
}

// MARK: - Store

@MainActor
final class OptimizationCurrencyPairsStore: ObservableObject {
    static let pairsCount = 500
    private static let maxHistoryCount = 240
    private static let latestPairsCount = 12

    @Published private(set) var pairs: [OptimizationCurrencyPair] = []
    @Published private(set) var lastUpdatedPairs: [OptimizationCurrencyPair] = []
    @Published private(set) var updateCycle = 0

    private var timer: Timer?

    init() {
        pairs = Self.makePairs()
        lastUpdatedPairs = Array(pairs.prefix(Self.latestPairsCount))
        startUpdating()
    }

    deinit {
        timer?.invalidate()
    }

    private func startUpdating() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 2,
            repeats: true
        ) { [weak self] _ in
            self?.updateRandomPairs()
        }
    }

    private func updateRandomPairs() {
        guard !pairs.isEmpty else { return }

        var updatedPairs = pairs
        let updateCount = Int.random(in: 8...35)
        var indexes = Set<Int>()

        while indexes.count < updateCount {
            indexes.insert(Int.random(in: updatedPairs.indices))
        }

        for index in indexes {
            updatedPairs[index].previousValue = updatedPairs[index].value
            updatedPairs[index].value = max(
                0.0001,
                updatedPairs[index].value * Double.random(in: 0.985...1.015)
            )

            updatedPairs[index].history.append(updatedPairs[index].value)
            if updatedPairs[index].history.count > Self.maxHistoryCount {
                let overflow = updatedPairs[index].history.count - Self.maxHistoryCount
                updatedPairs[index].history.removeFirst(overflow)
            }

            updatedPairs[index].isRisky = Self.isRisky(history: updatedPairs[index].history)
            updatedPairs[index].priceText = Self.priceFormatter.string(
                from: NSNumber(value: updatedPairs[index].value)
            ) ?? "\(updatedPairs[index].value)"
        }

        pairs = updatedPairs

        let sortedIndexes = indexes.sorted { left, right in
            updatedPairs[left].name < updatedPairs[right].name
        }
        lastUpdatedPairs = sortedIndexes
            .prefix(Self.latestPairsCount)
            .map { updatedPairs[$0] }

        updateCycle += 1
    }

    private static func makePairs() -> [OptimizationCurrencyPair] {
        (0..<pairsCount).map { _ in
            var value = Double.random(in: 0.5...180)
            var history: [Double] = []

            for _ in 0..<120 {
                value = max(0.0001, value * Double.random(in: 0.995...1.005))
                history.append(value)
            }

            let priceText = priceFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
            return OptimizationCurrencyPair(
                id: UUID(),
                name: "\(randomCode())/\(randomCode())",
                value: value,
                previousValue: history.dropLast().last ?? value,
                history: history,
                isRisky: isRisky(history: history),
                priceText: priceText
            )
        }
        .sorted { $0.name < $1.name }
    }

    private static func randomCode() -> String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String((0..<3).compactMap { _ in letters.randomElement() })
    }

    private static func isRisky(history: [Double]) -> Bool {
        guard history.count > 1 else { return false }

        var returns: [Double] = []
        returns.reserveCapacity(history.count - 1)

        for index in 1..<history.count {
            let previous = max(history[index - 1], 0.0001)
            returns.append(log(history[index] / previous))
        }

        let average = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { partialResult, value in
            partialResult + pow(value - average, 2)
        } / Double(returns.count)
        let volatility = sqrt(variance) * sqrt(252)

        let recent = history.suffix(14)
        let maxPrice = recent.max() ?? 0
        let minPrice = recent.min() ?? 0
        let averagePrice = recent.reduce(0, +) / Double(max(recent.count, 1))
        let rangePercent = averagePrice > 0 ? ((maxPrice - minPrice) / averagePrice) * 100 : 0

        return volatility > 0.06 || rangePercent > 2.2
    }

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        return formatter
    }()
}

// MARK: - Screen

struct OptimizationCurrenciesView: View {
    @StateObject private var store = OptimizationCurrencyPairsStore()
    @State private var highlightRisk = false

    var body: some View {
        VStack(spacing: 0) {
            headerBlock
            pairsList
        }
        .background(OptimizationPalette.screen.ignoresSafeArea())
    }

    private var headerBlock: some View {
        VStack(spacing: 0) {
            Toggle("Подсвечивать рискованные пары", isOn: $highlightRisk)
                .tint(.teal)
                .foregroundColor(OptimizationPalette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(OptimizationPalette.card)

            VStack(alignment: .leading, spacing: 8) {
                Text("Последние обновления")
                    .font(.headline)
                    .foregroundColor(OptimizationPalette.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.lastUpdatedPairs) { pair in
                            OptimizationRecentPairCard(pair: pair, updateCycle: store.updateCycle)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .background(OptimizationPalette.card)
        }
    }

    private var pairsList: some View {
        List {
            ForEach(store.pairs) { pair in
                OptimizationPairRow(pair: pair, highlightRisk: highlightRisk)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
        HStack(spacing: 12) {
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(rowBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(OptimizationPalette.border, lineWidth: 1)
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
        .frame(width: 150, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(OptimizationPalette.screen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(OptimizationPalette.border, lineWidth: 1)
        )
    }
}
