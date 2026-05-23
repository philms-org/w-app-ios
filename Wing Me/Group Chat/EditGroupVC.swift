
import UIKit

class EditGroupVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!
    
    var reloadGroup: (() -> ())?
    
    var groupID = String()
    var titleString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.text = titleString
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
    
    @IBAction func save(_ sender: UIButton) {
        guard !titleTextField.getText().isEmpty else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        sendData()
    }
}
