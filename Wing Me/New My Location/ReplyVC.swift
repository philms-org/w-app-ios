
import UIKit

class ReplyVC: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, ReplyDelegate {

    @IBOutlet weak var genderView: ShadowDesignable!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentTextField: UItextFieldDesignable!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!

    var commentsArray: [CommentStruct] = []
    var comment: CommentStruct!
    var locationID = String()
    var isMaster = Bool()
    var isOwner = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        setKeyboard()
        setUI()
        indicator.stopAnimating()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }

    func openProfile(cell: UITableViewCell) { }
    func like(cell: UITableViewCell) { }
    func add(cell: UITableViewCell) { }

    @IBAction func send(_ sender: UIButton) { }

    @objc func KeyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let rect = keyboardFrame.cgRectValue
            let h = view.safeAreaInsets.bottom > 0 ? rect.height - view.safeAreaInsets.bottom : rect.height
            UIView.animate(withDuration: 0.2, delay: 0.1) {
                self.commentView.transform = CGAffineTransform(translationX: 0, y: -h)
            }
        }
    }

    @objc func KeyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2) { self.commentView.transform = .identity }
    }

    func setUI() {
        userImageView.image = comment.imageView.image
        nameLabel.text = comment.name
        commentLabel.text = comment.comment
        likesLabel.text = "\(comment.likes)"
        
        if comment.age.isEmpty {
            if comment.city.isEmpty {
                if let emoji = Constants.flags[comment.country] {
                    detailsLabel.text = "\(emoji)"
                } else {
                    detailsLabel.isHidden = true
                }
            } else {
                if let emoji = Constants.flags[comment.country] {
                    detailsLabel.text = "\(comment.city) \(emoji)"
                } else {
                    detailsLabel.text = "\(comment.city)"
                }
            }
        } else {
            if comment.city.isEmpty {
                if let emoji = Constants.flags[comment.country] {
                    detailsLabel.text = "Age: \(comment.age) \(emoji)"
                } else {
                    detailsLabel.text = "Age: \(comment.age)"
                }
            } else {
                if let emoji = Constants.flags[comment.country] {
                    detailsLabel.text = "Age: \(comment.age), \(comment.city) \(emoji)"
                } else {
                    detailsLabel.text = "Age: \(comment.age), \(comment.city)"
                }
            }
        }
        if comment.gender == "F" {
            genderView.layer.shadowColor = Colors.pink.cgColor
        } else {
            genderView.layer.shadowColor = Colors.blue.cgColor
        }
        if comment.isLiked {
            likeButton.setImage(UIImage(named: "icon_heart_full"), for: .normal)
            likeButton.tintColor = Colors.red
        } else {
            likeButton.setImage(UIImage(named: "icon_heart"), for: .normal)
            likeButton.tintColor = .white
        }
    }
}
