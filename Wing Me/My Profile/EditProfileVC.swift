
import UIKit

class EditProfileVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var agePrivateSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!
    
    var reloadProfile: (() -> ())!
    
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
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    var drink = String()
    var activity = String()
    var profession = String()
    
    var lastGender = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        updateUI()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addPicture(_ sender: UIButton) {
        showPicker(button: sender)
    }
    
    @IBAction func selectGender(_ sender: UIButton) {
        view.endEditing(true)
        
        if (sender.tag == lastGender) {
            return
        }
        selectGender(tag: sender.tag)
    }
    
    @IBAction func selectBithDate(_ sender: Any) {
        view.endEditing(true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "DatePickerVC") as? DatePickerVC {
            viewController.selectDate = {
                date in
                self.selectDate(date: date)
            }
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func save(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !nameTextField.getText().isEmpty && !emailTextField.getText().isEmpty && lastGender != 0 && !birthDate.isEmpty else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        sendData()
    }
    
    @IBAction func setupProfile(_ sender: UIButton) {
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? ""
        
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
    
    @IBAction func deleteAccount(_ sender: UIButton) {
        if let encodedURL = (Constants.deleteAccountURL).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    
    func selectGender(tag: Int) {
        if let lastView = view.viewWithTag(lastGender + 5), let lastButton = view.viewWithTag(lastGender) as? UIButton {
            lastView.layer.borderWidth = 0
            lastView.backgroundColor = Colors.back_gray
            lastButton.setTitleColor(Colors.dark_gray, for: .normal)
        }
        if let selectedView = view.viewWithTag(tag + 5), let button = view.viewWithTag(tag) as? UIButton {
            selectedView.layer.borderWidth = 1
            selectedView.backgroundColor = Colors.black
            button.setTitleColor(UIColor.white, for: .normal)
        }
        lastGender = tag
    }
    
    func selectDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        birthDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "dd MMMM yyyy"
        let dateString = dateFormatter.string(from: date)
        dateButton.setTitle(dateString, for: .normal)
        dateButton.setTitleColor(UIColor.black, for: .normal)
    }
    
    func updateUI() {
        imageView.imageFromServerURL(urlString: imageURL)
        nameTextField.text = name
        phoneTextField.text = phone
        emailTextField.text = email
        
        let genderTag = getGenderTag(gender: gender)
        selectGender(tag: genderTag)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: birthDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            dateButton.setTitle(dateString, for: .normal)
            dateButton.setTitleColor(UIColor.black, for: .normal)
        }
        if agePrivacy == "private" {
            agePrivateSwitch.setOn(true, animated: false)
        } else {
            agePrivateSwitch.setOn(false, animated: false)
        }
    }
    
    func getGenderTag(gender: String) -> Int {
        let genders = [
            "M": 11,
            "F": 12,
            "O": 13
        ]
        if let gender = genders[gender] {
            return gender
        }
        return 0
    }
}
