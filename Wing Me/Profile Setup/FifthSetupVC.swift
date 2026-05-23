
import UIKit

class FifthSetupVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var drinkTextField: UITextField!
    @IBOutlet weak var fridayTextField: UITextField!
    @IBOutlet weak var professionTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!
    
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
        setKeyboard()
        
        cityTextField.text = city
        drinkTextField.text = drink
        fridayTextField.text = activity
        professionTextField.text = profession
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func save(_ sender: UIButton) {
        view.endEditing(true)
        
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        send()
    }
    
    func send() {
        let path = "set_up_profile.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "height": height,
            "relationship": relationship,
            "dating_Id": datingID,
            "socialising_Id": socialisingID,
            "networking_Id": networkingID,
            "nationality": nationality,
            "city": cityTextField.getText(),
            "drink": drinkTextField.getText(),
            "activity": fridayTextField.getText(),
            "profession": professionTextField.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        saveButton.isHidden = false
        saveIndicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        appDelegate.inLocation = false
        UserDefaults.standard.set(true, forKey: "Setup")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
