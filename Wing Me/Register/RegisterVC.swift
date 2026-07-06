
import UIKit
import FBSDKLoginKit
import AuthenticationServices

class RegisterVC: UIViewController, UITextFieldDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var codeButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var termsSwitch: UISwitch!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var registerIndicator: UIActivityIndicatorView!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var facebookIndicator: UIActivityIndicatorView!
    
    var codesArray: [CustomCell] = []
    
    var code = "1"
    var lastGender = Int()
    var birthDate = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        
        for (key, value) in Constants.countryCodes {
            codesArray.append(CustomCell.init(string1: value, string2: key))
        }
        codesArray = codesArray.sorted {
            (customCell1, customCell2) in
            return customCell1.string2 < customCell2.string2
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let appleId = appleIDCredential.user
            
            if let dictionary = UserDefaults.standard.object(forKey: appleId) as? NSDictionary {
                if let name = dictionary["Name"] as? String, let email = dictionary["Email"] as? String {
                    openRegister(id: appleId, name: name, email: email, imageURL: "")
                    return
                }
            }
            guard let fullName = appleIDCredential.fullName else {
                openRegister(id: appleId, name: "", email: "", imageURL: "")
                return
            }
            guard let firstName = fullName.givenName, let lastName = fullName.familyName else {
                openRegister(id: appleId, name: "", email: "", imageURL: "")
                return
            }
            guard let email = appleIDCredential.email else {
                let name = "\(firstName) \(lastName)"
                openRegister(id: appleId, name: name, email: "", imageURL: "")
                return
            }
            let name = "\(firstName) \(lastName)"
            let dictionary: NSDictionary = [
                "Name": name,
                "Email": email
            ]
            
            UserDefaults.standard.set(dictionary, forKey: appleId)
            openRegister(id: appleId, name: name, email: email, imageURL: "")
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addPicture(_ sender: UIButton) {
        showPicker(button: sender)
    }
    
    @IBAction func countryCode(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "PickerVC") as? PickerVC {
            viewController.array = codesArray
            viewController.selectItem = selectCode
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func selectGender(_ sender: UIButton) {
        view.endEditing(true)
        
        if (sender.tag == lastGender) {
            return
        }
        if let lastView = view.viewWithTag(lastGender + 5), let lastButton = view.viewWithTag(lastGender) as? UIButton {
            lastView.layer.borderWidth = 0
            lastView.backgroundColor = Colors.back_gray
            lastButton.setTitleColor(Colors.dark_gray, for: .normal)
        }
        if let selectedView = view.viewWithTag(sender.tag + 5) {
            selectedView.layer.borderWidth = 1
            selectedView.backgroundColor = Colors.black
            sender.setTitleColor(UIColor.white, for: .normal)
        }
        lastGender = sender.tag
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
    
    @IBAction func terms(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "AboutVC") as? AboutVC {
            viewController.titleString = Strings.terms
            viewController.path = "terms.php"
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !nameTextField.getText().isEmpty && !emailTextField.getText().isEmpty && !phoneTextField.getPhone().isEmpty
                && !passwordTextField.getText().isEmpty && !confirmTextField.getText().isEmpty && lastGender != 0
                && !birthDate.isEmpty, let image = imageView.image, let _ = image.pngData() else {
            
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        guard passwordTextField.getText() == confirmTextField.getText() else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertBoth)
            return
        }
        guard termsSwitch.isOn else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertTerms)
            return
        }
        registerButton.isHidden = true
        registerIndicator.startAnimating()
        sendData()
    }
    
    @IBAction func facebookRegister(_ sender: UIButton) {
        facebookButton.isHidden = true
        facebookIndicator.startAnimating()
        facebookRegister()
    }
    
    @IBAction func appleRegister(_ sender: UIButton) {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    func selectCode(customCell: CustomCell) {
        code = customCell.string1
        codeButton.setTitle("+\(customCell.string1!)", for: .normal)
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
    
    func facebookRegister() {
        let loginManager = LoginManager()
        
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) {
            (result, error) in
            
            if let _ = error {
                self.facebookStopLoading()
                self.facebookError()
                return
            }
            if let result = result {
                if let token = result.token {
                    self.request(token: token.tokenString)
                    return
                }
            }
            self.facebookStopLoading()
        }
    }
    
    func request(token: String) {
        let request = GraphRequest(graphPath: "me", parameters: ["fields": "id, name, email, gender, birthday, picture.width(1080).height(1080)"], tokenString: token, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))
        
        request.start(completion: {
            (connection, result, error) in
            self.facebookStopLoading()
            
            guard let result = result, error == nil else {
                self.facebookError()
                return
            }
            if let result = result as? NSDictionary {
                print(result)
                self.facebookSuccess(result: result)
            }
        })
    }
    
    func facebookError() {
        let alertClass = AlertClass()
        alertClass.showErrorAlert(delegate: self, message: Strings.alertConnection)
    }
    
    func facebookStopLoading() {
        facebookButton.isHidden = false
        facebookIndicator.stopAnimating()
    }
    
    func facebookSuccess(result: NSDictionary) {
        let facebookID  = result.getString(key: "id")
        let name = result.getString(key: "name")
        let email = result.getString(key: "email")
        
        var imageURL: String {
            if let picture = result["picture"] as? NSDictionary, let data = picture["data"] as? NSDictionary {
                let url = data.getString(key: "url")
                return url
            }
            return ""
        }
        openRegister(id: facebookID, name: name, email: email, imageURL: imageURL)
    }
    
    func openRegister(id: String, name: String, email: String, imageURL: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "FcbRegisterVC") as? FcbRegisterVC {
            viewController.id = id
            viewController.name = name
            viewController.email = email
            viewController.imageURL = imageURL
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
