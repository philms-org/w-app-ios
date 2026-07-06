
import UIKit

class ChatVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
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
    
    var array: [CustomCell] = []
    var messagesID: [Message] = []
    
    var close: (() -> ())?
    
    var id = String()
    var gender = String()
    var blocked = String()
    
    var keyboardHeight = CGFloat()
    var lastDate = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard(tableView: tableView)
        appDelegate.userID = id
        checkmarkImageView.isHidden = true
        messageView.isHidden = true
        acceptView.isHidden = true
        
        nameLabel.text = ""
        detailsLabel.text = ""
        
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        appDelegate.reloadChat = {
            self.reload()
        }
        if id == "0" {
            menuButton.isHidden = true
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
            } else if type == "send" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRightCell", for: indexPath) as! ChatRightCell
                cell.updateCell(customCell: array[indexPath.row])
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatLeftCell", for: indexPath) as! ChatLeftCell
                cell.updateCell(customCell: array[indexPath.row], gender: gender)
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
        let message = array[indexPath.row].string2
        
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
        appDelegate.setChatMessage = nil
        appDelegate.reloadChat = nil
        dismiss(animated: true)
    }
    
    @IBAction func menu(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        if blocked == "1" {
            actionSheet.addAction(UIAlertAction(title: Strings.unblock, style: .destructive) {
                _ in
                self.unblockUser()
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: Strings.viewProfile, style: .default) {
                _ in
                self.openProfile()
            })
            
            actionSheet.addAction(UIAlertAction(title: Strings.block, style: .destructive) {
                _ in
                self.blockUser()
            })
            
            actionSheet.addAction(UIAlertAction(title: Strings.report, style: .destructive) {
                _ in
                self.reportUser()
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
        
        if id == "0" {
            sendMaster()
        } else {
            send()
        }
    }
    
    @IBAction func accept(_ sender: UIButton) {
        acceptButton.isHidden = true
        acceptIndicator.startAnimating()
        accept()
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
    
    func openProfile() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as? UserProfileVC {
            viewController.id = id
            viewController.fromChat = true
            viewController.close = close
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func unblockUser() {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: self, message: Strings.alertUnblock, buttonTitle: Strings.unblock, action: {
            self.indicator.startAnimating()
            self.block()
        })
    }
    
    func blockUser() {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: self, message: Strings.alertBlock, buttonTitle: Strings.block, action: {
            self.indicator.startAnimating()
            self.block()
        })
    }
    
    func reportUser() {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: self, message: Strings.alertReport, buttonTitle: Strings.report, action: {
            self.indicator.startAnimating()
            self.report()
        })
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
        let path = "get_inbox.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "user_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            if let users = message["users"] as? NSDictionary {
                let image = users.getString(key: "image")
                let name = users.getString(key: "name")
                let is_master_account = users.getBool(key: "is_master_account")
                let is_accept_reject = message.getBool(key: "is_accept_reject")

                let nationality = users.getString(key: "nationality")
                let city = users.getString(key: "city")
                let age = users.getString(key: "age")
                
                gender = users.getString(key: "gender")
                
                if id == "0" {
                    imageView.image = UIImage(named: "icon_logo_profile")
                    genderView.layer.shadowColor = Colors.blue.cgColor
                    detailsLabel.text = ""
                } else {
                    imageView.imageFromServerURL(urlString: image)
                    
                    if gender == "F" {
                        genderView.layer.shadowColor = Colors.pink.cgColor
                    } else {
                        genderView.layer.shadowColor = Colors.blue.cgColor
                    }
                    if age.isEmpty {
                        if city.isEmpty {
                            if let emoji = Constants.flags[nationality] {
                                detailsLabel.text = "\(emoji)"
                            } else {
                                detailsLabel.isHidden = true
                            }
                        } else {
                            if let emoji = Constants.flags[nationality] {
                                detailsLabel.text = "\(city) \(emoji)"
                            } else {
                                detailsLabel.text = "\(city)"
                            }
                        }
                    } else {
                        if city.isEmpty {
                            if let emoji = Constants.flags[nationality] {
                                detailsLabel.text = "Age: \(age) \(emoji)"
                            } else {
                                detailsLabel.text = "Age: \(age)"
                            }
                        } else {
                            if let emoji = Constants.flags[nationality] {
                                detailsLabel.text = "Age: \(age), \(city) \(emoji)"
                            } else {
                                detailsLabel.text = "Age: \(age), \(city)"
                            }
                        }
                    }
                }
                nameLabel.text = name

                checkmarkImageView.isHidden = !is_master_account
                
                if is_accept_reject {
                    messageView.isHidden = false
                } else {
                    acceptView.isHidden = false
                }
                blocked = users.getString(key: "blocked")
                
                if blocked == "1" {
                    textFieldView.isHidden = true
                }
            }
            if let inbox = message["inbox"] as? [NSDictionary] {
                for (index, each) in inbox.enumerated() {
                    let message_Id = each.getString(key: "message_Id")
                    let type = each.getString(key: "type")
                    let text = each.getString(key: "text")
                    let date = each.getString(key: "insert_at")
                    
                    if index == 0 && type == "send" {
                        messageView.isHidden = false
                        acceptView.isHidden = true
                    }
                    setMessage(type: type, message: text, date: date)
                    
                    if index == inbox.count - 1 {
                        saveLastMessage(messageID: message_Id)
                    }
                }
                appDelegate.setChatMessage = {
                    messageID, message, date in
                    self.receiveMessage(messageID: messageID, message: message, date: date)
                }
                tableView.reloadData()
                tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: false)
            }
            if array.isEmpty {
                messageView.isHidden = false
                acceptView.isHidden = true
            }
        }
    }
    
    func receiveMessage(messageID: String, message: String, date: String) {
        setMessage(type: "receive", message: message, date: date)
        saveLastMessage(messageID: messageID)
        
        if let setLastMessage = appDelegate.setLastMessage {
            setLastMessage(id, message, date)
        }
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .bottom, animated: true)
    }
    
    func setMessage(type: String, message: String, date: String) {
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
        array.append(CustomCell.init(string1: type,
                                     string2: message,
                                     string3: timeString))
    }
    
    func send() {
        let path = "send_inbox.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "receiver_Id": id,
            "text": messageTextView.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: sendStopLoading, requestSuccess: sendSuccess)
    }
    
    func sendMaster() {
        let path = "send_inbox_master.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
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
            setMessage(type: "send", message: messageTextView.getText(), date: date)
            saveLastMessage(messageID: message_Id)
            
            if let setLastMessage = appDelegate.setLastMessage {
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
    
    func accept() {
        let path = "accept_inbox.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "user_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: acceptStopLoading, requestSuccess: acceptSuccess)
    }
    
    func acceptStopLoading() {
        acceptButton.isHidden = false
        acceptIndicator.stopAnimating()
    }
    
    func acceptSuccess(jsonObject: AnyObject) {
        if let error = jsonObject["error"] as? String {
            if error == "0" {
                messageView.isHidden = false
                acceptView.isHidden = true
            } else {
                if let reloadMessages = appDelegate.reloadMessages {
                    reloadMessages()
                }
                if let dictionary = jsonObject as? NSDictionary {
                    let alertClass = AlertClass()
                    alertClass.showErrorAlert(delegate: self, message: dictionary.getString(key: "message"), action: {
                        self.dismiss(animated: true)
                    })
                }
            }
        }
    }
    
    func block() {
        let path = "block_user.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "user_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: blockStopLoading, requestSuccess: blockSuccess)
    }
    
    func blockStopLoading() {
        indicator.stopAnimating()
    }
    
    func blockSuccess(jsonObject: AnyObject) {
        if let reloadLocation = appDelegate.reloadLocation, let reloadMessages = appDelegate.reloadMessages {
            reloadLocation()
            reloadMessages()
        }
        if let close = close {
            close()
        } else {
            dismiss(animated: true)
        }
    }
    
    func report() {
        let path = "report_user.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "user_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: reportStopLoading, requestSuccess: reportSuccess)
    }
    
    func reportStopLoading() {
        indicator.stopAnimating()
    }
    
    func reportSuccess(jsonObject: AnyObject) {
        let alertClass = AlertClass()
        alertClass.showSuccessAlert(delegate: self, message: Strings.alertReported, action: {
            self.dismiss(animated: true)
        })
    }
}
