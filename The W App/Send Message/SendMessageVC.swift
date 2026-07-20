
import UIKit

class SendMessageVC: UIViewController {

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    var usersArray: [UserClass] = []
    var isGroup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func send(_ sender: UIButton) {
        view.endEditing(true)
        let text = messageTextView.getText()
        guard !text.isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let name = self.isGroup ? self.usersArray.map { $0.name }.joined(separator: ", ") : nil
                _ = try await WAPData.shared.startConversation(
                    recipientIds: self.usersArray.map { $0.id },
                    name: name,
                    isGroup: self.isGroup,
                    firstMessage: text
                )
                await MainActor.run {
                    AlertClass().showSuccessAlert(delegate: self, message: Strings.alertMessageSent) { [weak self] in
                        self?.dismiss(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
}
