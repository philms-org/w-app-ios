
import UIKit

class SendMessageVC: UIViewController {

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    var usersArray: [UserClass] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func send(_ sender: UIButton) {
        view.endEditing(true)
        guard !messageTextView.getText().isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
