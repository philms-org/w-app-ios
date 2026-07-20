
import UIKit

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var genderView: ShadowDesignable!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var textFieldView: UIViewDesignable!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    @IBOutlet weak var acceptView: UIView!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var rejectIndicator: UIActivityIndicatorView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var acceptIndicator: UIActivityIndicatorView!

    var close: (() -> ())?

    var id = String()
    var gender = String()
    var blocked = String()

    var messagesArray: [WAPMessage] = []
    var myStatus = "accepted"

    var keyboardHeight = CGFloat()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        checkmarkImageView.isHidden = true
        messageView.isHidden = true
        acceptView.isHidden = true
        nameLabel.text = ""
        detailsLabel.text = ""
        genderView.isHidden = true
        indicator.startAnimating()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        reload()
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            var status = "accepted"
            do {
                status = try await WAPData.shared.fetchConversationStatus(conversationId: id)
            } catch {
                // Non-fatal: fall back to "accepted" so the message thread still loads;
                // the messages fetch below has its own error alert.
                print("ChatVC: failed to fetch conversation status, defaulting to \"accepted\": \(error.localizedDescription)")
            }
            do {
                let messages = try await WAPData.shared.fetchMessages(conversationId: id)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.messagesArray = messages
                    self.myStatus = status
                    if let first = messages.first(where: { $0.senderId != WAPAuth.currentUserID }) {
                        self.nameLabel.text = first.profile?.displayName ?? ""
                    }
                    self.tableView.reloadData()
                    self.indicator.stopAnimating()
                    self.updateRequestUI()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func updateRequestUI() {
        let isPendingRecipient = myStatus == "pending"
        acceptView.isHidden = !isPendingRecipient
        messageView.isHidden = isPendingRecipient
    }

    // MARK: - UITableViewDataSource / Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messagesArray.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messagesArray[indexPath.row]
        let isMine = message.senderId == WAPAuth.currentUserID
        let customCell = CustomCell(string1: message.id, string2: message.content, string3: message.createdAt.asMessageTimeDisplay())
        if isMine {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRightCell", for: indexPath) as? ChatRightCell else {
                assertionFailure("ChatVC storyboard cell identifier drifted from \"ChatRightCell\"")
                return UITableViewCell()
            }
            cell.updateCell(customCell: customCell)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatLeftCell", for: indexPath) as? ChatLeftCell else {
                assertionFailure("ChatVC storyboard cell identifier drifted from \"ChatLeftCell\"")
                return UITableViewCell()
            }
            cell.updateCell(customCell: customCell, gender: gender)
            return cell
        }
    }

    // MARK: - IBActions

    @IBAction func back(_ sender: UIButton) {
        close?()
    }

    @IBAction func menu(_ sender: UIButton) { }

    @IBAction func viewImage(_ sender: UIButton) { }

    @IBAction func send(_ sender: UIButton) {
        let text = messageTextView.getText()
        guard !text.isEmpty else { return }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPData.shared.sendMessage(conversationId: id, content: text)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.messageTextView.text = ""
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    self.reload()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.sendButton.isHidden = false
                    self.sendIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func accept(_ sender: UIButton) {
        respond(accept: true)
    }

    @IBAction func reject(_ sender: UIButton) {
        respond(accept: false)
    }

    func respond(accept: Bool) {
        let indicatorView = accept ? acceptIndicator : rejectIndicator
        indicatorView?.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPData.shared.respondToConversationRequest(conversationId: id, accept: accept)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    indicatorView?.stopAnimating()
                    self.myStatus = accept ? "accepted" : "rejected"
                    if accept {
                        self.updateRequestUI()
                    } else {
                        self.close?()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    indicatorView?.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Keyboard

    @objc func KeyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let rect = keyboardFrame.cgRectValue
            keyboardHeight = view.safeAreaInsets.bottom > 0 ? rect.height - view.safeAreaInsets.bottom : rect.height
        }
    }

    @objc func KeyboardWillHide(notification: NSNotification) {
        keyboardHeight = 0
    }
}
