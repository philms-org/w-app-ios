
import UIKit

@IBDesignable
class UItextFieldDesignable: UITextField {
    
    @IBInspectable var PlaceholderColor: UIColor = UIColor.black {
        didSet {
            if let placeholder = self.placeholder {
                self.attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [.foregroundColor: PlaceholderColor]
                )
            } else {
                self.attributedPlaceholder = NSAttributedString(
                    string: "",
                    attributes: [.foregroundColor: PlaceholderColor]
                )
            }
        }
    }
}
