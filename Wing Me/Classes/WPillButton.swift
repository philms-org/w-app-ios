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
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        layer.cornerRadius = 10
        layer.masksToBounds = true
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    // Teal accent variant used for primary CTAs (Save, Verify, etc.)
    func applyTealStyle() {
        backgroundColor = Colors.blue
    }
}
