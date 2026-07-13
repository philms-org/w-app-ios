
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
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent, action: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}
