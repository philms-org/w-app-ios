
import UIKit

class ContactVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!
    
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
    
    @IBAction func send(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !nameTextField.getText().isEmpty && !phoneTextField.getPhone().isEmpty && !messageTextView.getText().isEmpty else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        send()
    }
    
    func send() {
        let path = "contact_us.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "name": nameTextField.getText(),
            "phone": phoneTextField.getPhone(),
            "text": messageTextView.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        sendButton.isHidden = false
        sendIndicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        let alertClass = AlertClass()
        alertClass.showSuccessAlert(delegate: self, message: Strings.alertMessageSent, action: {
            self.dismiss(animated: true)
        })
    }
}
