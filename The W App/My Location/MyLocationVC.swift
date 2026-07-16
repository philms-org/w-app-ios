
import UIKit

class MyLocationVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noLocationView: UIView!
    @IBOutlet weak var noUsersView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var array: [CustomCell] = []
    
    var delegate: MainVC!
    var timer: Timer!
    
    var id = String()
    var inLocation = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.isHidden = true
        noUsersView.isHidden = true
        
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
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationPersonCell", for: indexPath) as! LocationPersonCell
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let customCell = array[indexPath.row]
        
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let customCell = array[indexPath.row]
        
        let messageRowAction = UIContextualAction(style: .normal, title: Strings.message) {
            (_, _, _) in
            self.openChat(customCell: customCell)
        }
        return UISwipeActionsConfiguration(actions: [messageRowAction])
    }
    
    @IBAction func lexicon(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "LexiconVC") as? LexiconVC {
            present(viewController, animated: true, completion: nil)
        }
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
    
    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .down
        present(activity, animated: true, completion: nil)
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
    
    func wingIn(customCell: CustomCell) {
        inLocation = true
        titleLabel.text = "My Location"
        noLocationView.isHidden = true
        
        id = customCell.string1
        locationLabel.text = customCell.string2
        
        UserDefaults.standard.set(id, forKey: "LocationID")
        UserDefaults.standard.set(customCell.string2, forKey: "LocationName")
        
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(reload), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        
        reload()
        
//        guard isNewDate() else {
//            return
//        }
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let today = dateFormatter.string(from: Date())
//        UserDefaults.standard.setValue(today, forKey: "LastDate")
//
//        let alertTitle = "Looking for something different this time?"
//        let alertBody = "Adjust your social settings for 24hrs"
//        let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
//
//        alert.addAction(UIAlertAction(title: Strings.alertNo, style: .destructive, handler: nil))
//
//        alert.addAction(UIAlertAction(title: Strings.alertYes, style: .default, handler: {
//            _ in
//            self.openSocialSettings()
//        }))
//
//        delegate.present(alert, animated: true, completion: nil)
    }
    
    func isNewDate() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: "LastDate") as? String else {
            return true
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        if today == lastDate {
            return false
        }
        return true
    }
    
    func openSocialSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SocialSettingsVC") as? SocialSettingsVC {
            viewController.datingID = delegate.datingID
            viewController.socialisingID = delegate.socialisingID
            viewController.networkingID = delegate.networkingID
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func hideLocation() {
        inLocation = false
        titleLabel.text = "No Location"
        noLocationView.isHidden = false
        
        if let _ = timer {
            timer.invalidate()
        }
        wingOff()
    }
    
    @objc func reload() {
        guard WAPAuth.currentUserID != nil, inLocation else { return }
        indicator.stopAnimating()
    }

    func wingOff() { }
}
