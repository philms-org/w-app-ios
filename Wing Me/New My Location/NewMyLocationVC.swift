
import UIKit
import SafariServices

class NewMyLocationVC: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, ReplyDelegate {
    
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var commentView: UIViewDesignable!
    @IBOutlet weak var commentTextField: UItextFieldDesignable!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var noLocationView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var bannerArray: [BannerStruct] = []
    var commentsArray: [CommentStruct] = []
    var usersArray: [CustomCell] = []
    
    var delegate: MainVC!
    var myComment: CommentStruct!
    var timer: Timer!
    
    var locationID = String()
    var inLocation = Bool()
    var isMaster = Bool()
    var isOwner = Bool()
    
    var bannerIndex = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationView.isHidden = true
        bannerView.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        appDelegate.reloadLocation = {
            self.reload()
        }
        delegate.wingIn = {
            customCell in
            self.wingIn(customCell: customCell)
        }
        delegate.hideLocation = {
            self.hideLocation()
        }
        setKeyboard()
        
        let locationID = UserDefaults.getString(key: "LocationID")
        let locationName = UserDefaults.getString(key: "LocationName")
        
        if locationID.contains("Event") {
            let customCell = CustomCell(string1: locationID, string2: locationName)
            wingIn(customCell: customCell)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bannerArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LocationBannerCell", for: indexPath) as! LocationBannerCell
        cell.updateCell(item: bannerArray[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = bannerArray[indexPath.row]
        
        if item.url.isEmpty {
            if !item.blurred, let image = item.imageView.image {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let viewController = storyboard.instantiateViewController(withIdentifier: "FullImageVC") as? FullImageVC {
                    viewController.image = image
                    viewController.modalTransitionStyle = .crossDissolve
                    viewController.modalPresentationStyle = .overFullScreen
                    present(viewController, animated: true, completion: nil)
                }
            }
        } else if let encodedURL = (item.url).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                
                let viewController = SFSafariViewController(url: url, configuration: config)
                present(viewController, animated: true)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            bannerIndex = Int(collectionView.contentOffset.x/collectionView.frame.width)
            pageControl.currentPage = bannerIndex
            
            let item = bannerArray[bannerIndex]
            updateUI(item: item)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let _ = myComment {
                return 1
            } else {
                return 0
            }
        } else if section == 1 {
            return commentsArray.count
        } else {
            return usersArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
            cell.updateCell(item: myComment)
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReplyCell", for: indexPath) as! ReplyCell
            cell.delegate = self
            cell.updateCell(item: commentsArray[indexPath.row], isMyComment: false)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationPersonCell", for: indexPath) as! LocationPersonCell
            cell.updateCell(customCell: usersArray[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
        } else if indexPath.section == 1 {
            let item = commentsArray[indexPath.row]
            openReplies(comment: item)
        } else {
            let customCell = usersArray[indexPath.row]
            
            if customCell.isMaster {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let viewController = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
                    viewController.id = customCell.string1
                    viewController.close = {
                        self.dismiss(animated: true)
                    }
                    viewController.modalPresentationStyle = .currentContext
                    delegate.present(viewController, animated: true, completion: nil)
                }
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let viewController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as? UserProfileVC {
                    viewController.id = customCell.string1
                    viewController.close = {
                        self.dismiss(animated: true)
                    }
                    viewController.modalPresentationStyle = .currentContext
                    delegate.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            return nil
        } else if indexPath.section == 1 {
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
        } else {
            let customCell = usersArray[indexPath.row]
            
            let messageRowAction = UIContextualAction(style: .normal, title: Strings.message) {
                (_, _, _) in
                self.openChat(customCell: customCell)
            }
            return UISwipeActionsConfiguration(actions: [messageRowAction])
        }
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
        
    }
    
    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .down
        present(activity, animated: true, completion: nil)
    }
    
    @IBAction func wingOut(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: Strings.checkOut, style: .destructive) {
            _ in
            appDelegate.inLocation = false
            self.hideLocation()
            
            UserDefaults.standard.removeObject(forKey: "LocationID")
            UserDefaults.standard.removeObject(forKey: "LocationName")
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.alertCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        delegate.present(actionSheet, animated: true, completion: nil)
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
                self.commentView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + 70)
            }
        }
    }
    
    @objc func KeyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            self.commentView.transform = .identity
        })
    }
    
    func openChat(customCell: CustomCell) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            viewController.id = customCell.string1
            viewController.close = {
                self.dismiss(animated: true)
            }
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
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
    
    func openReplies(comment: CommentStruct) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ReplyVC") as? ReplyVC {
            viewController.comment = comment
            viewController.locationID = locationID
            viewController.isMaster = isMaster
            viewController.isOwner = isOwner
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func updateUI(item: BannerStruct) {
        if item.blurred || item.title.isEmpty {
            bannerView.isHidden = true
        } else {
            bannerView.isHidden = false
            bannerLabel.text = item.title
        }
    }
    
    func wingIn(customCell: CustomCell) {
        appDelegate.inLocation = true
        inLocation = true
        noLocationView.isHidden = true
        
        locationID = customCell.string1
        
        UserDefaults.standard.set(locationID, forKey: "LocationID")
        UserDefaults.standard.set(customCell.string2, forKey: "LocationName")
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(reload), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        
        wingIn()
        reload()
    }
    
    func hideLocation() {
        inLocation = false
        noLocationView.isHidden = false
        
        if let _ = timer {
            timer.invalidate()
        }
        wingOff()
    }
    
    @objc func reload() {
        guard let _ = UserDefaults.standard.object(forKey: "Token") else {
            return
        }
        if (!inLocation) {
            return
        }
        indicator.startAnimating()
        
        if locationID.contains("Event") {
            getEvent()
        } else {
            getLocation()
            getUsers()
        }
    }
    
    func getLocation() {
        let path = "get_location.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "location_Id": locationID
        ]
        
        params.request(delegate: self, path: path, stopLoading: locationStopLoading, requestSuccess: locationSuccess)
    }
    
    func locationStopLoading() {
        indicator.stopAnimating()
    }
    
    func locationSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            isMaster = message.getBool(key: "is_master_account")
            isOwner = message.getBool(key: "is_owner")
            
            if isOwner {
                UserDefaults.standard.set(locationID, forKey: "MyLocationID")
            }
            bannerArray = []
            commentsArray = []
            
            if let banner = message["banner"] as? [NSDictionary] {
                for (index, each) in banner.enumerated() {
                    let imageView = UIImageView()
                    imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                                 collectionView: collectionView)
                    
                    let item = BannerStruct(imageView: imageView,
                                            title: each.getString(key: "title"),
                                            url: each.getString(key: "url"),
                                            blurred: each.getBool(key: "blurred"))
                    
                    if index == bannerIndex {
                        updateUI(item: item)
                    }
                    bannerArray.append(item)
                }
            }
            collectionView.reloadData()
            
            if bannerArray.isEmpty {
                let image = message.getString(key: "image")
                let imageView = UIImageView()
                imageView.imageFromServerURL(urlString: image,
                                             collectionView: collectionView)
                
                bannerArray.append(BannerStruct(imageView: imageView,
                                                title: "",
                                                url: "",
                                                blurred: false))
            }
            if bannerArray.count == 1 {
                pageControl.numberOfPages = 0
            } else {
                pageControl.numberOfPages = bannerArray.count
            }
            let image = message.getString(key: "image")
            let name = message.getString(key: "name")
            let name_city = message.getString(key: "name_city")
            let default_message = message.getString(key: "default_message")
            
            let imageView = UIImageView()
            imageView.imageFromServerURL(urlString: image,
                                         tableView: commentsTableView)
            
            myComment = CommentStruct(imageView: imageView,
                                      badgeImageView: UIImageView(),
                                      id: "",
                                      userID: "",
                                      name: name,
                                      age: "",
                                      gender: "",
                                      country: "",
                                      city: name_city,
                                      comment: default_message,
                                      likes: 0,
                                      isMyComment: false,
                                      isLiked: false,
                                      badgeTitle: "")
            
            if let comment = message["comment"] as? [NSDictionary] {
                for each in comment {
                    let imageView = UIImageView()
                    imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                                 tableView: commentsTableView)
                    
                    let badgeImageView = UIImageView()
                    badgeImageView.imageFromServerURL(urlString: each.getString(key: "badges_image"),
                                                      tableView: commentsTableView,
                                                      tint: Colors.blue)
                    
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
                                                       badgeTitle: each.getString(key: "badges_title")))
                }
            }
            commentsTableView.reloadData()
            
            locationView.isHidden = false
        }
    }
    
    func getUsers() {
        let path = "get_users.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "location_Id": locationID
        ]
        
        params.request(delegate: self, path: path, stopLoading: usersStopLoading, requestSuccess: usersSuccess)
    }
    
    func usersStopLoading() {
        indicator.stopAnimating()
    }
    
    func usersSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            usersArray = []
            
            for each in message {
                let image = each.getString(key: "image")
                let name = each.getString(key: "name")
                let is_master_account = each.getBool(key: "is_master_account")
                
                let imageView = UIImageView()
                
                if image.isEmpty {
                    imageView.image = UIImage(named: "icon_logo_profile")
                } else {
                    imageView.imageFromServerURL(urlString: image,
                                                 tableView: commentsTableView)
                }
                usersArray.append(CustomCell.init(imageView: imageView,
                                                  string1: each.getString(key: "Id"),
                                                  string2: name,
                                                  string3: each.getString(key: "details"),
                                                  string4: each.getString(key: "gender"),
                                                  string5: each.getString(key: "age"),
                                                  string6: each.getString(key: "city"),
                                                  string7: each.getString(key: "nationality"),
                                                  isMaster: is_master_account))
            }
            commentsTableView.reloadData()
        }
    }
    
    func getEvent() {
        let path = "get_event.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "event_Id": locationID.replacingOccurrences(of: "Event_", with: "")
        ]
        
        params.request(delegate: self, path: path, stopLoading: eventStopLoading, requestSuccess: eventSuccess)
    }
    
    func eventStopLoading() {
        indicator.stopAnimating()
    }
    
    func eventSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            isMaster = message.getBool(key: "is_master_account")
            isOwner = message.getBool(key: "is_owner")
            
            if isOwner {
                UserDefaults.standard.set(locationID, forKey: "MyLocationID")
            }
            bannerArray = []
            commentsArray = []
            
            let imageView1 = UIImageView()
            imageView1.imageFromServerURL(urlString: message.getString(key: "event_image"),
                                          collectionView: collectionView)
            
            let item = BannerStruct(imageView: imageView1,
                                    title: "",
                                    url: "",
                                    blurred: false)
            
            bannerArray.append(item)
            collectionView.reloadData()
            pageControl.numberOfPages = 0
            
            let image = UIImage(named: "icon_logo_profile")
            let name = message.getString(key: "title")
            let default_message = message.getString(key: "description")
            
            let imageView2 = UIImageView()
            imageView2.image = image
            
            myComment = CommentStruct(imageView: imageView2,
                                      badgeImageView: UIImageView(),
                                      id: "",
                                      userID: "",
                                      name: name,
                                      age: "",
                                      gender: "",
                                      country: "",
                                      city: "Welcome to our Event!",
                                      comment: default_message,
                                      likes: 0,
                                      isMyComment: false,
                                      isLiked: false,
                                      badgeTitle: "")
            
            if let comment = message["comments"] as? [NSDictionary] {
                for each in comment {
                    let imageView = UIImageView()
                    imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                                 tableView: commentsTableView)
                    
                    let badgeImageView = UIImageView()
                    badgeImageView.imageFromServerURL(urlString: each.getString(key: "badges_image"),
                                                      tableView: commentsTableView,
                                                      tint: Colors.blue)
                    
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
                                                       badgeTitle: each.getString(key: "badges_title")))
                }
            }
            commentsTableView.reloadData()
            
            locationView.isHidden = false
        }
    }
    
    func wingIn() {
        let path = "wing_on.php"
        
        if locationID.contains("Event") {
            return
        }
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: "")
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: wingInStopLoading, requestSuccess: wingInSuccess)
    }
    
    func wingInStopLoading() {
        
    }
    
    func wingInSuccess(jsonObject: AnyObject) {
        
    }
    
    func wingOff() {
        let path = "wing_off.php"
        
        if locationID.contains("Event") {
            return
        }
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: "")
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID
                ]
            }
        }
        
        params.request(delegate: self, path: path, stopLoading: wingOffStopLoading, requestSuccess: wingOffSuccess)
    }
    
    func wingOffStopLoading() {
        
    }
    
    func wingOffSuccess(jsonObject: AnyObject) {
        
    }
    
    func addComment() {
        let path = "add_comment.php"
        
        var params: NSDictionary {
            if locationID.contains("Event") {
                return [
                    "language": Strings.language,
                    "event_Id": locationID.replacingOccurrences(of: "Event_", with: ""),
                    "comment": commentTextField.getText()
                ]
            } else {
                return [
                    "language": Strings.language,
                    "location_Id": locationID,
                    "comment": commentTextField.getText()
                ]
            }
        }
        
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
