
import UIKit

class GroupChatVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
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
    
    var array: [CustomCell] = []
    var messagesID: [Message] = []
    
    var close: (() -> ())?
    
    var id = String()
    var titleString = String()
    var isAdmin = Bool()
    var isMute = Bool()
    
    var keyboardHeight = CGFloat()
    var lastDate = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        appDelegate.groupID = id
        messageView.isHidden = true
        
        nameLabel.text = ""
        
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        appDelegate.reloadGroup = {
            self.reload()
        }
        request()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.getText().isEmpty {
            messageLabel.alpha = 1
            messageLabel.text = "Wing away..."
        } else {
            messageLabel.alpha = 0
            messageLabel.text = textView.getText()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return array.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let type = array[indexPath.row].string1
            
            if type == "date" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatDateCell", for: indexPath) as! ChatDateCell
                cell.updateCell(customCell: array[indexPath.row])
                return cell
            } else if type == "sender" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRightCell", for: indexPath) as! ChatRightCell
                cell.updateCell(customCell: array[indexPath.row])
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChatCell", for: indexPath) as! GroupChatCell
                cell.updateCell(customCell: array[indexPath.row])
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatEmptyCell", for: indexPath) as! ChatEmptyCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            return keyboardHeight + 2
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 else {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        let type = array[indexPath.row].string1
        
        if type == "date" {
            return
        }
        var message: String {
            if type == "sender" {
                return array[indexPath.row].string2
            } else {
                return array[indexPath.row].string3
            }
        }
        
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Copy", style: .default) {
            _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = message
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: UIButton) {
        appDelegate.setGroupChatMessage = nil
        appDelegate.reloadChat = nil
        dismiss(animated: true)
    }
    
    @IBAction func menu(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        if isAdmin {
            actionSheet.addAction(UIAlertAction(title: "Edit Group", style: .default) {
                _ in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let viewController = storyboard.instantiateViewController(withIdentifier: "EditGroupVC") as? EditGroupVC {
                    viewController.groupID = self.id
                    viewController.titleString = self.titleString
                    viewController.modalPresentationStyle = .currentContext
                    self.present(viewController, animated: true, completion: nil)
                }
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "Group Members", style: .default) {
            _ in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "GroupMembersVC") as? GroupMembersVC {
                viewController.groupID = self.id
                viewController.isAdmin = self.isAdmin
                viewController.modalPresentationStyle = .currentContext
                self.present(viewController, animated: true, completion: nil)
            }
        })
        
        if isMute {
            actionSheet.addAction(UIAlertAction(title: "Unmute Group", style: .default) {
                _ in
                self.indicator.startAnimating()
                self.muteGroup(mute: false)
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: "Mute Group", style: .default) {
                _ in
                self.indicator.startAnimating()
                self.muteGroup(mute: true)
            })
        }
        
        if isAdmin {
            actionSheet.addAction(UIAlertAction(title: "Delete Group", style: .destructive) {
                _ in
                self.showDeleteAlert()
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: "Leave Group", style: .destructive) {
                _ in
                self.showLeaveAlert()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func viewImage(_ sender: UIButton) {
        guard let image = imageView.image else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "FullImageVC") as? FullImageVC {
            viewController.image = image
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func send(_ sender: UIButton) {
        if messageTextView.getText().isEmpty {
            return
        }
        sendButton.isHidden = true
        sendIndicator.startAnimating()
        send()
    }
    
    @objc func KeyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            
            if view.safeAreaInsets.bottom > 0 {
                keyboardHeight = keyboardRectangle.height - view.safeAreaInsets.bottom
            } else {
                keyboardHeight = keyboardRectangle.height
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.stackView.transform = CGAffineTransform(translationX: 0, y: -self.keyboardHeight)
            })
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: true)
        }
    }
    
    @objc func KeyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            self.stackView.transform = .identity
        })
        keyboardHeight = 0
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func showDeleteAlert() {
        AlertClass().showWarningAlert(delegate: self, message: Strings.alertDeleteGroup, buttonTitle: "Delete") {
            self.indicator.startAnimating()
            self.deleteGroup()
        }
    }
    
    func showLeaveAlert() {
        AlertClass().showWarningAlert(delegate: self, message: Strings.alertLeaveGroup, buttonTitle: "Leave") {
            self.indicator.startAnimating()
            self.leaveGroup()
        }
    }
    
    func reload() {
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        array = []
        lastDate = ""
        
        tableView.reloadData()
        indicator.startAnimating()
        request()
    }
    
    func request() {
        let path = "get_group_inbox.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            let group_image = message.getString(key: "group_image")
            titleString = message.getString(key: "title")
            isAdmin = message.getBool(key: "is_admin")
            isMute = message.getBool(key: "is_mute")
            
            imageView.imageFromServerURL(urlString: group_image)
            nameLabel.text = titleString
            
            if let messages = message["messages"] as? [NSDictionary] {
                for (index, each) in messages.enumerated() {
                    if let user = each["user"] as? NSDictionary {
                        let message_Id = each.getString(key: "message_Id")
                        let type = each.getString(key: "message_type")
                        let name = user.getString(key: "name")
                        let gender = user.getString(key: "gender")
                        let text = each.getString(key: "text")
                        let date = each.getString(key: "insert_at")
                        
                        setMessage(type: type, userName: name, message: text, date: date, gender: gender)
                        
                        if index == messages.count - 1 {
                            saveLastMessage(messageID: message_Id)
                        }
                    }
                }
                appDelegate.setGroupChatMessage = {
                    messageID, userName, gender, message, date in
                    self.receiveMessage(messageID: messageID, userName: userName, gender: gender, message: message, date: date)
                }
                tableView.reloadData()
                tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: false)
            }
            messageView.isHidden = false
        }
    }
    
    func receiveMessage(messageID: String, userName: String, gender: String, message: String, date: String) {
        setMessage(type: "receiver", userName: userName, message: message, date: date, gender: gender)
        saveLastMessage(messageID: messageID)
        
        if let setLastMessage = appDelegate.setLastGroupMessage {
            setLastMessage(id, message, date)
        }
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: true)
    }
    
    func setMessage(type: String, userName: String, message: String, date: String, gender: String) {
        let dateString: String = date.getDate(format: "dd MMM yyyy")
        let timeString: String = date.getDate(format: "hh:mm aa")
        
        let date: Date = date.getDate(format: "dd MMM yyyy")
        
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: date)
        let date2 = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        
        if dateString != lastDate {
            if components.day == 0 {
                array.append(CustomCell.init(string1: "date",
                                             string2: Strings.today))
            } else if components.day == 1 {
                array.append(CustomCell.init(string1: "date",
                                             string2: Strings.yesterday))
            } else {
                array.append(CustomCell.init(string1: "date",
                                             string2: dateString))
            }
            lastDate = dateString
        }
        if type == "sender" {
            array.append(CustomCell.init(string1: type,
                                         string2: message,
                                         string3: timeString))
        } else {
            array.append(CustomCell.init(string1: type,
                                         string2: userName,
                                         string3: message,
                                         string4: timeString,
                                         string5: gender))
        }
    }
    
    func send() {
        let path = "send_group_inbox.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": id,
            "text": messageTextView.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: sendStopLoading, requestSuccess: sendSuccess)
    }
    
    func sendStopLoading() {
        sendButton.isHidden = false
        sendIndicator.stopAnimating()
    }
    
    func sendSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            let date = message.getString(key: "date")
            let message_Id = message.getString(key: "message_Id")
            setMessage(type: "sender", userName: "", message: messageTextView.getText(), date: date, gender: "")
            saveLastMessage(messageID: message_Id)
            
            if let setLastMessage = appDelegate.setLastGroupMessage {
                setLastMessage(id, messageTextView.getText(), date)
            }
            messageTextView.text = ""
            messageLabel.alpha = 1
            messageLabel.text = "Wing away..."
            
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: true)
        }
    }
    
    func saveLastMessage(messageID: String) {
        if let message = messagesID.first(where: {
            message in
            message.userID == id
        }) {
            message.lastMessageID = messageID
        } else {
            let message = Message(context: context)
            message.userID = id
            message.lastMessageID = messageID
        }
        appDelegate.saveContext()
    }
    
    func deleteGroup() {
        let path = "delete_group.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: deleteStopLoading, requestSuccess: deleteSuccess)
    }
    
    func deleteStopLoading() {
        indicator.stopAnimating()
    }
    
    func deleteSuccess(jsonObject: AnyObject) {
        appDelegate.reloadGroups?()
        dismiss(animated: true)
    }
    
    func leaveGroup() {
        let path = "leave_group.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: leaveStopLoading, requestSuccess: leaveSuccess)
    }
    
    func leaveStopLoading() {
        indicator.stopAnimating()
    }
    
    func leaveSuccess(jsonObject: AnyObject) {
        appDelegate.reloadGroups?()
        dismiss(animated: true)
    }
    
    func muteGroup(mute: Bool) {
        let path = "mute_group.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": id,
            "mute": mute
        ]
        
        params.request(delegate: self, path: path, stopLoading: muteStopLoading, requestSuccess: {
            jsonObject in
            self.muteSuccess(jsonObject: jsonObject, mute: mute)
        })
    }
    
    func muteStopLoading() {
        indicator.stopAnimating()
    }
    
    func muteSuccess(jsonObject: AnyObject, mute: Bool) {
        appDelegate.reloadGroups?()
        isMute = mute
    }
}
