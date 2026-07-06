
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

    var currentNonce: String?

    var codesArray: [CustomCell] = []

    var code = "1"

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
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else { return }
        Task {
            do {
                try await WAPAuth.signInWithApple(idToken: idToken, nonce: nonce)
                navigateToHome()
            } catch {
                showAlert(error.localizedDescription)
            }
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
        guard let phone = phoneTextField.text, !phone.isEmpty else {
            showAlert(Strings.alertEmpty); return
        }
        loginButton.isHidden = true
        loginIndicator.startAnimating()
        Task {
            do {
                try await WAPAuth.signInWithPhone(phone: code + phone)
                loginButton.isHidden = false
                loginIndicator.stopAnimating()
                // Push OTP verification screen (built in Plan 2)
                showAlert("Verification code sent to \(code + phone)")
            } catch {
                loginButton.isHidden = false
                loginIndicator.stopAnimating()
                showAlert(error.localizedDescription)
            }
        }
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

        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile"], from: self) { [weak self] result, error in
            guard let self = self else { return }
            if let _ = error {
                self.facebookButton.isHidden = false
                self.facebookIndicator.stopAnimating()
                self.showAlert(Strings.alertConnection)
                return
            }
            if let token = AccessToken.current?.tokenString {
                Task {
                    do {
                        try await WAPAuth.signInWithFacebook(accessToken: token)
                        self.navigateToHome()
                    } catch {
                        self.facebookButton.isHidden = false
                        self.facebookIndicator.stopAnimating()
                        self.showAlert(error.localizedDescription)
                    }
                }
            } else {
                self.facebookButton.isHidden = false
                self.facebookIndicator.stopAnimating()
            }
        }
    }

    @IBAction func appleLogin(_ sender: UIButton) {
        if #available(iOS 13.0, *) {
            currentNonce = UUID().uuidString
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

    func showAlert(_ message: String) {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: self, message: message)
    }

    func navigateToHome() {
        openMain()
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
