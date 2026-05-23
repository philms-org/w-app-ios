
import UIKit

class AddBadgeVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addIndicator: UIActivityIndicatorView!
    
    var reloadBadges: (() -> ())?
    
    var categoryID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addPicture(_ sender: UIButton) {
        showPicker(button: sender)
    }
    
    @IBAction func add(_ sender: UIButton) {
        guard !titleTextField.getText().isEmpty else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        addButton.isHidden = true
        addIndicator.startAnimating()
        sendData()
    }
}
