
import UIKit

@IBDesignable
class ShadowDesignable: UIView {
    
    @IBInspectable var CornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = CornerRadius
        }
    }
    
    @IBInspectable var ShadowRadius: CGFloat = 0 {
        didSet {
            self.layer.shadowRadius = ShadowRadius
        }
    }
    
    @IBInspectable var ShadowOpacity: Float = 0 {
        didSet {
            self.layer.shadowOpacity = ShadowOpacity
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
        }
    }
    
    @IBInspectable var ShadowColor: UIColor = UIColor.clear {
        didSet {
            self.layer.shadowColor = ShadowColor.cgColor
        }
    }
}
