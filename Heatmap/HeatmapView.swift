import SwiftUI

struct HeatmapView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Heatmap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "BTC", change: "+2.4%", color: .green, width: 190, height: 150)

                        VStack(spacing: 8) {
                            CurrencyTileView(symbol: "ETH", change: "+1.1%", color: .green.opacity(0.75), width: 150, height: 71)
                            CurrencyTileView(symbol: "SOL", change: "-0.6%", color: .red.opacity(0.75), width: 150, height: 71)
                        }
                    }

                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "XRP", change: "-1.3%", color: .red, width: 112, height: 100)
                        CurrencyTileView(symbol: "DOGE", change: "+0.8%", color: .green.opacity(0.85), width: 112, height: 100)
                        CurrencyTileView(symbol: "ADA", change: "+1.7%", color: .green.opacity(0.65), width: 112, height: 100)
                    }

                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "DOT", change: "-0.4%", color: .red.opacity(0.65), width: 170, height: 94)
                        CurrencyTileView(symbol: "LTC", change: "+0.3%", color: .green.opacity(0.5), width: 170, height: 94)
                    }

                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "LINK", change: "+0.9%", color: .green.opacity(0.6), width: 112, height: 86)
                        CurrencyTileView(symbol: "BNB", change: "-0.2%", color: .red.opacity(0.55), width: 112, height: 86)
                        CurrencyTileView(symbol: "AVAX", change: "+1.5%", color: .green.opacity(0.9), width: 112, height: 86)
                    }

                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "TON", change: "+2.0%", color: .green.opacity(0.92), width: 112, height: 78)
                        CurrencyTileView(symbol: "TRX", change: "-0.8%", color: .red.opacity(0.7), width: 112, height: 78)
                        CurrencyTileView(symbol: "MATIC", change: "+0.6%", color: .green.opacity(0.72), width: 112, height: 78)
                    }

                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "XLM", change: "-0.3%", color: .red.opacity(0.62), width: 170, height: 78)
                        CurrencyTileView(symbol: "ATOM", change: "+1.2%", color: .green.opacity(0.84), width: 170, height: 78)
                    }

                    HStack(spacing: 8) {
                        CurrencyTileView(symbol: "NEAR", change: "+0.4%", color: .green.opacity(0.56), width: 112, height: 74)
                        CurrencyTileView(symbol: "ETC", change: "-1.1%", color: .red.opacity(0.86), width: 112, height: 74)
                        CurrencyTileView(symbol: "UNI", change: "+0.7%", color: .green.opacity(0.68), width: 112, height: 74)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }
}

// MARK: - Currency Tile

private struct CurrencyTileView: View {
    let symbol: String
    let change: String
    let color: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(color)

            VStack(spacing: 6) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(change)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.95))
            }
            .padding(8)
        }
        .frame(width: width, height: height)
    }
}
