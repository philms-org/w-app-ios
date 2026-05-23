
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
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        send()
    }
    
    func send() {
        let path = "send_mass_message.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "users": getUsers(),
            "message": messageTextView.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: sendStopLoading, requestSuccess: sendSuccess)
    }
    
    func sendStopLoading() {
        sendButton.isHidden = false
        sendIndicator.stopAnimating()
    }
    
    func sendSuccess(jsonObject: AnyObject) {
        appDelegate.reloadMessages?()
        
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent) {
            self.dismiss(animated: true)
        }
    }
    
    func getUsers() -> String {
        var array: [String] = []
        
        for each in usersArray where each.isSelected {
            array.append(each.id)
        }
        let data = try? JSONSerialization.data(withJSONObject: array)
        let jsonObject = String(data: data!, encoding: .utf8)!
        return jsonObject
    }
}
