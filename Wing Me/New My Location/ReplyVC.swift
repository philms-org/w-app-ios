
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
        request()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplyCell", for: indexPath) as! ReplyCell
        cell.delegate = self
        cell.updateCell(item: commentsArray[indexPath.row], isMyComment: comment.isMyComment)
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = commentsArray[indexPath.row]
        
        if isMaster || isOwner {
            var assignBadgeAction: UIContextualAction {
                if item.badgeTitle.isEmpty {
                    return UIContextualAction(style: .normal, title: "Assign Badge") {
                        (_, _, _) in
                        self.openBadges(item: item)
                    }
                } else {
                    return UIContextualAction(style: .normal, title: "Remove Badge") {
                        (_, _, _) in
                        self.indicator.startAnimating()
                        self.removeBadge(comment: item)
                    }
                }
            }
            
            let deleteRowAction = UIContextualAction(style: .destructive, title: Strings.delete) {
                (_, _, _) in
                self.indicator.startAnimating()
                self.deleteComment(commentID: item.id)
            }
            return UISwipeActionsConfiguration(actions: [assignBadgeAction, deleteRowAction])
        } else if item.isMyComment {
            let deleteRowAction = UIContextualAction(style: .destructive, title: Strings.delete) {
                (_, _, _) in
                self.indicator.startAnimating()
                self.deleteComment(commentID: item.id)
            }
            return UISwipeActionsConfiguration(actions: [deleteRowAction])
        }
        return nil
    }
    
    func openProfile(cell: UITableViewCell) {
        guard let indexPath = commentsTableView.indexPath(for: cell) else {
            return
        }
        let item = commentsArray[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as? UserProfileVC {
            viewController.id = item.userID
            viewController.close = {
                self.dismiss(animated: true)
            }
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func like(cell: UITableViewCell) {
        guard let indexPath = commentsTableView.indexPath(for: cell) else {
            return
        }
        let item = commentsArray[indexPath.row]
        
        if item.isLiked {
            commentsArray[indexPath.row].isLiked = false
            commentsArray[indexPath.row].likes -= 1
            deleteLike(commentID: item.id)
        } else {
            commentsArray[indexPath.row].isLiked = true
            commentsArray[indexPath.row].likes += 1
            addLike(commentID: item.id)
        }
        commentsTableView.reloadData()
    }
    
    func add(cell: UITableViewCell) {
        guard let indexPath = commentsTableView.indexPath(for: cell) else {
            return
        }
        let item = commentsArray[indexPath.row]
        
        indicator.startAnimating()
        
        if item.isAdded {
            deleteUserGroup(userID: item.userID)
        } else {
            addUserGroup(userID: item.userID)
        }
    }
    
    @IBAction func send(_ sender: UIButton) {
        guard !commentTextField.getText().isEmpty else {
            return
        }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        addComment()
    }
    
    @objc func KeyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            
            var keyboardHeight = CGFloat()
            
            if view.safeAreaInsets.bottom > 0 {
                keyboardHeight = keyboardRectangle.height - view.safeAreaInsets.bottom
            } else {
                keyboardHeight = keyboardRectangle.height
            }
            UIView.animate(withDuration: 0.2, delay: 0.1) {
                self.commentView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            }
        }
    }
    
    @objc func KeyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            self.commentView.transform = .identity
        })
    }
    
    func openBadges(item: CommentStruct) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "BadgesVC") as? BadgesVC {
            viewController.assignBadge = {
                id in
                self.indicator.startAnimating()
                self.assignBadge(comment: item, badgeID: id)
            }
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
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
            likeButton.tintColor = UIColor.white
        }
    }
    
    func reload() {
        indicator.startAnimating()
        request()
    }
    
    func request() {
        let path = "get_replies.php"
        
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "comment_Id": comment.id,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: "")
                ]
            } else {
                return [
                    "language": Strings.language,
                    "comment_Id": comment.id,
                    "location_Id": locationID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            commentsArray = []
            
            for each in message {
                let imageView = UIImageView()
                imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                             tableView: commentsTableView)
                
                let badgeImageView = UIImageView()
                badgeImageView.imageFromServerURL(urlString: each.getString(key: "badges_image"),
                                                  tableView: commentsTableView,
                                                  tint: Colors.black)
                
                commentsArray.append(CommentStruct(imageView: imageView,
                                                   badgeImageView: badgeImageView,
                                                   id: each.getString(key: "Id"),
                                                   userID: each.getString(key: "user_Id"),
                                                   name: each.getString(key: "name"),
                                                   age: each.getString(key: "age"),
                                                   gender: each.getString(key: "gender"),
                                                   country: each.getString(key: "nationality"),
                                                   city: each.getString(key: "city"),
                                                   comment: each.getString(key: "comment"),
                                                   likes: each.getInt(key: "number_of_like"),
                                                   isMyComment: each.getBool(key: "is_my_comment"),
                                                   isLiked: each.getBool(key: "is_liked"),
                                                   isAdded: each.getBool(key: "in_group"),
                                                   badgeTitle: each.getString(key: "badges_title")))
            }
            commentsTableView.reloadData()
        }
    }
    
    func addComment() {
        let path = "add_reply.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": comment.id,
            "comment": commentTextField.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: addCommentStopLoading, requestSuccess: addCommentSuccess)
    }
    
    func addCommentStopLoading() {
        sendButton.isHidden = false
        sendIndicator.stopAnimating()
    }
    
    func addCommentSuccess(jsonObject: AnyObject) {
        commentTextField.text = ""
        
        reload()
    }
    
    func addLike(commentID: String) {
        let path = "add_like.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": commentID
        ]
        
        params.request(delegate: self, path: path, stopLoading: addLikeStopLoading, requestSuccess: addLikeSuccess)
    }
    
    func addLikeStopLoading() {
        
    }
    
    func addLikeSuccess(jsonObject: AnyObject) {
        
    }
    
    func deleteLike(commentID: String) {
        let path = "delete_comment_likes.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": commentID
        ]
        
        params.request(delegate: self, path: path, stopLoading: deleteLikeStopLoading, requestSuccess: deleteLikeSuccess)
    }
    
    func deleteLikeStopLoading() {
        
    }
    
    func deleteLikeSuccess(jsonObject: AnyObject) {
        
    }
    
    func deleteComment(commentID: String) {
        let path = "delete_comment.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": commentID
        ]
        
        params.request(delegate: self, path: path, stopLoading: deleteCommentStopLoading, requestSuccess: deleteCommentSuccess)
    }
    
    func deleteCommentStopLoading() {
        indicator.stopAnimating()
    }
    
    func deleteCommentSuccess(jsonObject: AnyObject) {
        reload()
    }
    
    func addUserGroup(userID: String) {
        let path = "add_user_group.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": comment.id,
            "user_Id": userID
        ]
        
        params.request(delegate: self, path: path, stopLoading: addUserGroupStopLoading, requestSuccess: {
            jsonObject in
            self.addUserGroupSuccess(jsonObject: jsonObject, userID: userID)
        })
    }
    
    func addUserGroupStopLoading() {
        indicator.stopAnimating()
    }
    
    func addUserGroupSuccess(jsonObject: AnyObject, userID: String) {
        for (index, each) in commentsArray.enumerated() {
            if each.userID == userID {
                commentsArray[index].isAdded = true
            }
        }
        commentsTableView.reloadData()
        
        appDelegate.reloadGroups?()
    }
    
    func deleteUserGroup(userID: String) {
        let path = "remove_user_group.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": comment.id,
            "user_Id": userID
        ]
        
        params.request(delegate: self, path: path, stopLoading: deleteUserGroupStopLoading, requestSuccess: {
            jsonObject in
            self.deleteUserGroupSuccess(jsonObject: jsonObject, userID: userID)
        })
    }
    
    func deleteUserGroupStopLoading() {
        indicator.stopAnimating()
    }
    
    func deleteUserGroupSuccess(jsonObject: AnyObject, userID: String) {
        for (index, each) in commentsArray.enumerated() {
            if each.userID == userID {
                commentsArray[index].isAdded = false
            }
        }
        commentsTableView.reloadData()
    }
    
    func assignBadge(comment: CommentStruct, badgeID: String) {
        var path: String {
            if isMaster {
                return "master_assign_badge.php"
            } else {
                return "assign_badge.php"
            }
        }
        
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: ""),
                    "user_Id": comment.userID,
                    "badge_Id": badgeID
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID,
                    "user_Id": comment.userID,
                    "badge_Id": badgeID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: assignBadgeStopLoading, requestSuccess: assignBadgeSuccess)
    }
    
    func assignBadgeStopLoading() {
        indicator.stopAnimating()
    }
    
    func assignBadgeSuccess(jsonObject: AnyObject) {
        reload()
    }
    
    func removeBadge(comment: CommentStruct) {
        var path: String {
            if isMaster {
                return "master_remove_badge.php"
            } else {
                return "remove_badge.php"
            }
        }
        
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: ""),
                    "user_Id": comment.userID
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID,
                    "user_Id": comment.userID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: removeBadgeStopLoading, requestSuccess: removeBadgeSuccess)
    }
    
    func removeBadgeStopLoading() {
        indicator.stopAnimating()
    }
    
    func removeBadgeSuccess(jsonObject: AnyObject) {
        reload()
    }
}
