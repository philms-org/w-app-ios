
import UIKit

@IBDesignable
class UIViewDesignable: UIView {
    
    override class var layerClass: AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
    
    @IBInspectable var FirstColor: UIColor = UIColor.clear {
        didSet {
            updateFrame()
        }
    }
    
    @IBInspectable var SecondColor: UIColor = UIColor.clear {
        didSet {
            updateFrame()
        }
    }
    
    @IBInspectable var Horizontal: Bool = false {
        didSet {
            updateFrame()
        }
    }
    
    @IBInspectable var Diagonal: Bool = false {
        didSet {
            updateFrame()
        }
    }
    
    @IBInspectable var BorderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = BorderWidth
        }
    }
    
    @IBInspectable var BorderColor: UIColor = .clear {
        didSet {
            self.layer.borderColor = BorderColor.cgColor
        }
    }
    
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
            self.layer.shadowOffset = CGSize(width: 3, height: 3)
        }
    }
    
    func updateFrame() {
        let layer = self.layer as! CAGradientLayer
        layer.colors = [FirstColor.cgColor, SecondColor.cgColor]
        
        if Diagonal {
            if Horizontal {
                layer.startPoint = CGPoint(x: 0.0, y: 0.0)
                layer.endPoint = CGPoint(x: 1.0, y: 1.0)
            } else {
                layer.startPoint = CGPoint(x: 1.0, y: 0.0)
                layer.endPoint = CGPoint(x: 0.0, y: 1.0)
            }
        } else {
            if Horizontal {
                layer.startPoint = CGPoint(x: 0.0, y: 0.5)
                layer.endPoint = CGPoint(x: 1.0, y: 0.5)
            } else {
                layer.startPoint = CGPoint(x: 0.5, y: 0.0)
                layer.endPoint = CGPoint(x: 0.5, y: 1.0)
            }
        }
    }
}
