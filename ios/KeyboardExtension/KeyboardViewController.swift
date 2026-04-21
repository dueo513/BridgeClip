import UIKit

class KeyboardViewController: UIInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        self.view.backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1.0) // Dark Mode

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 16),
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Antigravity Clipboard Drawer"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        stackView.addArrangedSubview(titleLabel)

        // Mock Button
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Paste: https://github.com/flutter...", for: .normal)
        copyButton.backgroundColor = UIColor(red: 26/255, green: 115/255, blue: 232/255, alpha: 1.0)
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 8
        copyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        copyButton.addTarget(self, action: #selector(pasteText), for: .touchUpInside)
        stackView.addArrangedSubview(copyButton)
    }

    @objc func pasteText() {
        let textToPaste = "https://github.com/flutter/flutter"
        self.textDocumentProxy.insertText(textToPaste)
        // Give haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
