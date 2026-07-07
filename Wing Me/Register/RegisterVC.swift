
import UIKit
import CryptoKit
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
    private var currentNonce: String?
    
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
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else { return }
        let firstName = cred.fullName?.givenName ?? ""
        let lastName  = cred.fullName?.familyName ?? ""
        let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        Task {
            do {
                try await WAPAuth.signInWithApple(idToken: idToken, nonce: nonce)
                await MainActor.run {
                    self.openRegister(id: "", name: name, email: cred.email ?? "", imageURL: "")
                }
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

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
        guard !nameTextField.getText().isEmpty && !phoneTextField.getPhone().isEmpty
                && lastGender != 0 && !birthDate.isEmpty,
              let image = imageView.image, let _ = image.pngData() else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        guard termsSwitch.isOn else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertTerms)
            return
        }
        registerButton.isHidden = true
        registerIndicator.startAnimating()
        let phone = "+\(code)\(phoneTextField.getPhone())"
        Task {
            do {
                try await WAPAuth.signInWithPhone(phone: phone)
                await MainActor.run { self.openOTPVerify(phone: phone) }
            } catch {
                await MainActor.run {
                    self.registerButton.isHidden = false
                    self.registerIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func openOTPVerify(phone: String) {
        let vc = OTPVerifyVC()
        vc.phone = phone
        vc.name = nameTextField.getText()
        vc.gender = getGender()
        vc.birthDate = birthDate
        vc.avatarImage = imageView.image
        vc.modalPresentationStyle = .currentContext
        present(vc, animated: true)
    }
    
    @IBAction func facebookRegister(_ sender: UIButton) {
        facebookButton.isHidden = true
        facebookIndicator.startAnimating()
        facebookRegister()
    }
    
    @IBAction func appleRegister(_ sender: UIButton) {
        let rawNonce = randomNonceString()
        currentNonce = rawNonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(rawNonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
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
