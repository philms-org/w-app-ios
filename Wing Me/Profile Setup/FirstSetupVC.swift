
import UIKit

class FirstSetupVC: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var pageLabel: UILabel!
    
    var regionCode = String()
    var city = String()
    var nationality = String()
    var height = String()
    var relationship = String()
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    var drink = String()
    var activity = String()
    var profession = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageLabel.text = "1/5"
        
        if height.isEmpty {
            heightLabel.text = "---"
        } else {
            heightLabel.text = "\(height)m"
            
            if let height = Float(height) {
                slider.value = height
            }
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        let alert = UIAlertController(title: Strings.alertWarning, message: Strings.alertSaveProfile, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: Strings.saveChanges, style: .default, handler: {
            _ in
            self.backButton.isHidden = true
            self.indicator.startAnimating()
            self.save()
        }))
        
        alert.addAction(UIAlertAction(title: Strings.discardChanges, style: .destructive, handler: {
            _ in
            self.openMain()
        }))
        
        alert.addAction(UIAlertAction(title: Strings.alertCancel, style: .cancel))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func slide(_ sender: UISlider) {
        let value = Double(sender.value)
        let rounded = Double(round(100 * value) / 100)
        self.height = String(rounded)
        heightLabel.text = "\(rounded)m"
    }
    
    @IBAction func previous(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func next(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SecondSetupVC") as? SecondSetupVC {
            viewController.regionCode = regionCode
            viewController.city = city
            viewController.nationality = nationality
            viewController.height = height
            viewController.relationship = relationship
            viewController.datingID = datingID
            viewController.socialisingID = socialisingID
            viewController.networkingID = networkingID
            viewController.drink = drink
            viewController.activity = activity
            viewController.profession = profession
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func save() {
        let path = "set_up_profile.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "height": height,
            "relationship": relationship,
            "dating_Id": datingID,
            "socialising_Id": socialisingID,
            "networking_Id": networkingID,
            "nationality": nationality,
            "city": city,
            "drink": drink,
            "activity": activity,
            "profession": profession
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        backButton.isHidden = false
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        openMain()
    }
    
    func openMain() {
        appDelegate.inLocation = false
        UserDefaults.standard.set(true, forKey: "Setup")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
