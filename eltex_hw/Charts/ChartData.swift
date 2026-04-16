import UIKit

struct CandleData {
    let open: Double
    let close: Double
    let high: Double
    let low: Double
    let timeTitle: String

    let bodyHeight: CGFloat
    let bodyTop: CGFloat
    let topTailExtra: CGFloat
    let bottomTailExtra: CGFloat

    var isGrowing: Bool {
        close >= open
    }
}

struct LinePointData {
    let price: Double
    let title: String
}
