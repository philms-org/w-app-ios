
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

    var keyboardHeight = CGFloat()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        checkmarkImageView.isHidden = true
        messageView.isHidden = true
        acceptView.isHidden = true
        nameLabel.text = ""
        detailsLabel.text = ""
        indicator.stopAnimating()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - UITableViewDataSource / Delegate stubs

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }

    // MARK: - IBActions

    @IBAction func back(_ sender: UIButton) {
        close?()
    }

    @IBAction func menu(_ sender: UIButton) { }

    @IBAction func viewImage(_ sender: UIButton) { }

    @IBAction func send(_ sender: UIButton) { }

    @IBAction func accept(_ sender: UIButton) { }

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
