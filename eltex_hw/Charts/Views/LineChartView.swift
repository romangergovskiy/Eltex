import UIKit

final class LineChartView: UIView {

    // MARK: - Properties

    var points: [LinePointData] = [] {
        didSet {
            selectedIndex = nil
            rebuildLabels()
            setNeedsLayout()
        }
    }

    var onPointSelected: ((Int) -> Void)?

    private let lineLayer = CAShapeLayer()
    private let gridLayer = CAShapeLayer()
    private let selectedPointLayer = CAShapeLayer()
    private let selectedGuideLayer = CAShapeLayer()
    private let currentPricePulseView = UIView()
    private let currentPriceIndicatorView = UIView()

    private let selectedValueLabel = UILabel()
    private var yAxisLabels: [UILabel] = []
    private var xAxisLabels: [UILabel] = []
    private var selectedIndex: Int?
    private var pulseAnimationStarted = false
    private var didSetCurrentIndicatorPosition = false
    private var shouldAnimateCurrentIndicatorOnNextDraw = false

    private let chartInsets = UIEdgeInsets(top: 12, left: 52, bottom: 34, right: 12)

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawChart()
    }

    // MARK: - Setup

    private func setupView() {
        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 1

        lineLayer.strokeColor = UIColor.systemTeal.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round

        selectedGuideLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        selectedGuideLayer.fillColor = UIColor.clear.cgColor
        selectedGuideLayer.lineWidth = 1
        selectedGuideLayer.lineDashPattern = [4, 4]

        selectedPointLayer.strokeColor = UIColor.white.cgColor
        selectedPointLayer.fillColor = UIColor.systemBlue.cgColor
        selectedPointLayer.lineWidth = 2

        layer.addSublayer(gridLayer)
        layer.addSublayer(lineLayer)
        layer.addSublayer(selectedGuideLayer)
        layer.addSublayer(selectedPointLayer)

        currentPricePulseView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        currentPricePulseView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)
        currentPricePulseView.layer.cornerRadius = 9
        currentPricePulseView.isUserInteractionEnabled = false
        addSubview(currentPricePulseView)

        currentPriceIndicatorView.frame = CGRect(x: 0, y: 0, width: 11, height: 11)
        currentPriceIndicatorView.backgroundColor = .systemTeal
        currentPriceIndicatorView.layer.borderColor = UIColor.white.cgColor
        currentPriceIndicatorView.layer.borderWidth = 2
        currentPriceIndicatorView.layer.cornerRadius = 5.5
        currentPriceIndicatorView.isUserInteractionEnabled = false
        addSubview(currentPriceIndicatorView)

        selectedValueLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedValueLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        selectedValueLabel.textColor = .white
        selectedValueLabel.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        selectedValueLabel.layer.cornerRadius = 6
        selectedValueLabel.layer.masksToBounds = true
        selectedValueLabel.textAlignment = .center
        selectedValueLabel.isHidden = true
        addSubview(selectedValueLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    private func rebuildLabels() {
        yAxisLabels.forEach { $0.removeFromSuperview() }
        xAxisLabels.forEach { $0.removeFromSuperview() }
        yAxisLabels.removeAll()
        xAxisLabels.removeAll()

        for _ in 0..<5 {
            let label = makeAxisLabel()
            yAxisLabels.append(label)
            addSubview(label)
        }

        for _ in 0..<5 {
            let label = makeAxisLabel()
            xAxisLabels.append(label)
            addSubview(label)
        }
    }

    private func makeAxisLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }

    // MARK: - Drawing

    private func drawChart() {
        guard bounds.width > 0, bounds.height > 0, !points.isEmpty else {
            gridLayer.path = nil
            lineLayer.path = nil
            selectedGuideLayer.path = nil
            selectedPointLayer.path = nil
            currentPricePulseView.isHidden = true
            currentPriceIndicatorView.isHidden = true
            selectedValueLabel.isHidden = true
            return
        }

        let chartRect = CGRect(
            x: chartInsets.left,
            y: chartInsets.top,
            width: max(1, bounds.width - chartInsets.left - chartInsets.right),
            height: max(1, bounds.height - chartInsets.top - chartInsets.bottom)
        )

        let prices = points.map(\.price)
        guard let minPriceRaw = prices.min(), let maxPriceRaw = prices.max() else { return }
        let range = max(maxPriceRaw - minPriceRaw, 1)
        let minPrice = minPriceRaw
        let maxPrice = minPriceRaw + range

        let yStep = chartRect.height / 4
        let gridPath = UIBezierPath()
        for index in 0..<5 {
            let y = chartRect.maxY - CGFloat(index) * yStep
            gridPath.move(to: CGPoint(x: chartRect.minX, y: y))
            gridPath.addLine(to: CGPoint(x: chartRect.maxX, y: y))

            let levelPrice = minPrice + (Double(index) / 4.0) * (maxPrice - minPrice)
            let label = yAxisLabels[index]
            label.text = String(format: "%.2f", levelPrice)
            label.frame = CGRect(x: 4, y: y - 7, width: chartInsets.left - 8, height: 14)
        }

        let xIndexes = axisIndexes(totalCount: points.count, targetCount: 5)
        xAxisLabels.forEach { $0.isHidden = true }
        for i in 0..<xIndexes.count {
            let index = xIndexes[i]
            let point = chartPoint(at: index, in: chartRect, minPrice: minPrice, maxPrice: maxPrice)

            gridPath.move(to: CGPoint(x: point.x, y: chartRect.minY))
            gridPath.addLine(to: CGPoint(x: point.x, y: chartRect.maxY))

            let label = xAxisLabels[i]
            label.text = points[index].title
            label.frame = CGRect(x: point.x - 22, y: chartRect.maxY + 4, width: 44, height: 14)
            label.isHidden = false
        }
        gridLayer.path = gridPath.cgPath

        let linePath = UIBezierPath()
        for index in points.indices {
            let point = chartPoint(at: index, in: chartRect, minPrice: minPrice, maxPrice: maxPrice)
            if index == 0 {
                linePath.move(to: point)
            } else {
                linePath.addLine(to: point)
            }
        }
        lineLayer.path = linePath.cgPath

        updateSelectionLayers(chartRect: chartRect, minPrice: minPrice, maxPrice: maxPrice)
        updateCurrentPriceIndicator(chartRect: chartRect, minPrice: minPrice, maxPrice: maxPrice)
    }

    private func updateSelectionLayers(chartRect: CGRect, minPrice: Double, maxPrice: Double) {
        guard let selectedIndex, points.indices.contains(selectedIndex) else {
            selectedGuideLayer.path = nil
            selectedPointLayer.path = nil
            selectedValueLabel.isHidden = true
            return
        }

        let selectedPoint = chartPoint(at: selectedIndex, in: chartRect, minPrice: minPrice, maxPrice: maxPrice)

        let guidePath = UIBezierPath()
        guidePath.move(to: CGPoint(x: selectedPoint.x, y: chartRect.minY))
        guidePath.addLine(to: CGPoint(x: selectedPoint.x, y: chartRect.maxY))
        selectedGuideLayer.path = guidePath.cgPath

        let circlePath = UIBezierPath(
            arcCenter: selectedPoint,
            radius: 5,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        selectedPointLayer.path = circlePath.cgPath

        selectedValueLabel.text = String(format: "  %.2f  ", points[selectedIndex].price)
        selectedValueLabel.sizeToFit()
        let x = min(max(6, selectedPoint.x - selectedValueLabel.bounds.width / 2), bounds.width - selectedValueLabel.bounds.width - 6)
        let y = max(6, selectedPoint.y - selectedValueLabel.bounds.height - 8)
        selectedValueLabel.frame = CGRect(origin: CGPoint(x: x, y: y), size: selectedValueLabel.bounds.size)
        selectedValueLabel.isHidden = false
    }

    private func updateCurrentPriceIndicator(chartRect: CGRect, minPrice: Double, maxPrice: Double) {
        guard !points.isEmpty else {
            currentPricePulseView.isHidden = true
            currentPriceIndicatorView.isHidden = true
            didSetCurrentIndicatorPosition = false
            return
        }

        let lastIndex = points.count - 1
        let point = chartPoint(at: lastIndex, in: chartRect, minPrice: minPrice, maxPrice: maxPrice)
        currentPricePulseView.isHidden = false
        currentPriceIndicatorView.isHidden = false

        let shouldAnimate = didSetCurrentIndicatorPosition && shouldAnimateCurrentIndicatorOnNextDraw
        if shouldAnimate {
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut]) {
                self.currentPricePulseView.center = point
                self.currentPriceIndicatorView.center = point
            }
        } else {
            currentPricePulseView.center = point
            currentPriceIndicatorView.center = point
            didSetCurrentIndicatorPosition = true
        }
        shouldAnimateCurrentIndicatorOnNextDraw = false

        startPulseAnimationIfNeeded()
    }

    private func startPulseAnimationIfNeeded() {
        guard !pulseAnimationStarted else { return }
        pulseAnimationStarted = true

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.5
        opacityAnimation.duration = 0.8
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.5
        scaleAnimation.duration = 0.8
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity

        currentPricePulseView.layer.add(opacityAnimation, forKey: "pulse.opacity")
        currentPricePulseView.layer.add(scaleAnimation, forKey: "pulse.scale")
    }

    // MARK: - Live Updates

    func appendLivePoint(_ point: LinePointData, keepCount: Int, animated: Bool) {
        let oldLinePath = lineLayer.path

        var updatedPoints = points
        updatedPoints.append(point)
        if updatedPoints.count > keepCount {
            updatedPoints.removeFirst(updatedPoints.count - keepCount)
        }

        shouldAnimateCurrentIndicatorOnNextDraw = animated
        points = updatedPoints
        layoutIfNeeded()

        guard animated else { return }
        animatePathChange(layer: lineLayer, from: oldLinePath, to: lineLayer.path, key: "line.path")

        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0.9
        strokeAnimation.toValue = 1
        strokeAnimation.duration = 0.35
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        lineLayer.add(strokeAnimation, forKey: "line.strokeEnd")
    }

    func animatePathChange(layer: CAShapeLayer, from: CGPath?, to: CGPath?, key: String) {
        guard let from, let to else { return }
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = from
        animation.toValue = to
        animation.duration = 0.35
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: key)
    }

    private func axisIndexes(totalCount: Int, targetCount: Int) -> [Int] {
        guard totalCount > 0 else { return [] }
        guard totalCount > targetCount else { return Array(0..<totalCount) }

        var result: [Int] = []
        let step = Double(totalCount - 1) / Double(targetCount - 1)
        for index in 0..<targetCount {
            let value = Int(round(Double(index) * step))
            if result.last != value {
                result.append(value)
            }
        }
        if result.count < targetCount, result.last != totalCount - 1 {
            result.append(totalCount - 1)
        }
        return Array(result.prefix(targetCount))
    }

    private func chartPoint(at index: Int, in rect: CGRect, minPrice: Double, maxPrice: Double) -> CGPoint {
        let xStep = points.count > 1 ? rect.width / CGFloat(points.count - 1) : 0
        let x = rect.minX + CGFloat(index) * xStep

        let price = points[index].price
        let normalized = (price - minPrice) / max(maxPrice - minPrice, 1)
        let y = rect.maxY - CGFloat(normalized) * rect.height

        return CGPoint(x: x, y: y)
    }

    // MARK: - Actions

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard !points.isEmpty else { return }

        let location = recognizer.location(in: self)
        let chartRect = CGRect(
            x: chartInsets.left,
            y: chartInsets.top,
            width: max(1, bounds.width - chartInsets.left - chartInsets.right),
            height: max(1, bounds.height - chartInsets.top - chartInsets.bottom)
        )

        guard chartRect.contains(location) else { return }

        let prices = points.map(\.price)
        guard let minPrice = prices.min(), let maxPrice = prices.max() else { return }

        var nearestIndex = 0
        var nearestDistance = CGFloat.greatestFiniteMagnitude

        for index in points.indices {
            let point = chartPoint(at: index, in: chartRect, minPrice: minPrice, maxPrice: maxPrice)
            let distance = abs(point.x - location.x)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        selectedIndex = nearestIndex
        setNeedsLayout()
        onPointSelected?(nearestIndex)
    }
}
