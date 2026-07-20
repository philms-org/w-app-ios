
import UIKit

class GroupChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    var close: (() -> ())?

    var id = String()
    var titleString = String()
    var isAdmin = Bool()
    var isMute = Bool()
    var messagesArray: [WAPMessage] = []

    var keyboardHeight = CGFloat()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        messageView.isHidden = false
        nameLabel.text = titleString
        indicator.startAnimating()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        reload()
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let messages = try await WAPData.shared.fetchMessages(conversationId: id)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.messagesArray = messages
                    self.tableView.reloadData()
                    self.indicator.stopAnimating()
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

    // MARK: - UITableViewDataSource / Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messagesArray.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messagesArray[indexPath.row]
        let isMine = message.senderId == WAPAuth.currentUserID
        if isMine {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRightCell", for: indexPath) as? ChatRightCell else {
                assertionFailure("GroupChatVC storyboard cell identifier drifted from \"ChatRightCell\"")
                return UITableViewCell()
            }
            let customCell = CustomCell(string1: message.id,
                                         string2: message.content,
                                         string3: message.createdAt.asMessageTimeDisplay())
            cell.updateCell(customCell: customCell)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChatCell", for: indexPath) as? GroupChatCell else {
                assertionFailure("GroupChatVC storyboard cell identifier drifted from \"GroupChatCell\"")
                return UITableViewCell()
            }
            let customCell = CustomCell(string1: message.id,
                                         string2: message.profile?.displayName ?? "",
                                         string3: message.content,
                                         string4: message.createdAt.asMessageTimeDisplay(),
                                         string5: "")
            cell.updateCell(customCell: customCell)
            return cell
        }
    }

    // MARK: - IBActions

    @IBAction func back(_ sender: UIButton) {
        close?()
    }

    @IBAction func menu(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "GroupMembersVC") as? GroupMembersVC {
            vc.groupID = id
            vc.isAdmin = isAdmin
            if navigationController != nil {
                navigationController?.pushViewController(vc, animated: true)
            } else {
                vc.close = { [weak self] in
                    self?.dismiss(animated: true)
                }
                vc.modalPresentationStyle = .currentContext
                present(vc, animated: true)
            }
        }
    }

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
