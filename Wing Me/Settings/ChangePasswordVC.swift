
import UIKit

class ChangePasswordVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var oldTextField: UITextField!
    @IBOutlet weak var newTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var changeIndicator: UIActivityIndicatorView!
    
    var fromLogin = Bool()

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
    
    @IBAction func change(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !oldTextField.getText().isEmpty && !newTextField.getText().isEmpty && !confirmTextField.getText().isEmpty else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        guard newTextField.getText() == confirmTextField.getText() else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertBoth)
            return
        }
        changeButton.isHidden = true
        changeIndicator.startAnimating()
        change()
    }
    
    func change() {
        let path = "change_password.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "old_password": oldTextField.getText(),
            "new_password": newTextField.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        changeButton.isHidden = false
        changeIndicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            let token = message.getString(key: "token")
            UserDefaults.standard.set(token, forKey: "Token")
            
            if fromLogin {
                openMain()
            } else {
                let alertClass = AlertClass()
                alertClass.showSuccessAlert(delegate: self, message: Strings.alertPasswordChanged, action: {
                    self.dismiss(animated: true)
                })
            }
        }
    }
    
    func openMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
