
import UIKit

final class ViewController: UIViewController {

    let headerImageView = UIImageView()
    let containerView = UIView()
    let filterStack = UIStackView()
    let runButton = UIButton(type: .system)
    let outputTextView = UITextView()
    let botSwitch = UISwitch()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        setupHeaderImage()
        setupContainer()
        setupFilter()
        setupButton()
        setupOutput()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutUI()
    }
    
    func setupHeaderImage() {
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.image = UIImage(named: "fordz")
        view.addSubview(headerImageView)
        headerImageView.layer.cornerRadius = 10
    }
    
    func setupContainer() {
        containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(containerView)
    }
    
    func setupFilter() {
        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterStack.distribution = .equalSpacing
        let label = UILabel()
        label.text = "Торговый бот"
        filterStack.addArrangedSubview(label)
        filterStack.addArrangedSubview(botSwitch)
        filterStack.addArrangedSubview(UIView())
        containerView.addSubview(filterStack)
        containerView.layer.cornerRadius = 10
    }
    
    func setupButton() {
        runButton.setTitle("Начать торговлю", for: .normal)
        runButton.backgroundColor = .systemBlue
        runButton.setTitleColor(.black, for: .normal)
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        containerView.addSubview(runButton)
    }
    
    func setupOutput() {
        outputTextView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        outputTextView.font = UIFont.systemFont(ofSize: 16)
        outputTextView.layer.cornerRadius = 10
        outputTextView.isEditable = false
        view.addSubview(outputTextView)
    }
    
    func layoutUI() {
        let safe = view.safeAreaInsets
        let margin: CGFloat = 20
        let width = view.frame.width - margin * 2
        let headerHeight = min(view.frame.height * 0.2, 180)
        
        headerImageView.frame = CGRect(x: margin, y: safe.top, width: width, height: headerHeight)
        
        let containerTop = headerImageView.frame.maxY + 20
        let containerHeight: CGFloat = 180
        
        containerView.frame = CGRect(x: margin, y: containerTop, width: width, height: containerHeight)
        filterStack.frame = CGRect(x: 10, y: 20, width: containerView.frame.width - 20, height: 40)
        runButton.frame = CGRect(x: 20, y: 80, width: containerView.frame.width - 40, height: 50)
        
        outputTextView.frame = CGRect(
            x: margin,
            y: containerView.frame.maxY + 20,
            width: width,
            height: view.frame.height - containerView.frame.maxY - safe.bottom - 20
        )
    }
    
    @objc func runTapped() {
        outputTextView.text = ""
        
        func append(_ text: String) {
            DispatchQueue.main.async {
                self.outputTextView.text += text + "\n"
                let range = NSRange(location: max(0, self.outputTextView.text.count - 1), length: 0)
                self.outputTextView.scrollRangeToVisible(range)
            }
        }
        
        let trader = Trader(balance: 10000, currency: .usd)
        let bot = TradingBot(trader: trader)
        bot.onUpdate = append
        
        DispatchQueue.global().async {
            bot.startTrading()
        }
    }
}
