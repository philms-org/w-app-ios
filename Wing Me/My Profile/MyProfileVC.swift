
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
        guard let uid = WAPAuth.currentUserID else {
            indicator.stopAnimating()
            return
        }
        Task { @MainActor in
            do {
                let profile = try await WAPData.shared.fetchProfile(id: uid)
                displayProfile(profile)
            } catch {
                indicator.stopAnimating()
                AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
            }
        }
    }

    private func displayProfile(_ profile: WAPProfile) {
        nameLabel.text = profile.displayName
        professionLabel.text = profile.profession ?? ""
        cityLabel.text = profile.city ?? ""
        drinkLabel.text = profile.faveDrink ?? ""
        fridayActivityLabel.text = profile.fridayNight ?? ""

        if let url = profile.avatarURL, !url.isEmpty {
            imageView.imageFromServerURL(urlString: url)
        }

        checkmarkImageView.isHidden = !(profile.isVerified ?? false)

        // Hide dating-era fields that have no WAP equivalent
        phoneLabel.isHidden = true
        emailLabel.isHidden = true
        nationalityLabel.isHidden = true
        ageLabel.isHidden = true
        genderLabel.isHidden = true
        heightLabel.isHidden = true
        relationshipLabel.isHidden = true

        // Hide owner/master controls (not wired to WAPProfile yet)
        editLocationView.isHidden = true
        generateUsersView.isHidden = true
        sendMessageView.isHidden = true
        eventsView.isHidden = true
        badgesView.isHidden = true

        indicator.stopAnimating()
        scrollView.isHidden = false
    }
    
    
    func logout() {
        Task { @MainActor in
            await WAPAuth.signOut()
            delegate.logout()
            logoutButton.isHidden = false
            logoutIndicator.stopAnimating()
        }
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
        let regionCode = locale.region?.identifier ?? ""

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SecondSetupVC") as? SecondSetupVC {
            viewController.regionCode = regionCode
            viewController.city = city
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
