
import UIKit

class UserProfileVC: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var sendView: UIViewDesignable!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var cityView: UIView!
    @IBOutlet weak var cityLabel: UILabel!
    
    @IBOutlet weak var nationalityView: UIView!
    @IBOutlet weak var nationalityLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    
    @IBOutlet weak var heightView: UIView!
    @IBOutlet weak var heightLabel: UILabel!
    
    @IBOutlet weak var relationshipView: UIView!
    @IBOutlet weak var relationshipLabel: UILabel!
    
    @IBOutlet weak var drinkView: UIView!
    @IBOutlet weak var drinkLabel: UILabel!
    
    @IBOutlet weak var fridayActivityView: UIView!
    @IBOutlet weak var fridayActivityLabel: UILabel!
    
    @IBOutlet weak var professionView: UIView!
    @IBOutlet weak var professionLabel: UILabel!
    
    var close: (() -> ())?
    
    var id = String()
    var fromChat = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        request()
    }
    
    @IBAction func back(_ sender: UIButton) {
        if let reloadMessages = appDelegate.reloadMessages {
            reloadMessages()
        }
        dismiss(animated: true)
    }
    
    @IBAction func menu(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: Strings.block, style: .destructive) {
            _ in
            self.blockUser()
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.report, style: .destructive) {
            _ in
            self.reportUser()
        })
        
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
    
    @IBAction func sendMessage(_ sender: UIButton) {
        if fromChat {
            dismiss(animated: true)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            viewController.id = id
            viewController.close = close
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
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
    
    func request() {
        let path = "get_user_info.php"
        
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
            let image = message.getString(key: "image")
            
            if image.isEmpty {
                imageView.image = UIImage(named: "icon_logo_profile")
            } else {
                imageView.imageFromServerURL(urlString: image)
            }
            let name = message.getString(key: "name")
            let is_master_account = message.getBool(key: "is_master_account")
            let city = message.getString(key: "city")
            let age = message.getString(key: "age")
            let drink = message.getString(key: "drink")
            let activity = message.getString(key: "activity")
            let profession = message.getString(key: "profession")
            
            nameLabel.text = name
            ageLabel.text = age
            
            checkmarkImageView.isHidden = !is_master_account
            
            if city.isEmpty {
                cityView.isHidden = true
            } else {
                cityView.isHidden = false
                cityLabel.text = city
            }
            
            if drink.isEmpty {
                drinkView.isHidden = true
            } else {
                drinkView.isHidden = false
                drinkLabel.text = drink
            }
            
            if activity.isEmpty {
                fridayActivityView.isHidden = true
            } else {
                fridayActivityView.isHidden = false
                fridayActivityLabel.text = activity
            }
            
            if profession.isEmpty {
                professionView.isHidden = true
            } else {
                professionView.isHidden = false
                professionLabel.text = profession
            }
            
            let nationality = message.getString(key: "nationality")
            let countryName = getCountryName(countryCode: nationality)
            
            if let emoji = Constants.flags[nationality] {
                nationalityView.isHidden = false
                nationalityLabel.text = "\(countryName) \(emoji)"
            } else {
                nationalityView.isHidden = true
            }
            
            let gender = message.getString(key: "gender")
            genderLabel.text = getGender(gender: gender)
            
            let height = message.getString(key: "height")
            
            if height.isEmpty {
                heightView.isHidden = true
            } else {
                heightView.isHidden = false
                heightLabel.text = "\(height)m"
            }
            
            let relationship = message.getString(key: "relationship")
            
            if let customCell = Constants.relashionships.first(where: {
                customCell in
                customCell.string1 == relationship
            }) {
                relationshipView.isHidden = false
                relationshipLabel.text = customCell.string2
            } else {
                relationshipView.isHidden = true
            }
            
            if gender == "F" {
                sendView.backgroundColor = Colors.pink
            } else {
                sendView.backgroundColor = Colors.blue
            }
            scrollView.isHidden = false
        }
    }
    
    func getCountryName(countryCode: String) -> String {
        let current = Locale(identifier: "en_US")
        if let name = current.localizedString(forRegionCode: countryCode) {
            return name
        }
        return ""
    }
    
    func getGender(gender: String) -> String {
        let genders = [
            "M": "Male",
            "F": "Female"
        ]
        if let gender = genders[gender] {
            return gender
        }
        return "Other"
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
