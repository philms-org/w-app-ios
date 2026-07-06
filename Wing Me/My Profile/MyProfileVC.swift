
import UIKit

class MyProfileVC: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var profileSetupView: UIViewDesignable!
    @IBOutlet weak var editAccountView: UIViewDesignable!
    @IBOutlet weak var editLocationView: UIViewDesignable!
    @IBOutlet weak var generateUsersView: UIViewDesignable!
    @IBOutlet weak var generateUsersButton: UIButton!
    @IBOutlet weak var generateUsersIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sendMessageView: UIViewDesignable!
    @IBOutlet weak var eventsView: UIViewDesignable!
    @IBOutlet weak var badgesView: UIViewDesignable!
    @IBOutlet weak var settingsView: UIViewDesignable!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var logoutIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var nationalityLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var relationshipLabel: UILabel!
    @IBOutlet weak var drinkLabel: UILabel!
    @IBOutlet weak var fridayActivityLabel: UILabel!
    @IBOutlet weak var professionLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var generateArray: [NSDictionary] = []
    
    var delegate: MainVC!
    
    var imageURL = String()
    var name = String()
    var phone = String()
    var email = String()
    var city = String()
    var nationality = String()
    var birthDate = String()
    var agePrivacy = String()
    var gender = String()
    var height = String()
    var relationship = String()
    var drink = String()
    var activity = String()
    var profession = String()
    
    var isMaster = Bool()
    var isOwner = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        
        if let setup = UserDefaults.standard.object(forKey: "Setup") as? Bool {
            if setup {
                profileSetupView.isHidden = true
            }
        }
        request()
    }
    
    @IBAction func notification(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationVC {
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func links(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MyLinksVC") as? MyLinksVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func qrCode(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "QRCodeVC") as? QRCodeVC {
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func setupProfile(_ sender: UIButton) {
        openProfileSetup()
    }
    
    @IBAction func editProfile(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "EditProfileVC") as? EditProfileVC {
            viewController.imageURL = imageURL
            viewController.name = name
            viewController.phone = phone
            viewController.email = email
            viewController.city = city
            viewController.nationality = nationality
            viewController.birthDate = birthDate
            viewController.agePrivacy = agePrivacy
            viewController.gender = gender
            viewController.height = height
            viewController.relationship = relationship
            viewController.datingID = delegate.datingID
            viewController.socialisingID = delegate.socialisingID
            viewController.networkingID = delegate.networkingID
            viewController.drink = drink
            viewController.activity = activity
            viewController.profession = profession
            
            viewController.reloadProfile = {
                self.reload()
            }
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func editLocation(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "EditLocationVC") as? EditLocationVC {
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func generateUsers(_ sender: UIButton) {
        showActionSheet(button: sender)
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SelectUsersVC") as? SelectUsersVC {
            viewController.isMaster = isMaster
            viewController.isOwner = isOwner
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func events(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "EventsVC") as? EventsVC {
            viewController.isMaster = isMaster
            viewController.isOwner = isOwner
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func badges(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "BadgesVC") as? BadgesVC {
            viewController.isMaster = isMaster
            viewController.isOwner = isOwner
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func settings(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SettingsVC") as? SettingsVC {
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func logout(_ sender: UIButton) {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: delegate, message: Strings.alertLogout, buttonTitle: Strings.logout, action: {
            self.logoutButton.isHidden = true
            self.logoutIndicator.startAnimating()
            self.logout()
        })
    }
    
    func reload() {
        imageView.image = UIImage()
        scrollView.isHidden = true
        indicator.startAnimating()
        request()
    }
    
    func request() {
        let path = "get_info.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            imageURL = message.getString(key: "image")
            imageView.imageFromServerURL(urlString: imageURL)
            
            name = message.getString(key: "name")
            phone = message.getString(key: "phone")
            email = message.getString(key: "email")
            city = message.getString(key: "city")
            drink = message.getString(key: "drink")
            activity = message.getString(key: "activity")
            profession = message.getString(key: "profession")
            
            let split = name.split(separator: " ")
            
            if let firstName = split.first {
                UserDefaults.standard.set(firstName, forKey: "FirstName")
            }
            nameLabel.text = name
            phoneLabel.text = phone.fill()
            emailLabel.text = email.fill()
            cityLabel.text = city.fill()
            drinkLabel.text = drink.fill()
            fridayActivityLabel.text = activity.fill()
            professionLabel.text = profession.fill()
            
            isMaster = message.getBool(key: "is_master_account")
            isOwner = message.getBool(key: "is_owner")
            let add_event = message.getBool(key: "add_event")
            
            checkmarkImageView.isHidden = !isMaster
            editLocationView.isHidden = !isOwner
            generateUsersView.isHidden = !(isMaster || isOwner)
            sendMessageView.isHidden = !(isMaster || isOwner)
            eventsView.isHidden = !(isMaster || (isOwner && add_event))
            badgesView.isHidden = !(isMaster || isOwner)
            
            nationality = message.getString(key: "nationality")
            let countryName = getCountryName(countryCode: nationality)
            
            if let emoji = Constants.flags[nationality] {
                nationalityLabel.text = "\(countryName) \(emoji)"
            } else {
                nationalityLabel.text = "".fill()
            }
            
            birthDate = message.getString(key: "birth")
            ageLabel.text = getAge(date: birthDate)
            
            agePrivacy = message.getString(key: "age_privacy")
            
            gender = message.getString(key: "gender")
            genderLabel.text = getGender(gender: gender)
            
            height = message.getString(key: "height")
            
            if height.isEmpty {
                heightLabel.text = "".fill()
            } else {
                heightLabel.text = "\(height)m"
            }
            
            relationship = message.getString(key: "relationship")
            
            if let customCell = Constants.relashionships.first(where: {
                customCell in
                customCell.string1 == relationship
            }) {
                relationshipLabel.text = customCell.string2
            } else {
                relationshipLabel.text = "".fill()
            }
            
            delegate.datingID = message.getString(key: "dating_Id")
            delegate.socialisingID = message.getString(key: "socialising_Id")
            delegate.networkingID = message.getString(key: "networking_Id")

            if gender == "F" {
                editAccountView.backgroundColor = Colors.pink
                settingsView.backgroundColor = Colors.pink
            } else {
                editAccountView.backgroundColor = Colors.blue
                settingsView.backgroundColor = Colors.blue
            }
            scrollView.isHidden = false
            
            if city.isEmpty || nationality.isEmpty || height.isEmpty || drink.isEmpty || activity.isEmpty {
                setup()
            }
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
            "F": "Female",
            "O": "Other"
        ]
        if let gender = genders[gender] {
            return gender
        }
        return ""
    }
    
    func getAge(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: date) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
            return String(ageComponents.year!)
        }
        return ""
    }
    
    func logout() {
        // TODO: Task 6 — replace with Supabase sign-out
        delegate.logout()
    }
    
    func logoutError() {
        logout()
    }
    
    func logoutSuccess(jsonObject: AnyObject) {
        delegate.logout()
        
        logoutButton.isHidden = false
        logoutIndicator.stopAnimating()
    }
    
    func setup() {
        let delay = DispatchTime.now() + 30
        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            self.showSetupAlert()
        })
    }
    
    func showSetupAlert() {
        if let _ = UserDefaults.standard.object(forKey: "Setup") {
            return
        }
        let alert = UIAlertController(title: Strings.alertSetup, message: Strings.alertSetupProfile, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.alertSetupNow, style: .default, handler: {
            _ in
            self.openProfileSetup()
        }))
        alert.addAction(UIAlertAction(title: Strings.alertLater, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: Strings.alertNever, style: .destructive, handler: {
            _ in
            UserDefaults.standard.set(false, forKey: "Setup")
        }))
        delegate.present(alert, animated: true, completion: nil)
    }
    
    func openProfileSetup() {
        let locale = Locale.current
        let regionCode = locale.regionCode ?? ""
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SecondSetupVC") as? SecondSetupVC {
            viewController.regionCode = regionCode
            viewController.city = city
            viewController.nationality = nationality
            viewController.height = height
            viewController.relationship = relationship
            viewController.datingID = delegate.datingID
            viewController.socialisingID = delegate.socialisingID
            viewController.networkingID = delegate.networkingID
            viewController.drink = drink
            viewController.activity = activity
            viewController.profession = profession
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
}
