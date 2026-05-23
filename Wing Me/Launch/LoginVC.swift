
import UIKit
import FBSDKLoginKit
import AuthenticationServices

class LoginVC: UIViewController, UITextFieldDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @IBOutlet weak var codeButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginIndicator: UIActivityIndicatorView!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var facebookIndicator: UIActivityIndicatorView!
    
    var facebookID = String()
    
    var codesArray: [CustomCell] = []
    
    var code = "1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        
        for (key, value) in Constants.coutriesDictionary {
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
            appleSuccess(appleID: appleId)
            
            guard let fullName = appleIDCredential.fullName else {
                return
            }
            guard let firstName = fullName.givenName, let lastName = fullName.familyName else {
                return
            }
            guard let email = appleIDCredential.email else {
                return
            }
            let name = "\(firstName) \(lastName)"
            let dictionary: NSDictionary = [
                "Name": name,
                "Email": email
            ]
            
            UserDefaults.standard.set(dictionary, forKey: appleId)
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
    
    @IBAction func login(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !phoneTextField.getPhone().isEmpty && !passwordTextField.getText().isEmpty else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        loginButton.isHidden = true
        loginIndicator.startAnimating()
        login()
    }
    
    @IBAction func forgotPassword(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ForgotPasswordVC") as? ForgotPasswordVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func facebookLogin(_ sender: UIButton) {
        facebookButton.isHidden = true
        facebookIndicator.startAnimating()
        facebookLogin()
    }
    
    @IBAction func appleLogin(_ sender: UIButton) {
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
    
    func login() {
        let path = "login.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "phone": code + phoneTextField.getPhone(),
            "password": passwordTextField.getText(),
            "uid": Constants.getUID()
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        loginButton.isHidden = false
        loginIndicator.stopAnimating()
    }
    
    func facebookLogin() {
        let loginManager = LoginManager()
        
        loginManager.logIn(permissions: ["public_profile"], from: self) {
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
        let request = GraphRequest(graphPath: "me", parameters: ["fields": "id"], tokenString: token, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))
        
        request.start(completion: {
            (connection, result, error) in
            
            guard let result = result, error == nil else {
                self.facebookStopLoading()
                self.facebookError()
                return
            }
            if let result = result as? NSDictionary {
                print(result)
                self.facebookSuccess(result: result)
                return
            }
            self.facebookStopLoading()
        })
    }
    
    func facebookError() {
        let alertClass = AlertClass()
        alertClass.showErrorAlert(delegate: self, message: Strings.alertConnection)
    }
    
    func facebookSuccess(result: NSDictionary) {
        let facebookID  = result.getString(key: "id")
        let path = "login_facebook.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "facebook_Id": facebookID,
            "uid": Constants.getUID()
        ]
        
        params.request(delegate: self, path: path, stopLoading: facebookStopLoading, requestSuccess: requestSuccess)
    }
    
    func appleSuccess(appleID: String) {
        let path = "login_facebook.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "facebook_Id": appleID,
            "uid": Constants.getUID()
        ]
        
        params.request(delegate: self, path: path, stopLoading: facebookStopLoading, requestSuccess: requestSuccess)
    }
    
    func facebookStopLoading() {
        facebookButton.isHidden = false
        facebookIndicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            let token = message.getString(key: "token")
            UserDefaults.standard.set(token, forKey: "Token")
            
            phoneTextField.text = ""
            passwordTextField.text = ""
            
            let is_first_time = message.getBool(key: "is_first_time")
            
            if is_first_time {
                openChangePassword()
            } else {
                openMain()
            }
        }
    }
    
    func openChangePassword() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as? ChangePasswordVC {
            viewController.fromLogin = true
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func openMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.isLogin = true
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
