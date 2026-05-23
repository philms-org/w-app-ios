
import UIKit

class MessagesVC: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var groupsTableView: UITableView!
    @IBOutlet weak var noMessagesView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let messagesRefreshControl = UIRefreshControl()
    let groupsRefreshControl = UIRefreshControl()
    
    var messagesArray: [CustomCell] = []
    var groupsArray: [CustomCell] = []
    var messagesID: [Message] = []
    
    var delegate: MainVC!
    
    var lastTag = 12
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noMessagesView.isHidden = true
        
        setKeyboard()
        
        messagesRefreshControl.tintColor = Colors.blue
        messagesRefreshControl.addTarget(self, action: #selector(refreshMessages), for: .valueChanged)
        messagesTableView.addSubview(messagesRefreshControl)
        
        groupsRefreshControl.tintColor = Colors.blue
        groupsRefreshControl.addTarget(self, action: #selector(refreshGroups), for: .valueChanged)
        groupsTableView.addSubview(groupsRefreshControl)
        
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        appDelegate.setLastMessage = {
            userID, message, date in
            self.setInbox(userID: userID, message: message, date: date, badge: false)
        }
        appDelegate.setLastGroupMessage = {
            groupID, message, date in
            self.setGroup(groupID: groupID, message: message, date: date, badge: false)
        }
        appDelegate.reloadMessages = {
            self.reloadMessages()
        }
        appDelegate.reloadGroups = {
            self.reloadGroups()
        }
        setTab(tag: 11)
        getInbox()
        getGroups()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == messagesTableView {
            return messagesArray.count
        } else {
            return groupsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == messagesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            cell.updateCell(customCell: messagesArray[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            cell.updateCell(customCell: groupsArray[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == messagesTableView {
            let customCell = messagesArray[indexPath.row]
            customCell.isSelected = false
            tableView.reloadData()
            
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
            let customCell = groupsArray[indexPath.row]
            customCell.isSelected = false
            tableView.reloadData()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "GroupChatVC") as? GroupChatVC {
                viewController.id = customCell.string1
                viewController.close = {
                    self.dismiss(animated: true)
                }
                viewController.modalPresentationStyle = .currentContext
                delegate.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tableView == messagesTableView {
            let customCell = messagesArray[indexPath.row]
            
            if customCell.isMaster {
                return nil
            }
            let deleteRowAction = UIContextualAction(style: .destructive, title: Strings.delete) {
                (_, _, _) in
                let id = customCell.string1!
                self.deleteChat(id: id)
            }
            return UISwipeActionsConfiguration(actions: [deleteRowAction])
        } else {
            return nil
        }
    }
    
    @IBAction func sort(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: "Sort by", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Recently Added (Default)", style: .default) {
            _ in
            
        })
        
        actionSheet.addAction(UIAlertAction(title: "Oldest to Recent", style: .default) {
            _ in
            
        })
        
        actionSheet.addAction(UIAlertAction(title: "Looking For", style: .default) {
            _ in
            
        })
        
        actionSheet.addAction(UIAlertAction(title: "Males First", style: .default) {
            _ in
            
        })
        
        actionSheet.addAction(UIAlertAction(title: "Females First", style: .default) {
            _ in
            
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func selectTab(_ sender: UIButton) {
        if sender.tag == lastTag {
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.setTab(tag: sender.tag)
        }
    }
    
    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .down
        present(activity, animated: true, completion: nil)
    }
    
    @objc func refreshMessages() {
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        let delay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            self.getInbox()
        })
    }
    
    @objc func refreshGroups() {
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        let delay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            self.getGroups()
        })
    }
    
    func setTab(tag: Int) {
        messagesTableView.isHidden = !(tag == 11)
        groupsTableView.isHidden = !(tag == 12)
        
        if let lastButton = view.viewWithTag(lastTag) as? UIButton, let selectedButton = view.viewWithTag(tag) as? UIButton {
            lastButton.setTitleColor(UIColor.white, for: .normal)
            selectedButton.setTitleColor(Colors.blue, for: .normal)
        }
        if let lastView = view.viewWithTag(lastTag + 5), let selectedView = view.viewWithTag(tag + 5) {
            lastView.transform = CGAffineTransform(scaleX: 0.001, y: 1)
            selectedView.transform = .identity
        }
        lastTag = tag
    }
    
    func deleteChat(id: String) {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: self, message: Strings.alertDelete, buttonTitle: Strings.delete, action: {
            self.indicator.startAnimating()
            self.delete(id: id)
        })
    }
    
    func reloadMessages() {
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        indicator.startAnimating()
        getInbox()
    }
    
    func getInbox() {
        let path = "get_inboxs.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: inboxStopLoading, requestSuccess: inboxSuccess)
    }
    
    func inboxStopLoading() {
        indicator.stopAnimating()
        messagesRefreshControl.endRefreshing()
    }
    
    func inboxSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            messagesArray = []
            
            for each in message {
                if let user = each["user"] as? NSDictionary {
                    let image = user.getString(key: "image")
                    let userID = user.getString(key: "Id")
                    let messageID = each.getString(key: "Id")
                    let message_at = each.getString(key: "message_at")
                    let is_master_account = user.getBool(key: "is_master_account")
                    
                    let imageView = UIImageView()
                    
                    if image.isEmpty {
                        imageView.image = UIImage(named: "icon_logo_profile")
                    } else {
                        imageView.imageFromServerURL(urlString: image,
                                                     tableView: messagesTableView)
                    }
                    if userID.isEmpty {
                        continue
                    }
                    messagesArray.append(CustomCell.init(imageView: imageView,
                                                         string1: userID,
                                                         string2: user.getString(key: "name"),
                                                         string3: each.getString(key: "text"),
                                                         string4: getTime(date: message_at),
                                                         string5: user.getString(key: "gender"),
                                                         string6: messageID,
                                                         string7: user.getString(key: "blocked"),
                                                         isSelected: checkBadge(userID: userID, messageID: messageID),
                                                         isMaster: is_master_account))
                }
            }
            messagesTableView.reloadData()
            
            appDelegate.setInbox = {
                userID, message, date in
                self.setInbox(userID: userID, message: message, date: date, badge: true)
            }
            noMessagesView.isHidden = !(messagesArray.isEmpty && groupsArray.isEmpty)
        }
    }
    
    func reloadGroups() {
        do {
            messagesID = try context.fetch(Message.fetchRequest())
        } catch {}
        
        indicator.startAnimating()
        getGroups()
    }
    
    func getGroups() {
        let path = "get_groups_inboxs.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: groupsStopLoading, requestSuccess: groupsSuccess)
    }
    
    func groupsStopLoading() {
        indicator.stopAnimating()
        groupsRefreshControl.endRefreshing()
    }
    
    func groupsSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            groupsArray = []
            
            for each in message {
                let image = each.getString(key: "group_image")
                let comment_Id = each.getString(key: "comment_Id")
                let messageID = each.getString(key: "message_Id")
                let message_at = each.getString(key: "insert_at")
                
                let imageView = UIImageView()
                
                if image.isEmpty {
                    imageView.image = UIImage(named: "icon_logo_profile")
                } else {
                    imageView.imageFromServerURL(urlString: image,
                                                 tableView: groupsTableView)
                }
                groupsArray.append(CustomCell.init(imageView: imageView,
                                                   string1: comment_Id,
                                                   string2: each.getString(key: "title"),
                                                   string3: each.getString(key: "text"),
                                                   string4: getTime(date: message_at),
                                                   string5: "",
                                                   string6: messageID,
                                                   string7: "",
                                                   isSelected: checkBadge(userID: comment_Id, messageID: messageID),
                                                   isMaster: each.getBool(key: "is_mute")))
            }
            groupsTableView.reloadData()
            
            appDelegate.setGroup = {
                groupID, message, date in
                self.setGroup(groupID: groupID, message: message, date: date, badge: true)
            }
            noMessagesView.isHidden = !(messagesArray.isEmpty && groupsArray.isEmpty)
        }
    }
    
    func getTime(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: date) {
            let calendar = Calendar.current
            let date1 = calendar.startOfDay(for: date)
            let date2 = calendar.startOfDay(for: Date())
            
            let components = calendar.dateComponents([.day], from: date1, to: date2)
            
            if components.day == 0 {
                let timeString: String = date.getDate(format: "hh:mm aa")
                return timeString
            } else if components.day == 1 {
                return Strings.yesterday
            } else {
                let dateString: String = date.getDate(format: "dd MMM yyyy")
                return dateString
            }
        }
        return ""
    }
    
    func checkBadge(userID: String, messageID: String) -> Bool {
        if let message = messagesID.first(where: {
            message in
            message.userID == userID
        }) {
            if message.lastMessageID == messageID {
                return false
            }
        }
        delegate.showBadge()
        return true
    }
    
    func setInbox(userID: String, message: String, date: String, badge: Bool) {
        if let index = messagesArray.firstIndex(where: {
            customCell in
            customCell.string1 == userID
        }) {
            let customCell = messagesArray.remove(at: index)
            customCell.isSelected = badge
            customCell.string3 = message
            customCell.string4 = getTime(date: date)
            messagesArray.insert(customCell, at: 0)
            messagesTableView.reloadData()
            
            if badge {
                delegate.showBadge()
            }
        } else {
            reloadMessages()
        }
    }
    
    func setGroup(groupID: String, message: String, date: String, badge: Bool) {
        if let index = groupsArray.firstIndex(where: {
            customCell in
            customCell.string1 == groupID
        }) {
            let customCell = groupsArray.remove(at: index)
            customCell.isSelected = badge
            customCell.string3 = message
            customCell.string4 = getTime(date: date)
            groupsArray.insert(customCell, at: 0)
            groupsTableView.reloadData()
            
            if badge {
                delegate.showBadge()
            }
        } else {
            reloadGroups()
        }
    }
    
    func delete(id: String) {
        let path = "delete_inbox.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "user_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: deleteStopLoading, requestSuccess: {
            jsonObject in
            self.deleteSuccess(jsonObject: jsonObject, id: id)
        })
    }
    
    func deleteStopLoading() {
        indicator.stopAnimating()
    }
    
    func deleteSuccess(jsonObject: AnyObject, id: String) {
        if let index = messagesArray.firstIndex(where: {
            customCell in
            customCell.string1 == id
        }) {
            let indexPath = IndexPath(row: index, section: 0)
            messagesArray.remove(at: index)
            messagesTableView.deleteRows(at: [indexPath], with: .right)
        }
        noMessagesView.isHidden = !messagesArray.isEmpty
    }
}
