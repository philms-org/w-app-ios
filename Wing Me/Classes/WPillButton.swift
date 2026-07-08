import UIKit

final class WPillButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = Colors.back_gray
        layer.cornerRadius = 10
        layer.masksToBounds = true

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            return outgoing
        }
        configuration = config

        configurationUpdateHandler = { button in
            button.configuration?.baseForegroundColor = button.state == .disabled
                ? UIColor.white.withAlphaComponent(0.5)
                : .white
        }
    }

    // Teal accent variant used for primary CTAs (Save, Verify, etc.)
    func applyTealStyle() {
        backgroundColor = Colors.blue
    }
}
