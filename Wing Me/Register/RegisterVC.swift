import UIKit
import CryptoKit
import FBSDKLoginKit
import AuthenticationServices

class RegisterVC: UIViewController, UITextFieldDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    let imageView = UIImageView()
    private let nameTextField = UITextField()
    private let codeButton = UIButton(type: .custom)
    private let phoneTextField = UITextField()
    private let termsSwitch = UISwitch()
    private let registerButton = WPillButton()
    private let registerIndicator = UIActivityIndicatorView(style: .medium)
    private let appleButton = UIButton(type: .custom)
    private let facebookButton = WPillButton()
    private let facebookIndicator = UIActivityIndicatorView(style: .medium)

    var codesArray: [CustomCell] = []
    var code = "1"
    private var currentNonce: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()

        for (key, value) in Constants.countryCodes {
            codesArray.append(CustomCell.init(string1: value, string2: key))
        }
        codesArray = codesArray.sorted {
            (customCell1, customCell2) in
            return customCell1.string2 < customCell2.string2
        }
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        let backButton = UIButton(type: .system)
        backButton.setTitle("‹", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .regular)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = Colors.back_gray
        imageView.layer.cornerRadius = 48
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let photoTap = UITapGestureRecognizer(target: self, action: #selector(addPicture))
        imageView.addGestureRecognizer(photoTap)

        nameTextField.placeholder = "Name"
        nameTextField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [.foregroundColor: UIColor.lightGray])
        nameTextField.textColor = .white
        nameTextField.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameTextField.backgroundColor = Colors.back_gray
        nameTextField.layer.cornerRadius = 10
        nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        nameTextField.leftViewMode = .always
        nameTextField.delegate = self
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        codeButton.setTitle("+1", for: .normal)
        codeButton.setTitleColor(.white, for: .normal)
        codeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        codeButton.backgroundColor = Colors.back_gray
        codeButton.layer.cornerRadius = 10
        codeButton.addTarget(self, action: #selector(countryCode), for: .touchUpInside)
        codeButton.translatesAutoresizingMaskIntoConstraints = false

        phoneTextField.placeholder = "Phone"
        phoneTextField.attributedPlaceholder = NSAttributedString(string: "Phone", attributes: [.foregroundColor: UIColor.lightGray])
        phoneTextField.textColor = .white
        phoneTextField.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        phoneTextField.backgroundColor = Colors.back_gray
        phoneTextField.layer.cornerRadius = 10
        phoneTextField.keyboardType = .phonePad
        phoneTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        phoneTextField.leftViewMode = .always
        phoneTextField.delegate = self
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false

        let termsLabel = UILabel()
        termsLabel.text = "I agree to the Terms & Privacy Policy"
        termsLabel.textColor = .white
        termsLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        termsLabel.numberOfLines = 0
        termsLabel.isUserInteractionEnabled = true
        termsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(terms)))
        termsLabel.translatesAutoresizingMaskIntoConstraints = false

        termsSwitch.onTintColor = Colors.blue
        termsSwitch.translatesAutoresizingMaskIntoConstraints = false

        registerButton.setTitle("Register", for: .normal)
        registerButton.applyTealStyle()
        registerButton.addTarget(self, action: #selector(register), for: .touchUpInside)
        registerButton.translatesAutoresizingMaskIntoConstraints = false

        registerIndicator.color = .white
        registerIndicator.hidesWhenStopped = true
        registerIndicator.translatesAutoresizingMaskIntoConstraints = false

        appleButton.setTitle("Continue with Apple", for: .normal)
        appleButton.setTitleColor(.white, for: .normal)
        appleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        appleButton.backgroundColor = Colors.back_gray
        appleButton.layer.cornerRadius = 10
        appleButton.addTarget(self, action: #selector(appleRegister), for: .touchUpInside)
        appleButton.translatesAutoresizingMaskIntoConstraints = false

        facebookButton.setTitle("Continue with Facebook", for: .normal)
        facebookButton.addTarget(self, action: #selector(facebookRegister), for: .touchUpInside)
        facebookButton.translatesAutoresizingMaskIntoConstraints = false

        facebookIndicator.color = .white
        facebookIndicator.hidesWhenStopped = true
        facebookIndicator.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(named: "icon_watermark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        [backButton, imageView, nameTextField, codeButton, phoneTextField, termsSwitch, termsLabel,
         registerButton, registerIndicator, appleButton, facebookButton, facebookIndicator, logo]
            .forEach { content.addSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            backButton.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),

            imageView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 96),
            imageView.heightAnchor.constraint(equalToConstant: 96),

            nameTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 32),
            nameTextField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            nameTextField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            nameTextField.heightAnchor.constraint(equalToConstant: 56),

            codeButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            codeButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            codeButton.widthAnchor.constraint(equalToConstant: 64),
            codeButton.heightAnchor.constraint(equalToConstant: 56),

            phoneTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            phoneTextField.leadingAnchor.constraint(equalTo: codeButton.trailingAnchor, constant: 8),
            phoneTextField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            phoneTextField.heightAnchor.constraint(equalToConstant: 56),

            termsSwitch.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 20),
            termsSwitch.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),

            termsLabel.centerYAnchor.constraint(equalTo: termsSwitch.centerYAnchor),
            termsLabel.leadingAnchor.constraint(equalTo: termsSwitch.trailingAnchor, constant: 10),
            termsLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),

            registerButton.topAnchor.constraint(equalTo: termsSwitch.bottomAnchor, constant: 24),
            registerButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            registerButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            registerButton.heightAnchor.constraint(equalToConstant: 56),

            registerIndicator.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 12),
            registerIndicator.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            appleButton.topAnchor.constraint(equalTo: registerIndicator.bottomAnchor, constant: 20),
            appleButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            appleButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            appleButton.heightAnchor.constraint(equalToConstant: 50),

            facebookButton.topAnchor.constraint(equalTo: appleButton.bottomAnchor, constant: 12),
            facebookButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            facebookButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            facebookButton.heightAnchor.constraint(equalToConstant: 50),

            facebookIndicator.topAnchor.constraint(equalTo: facebookButton.bottomAnchor, constant: 12),
            facebookIndicator.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            logo.topAnchor.constraint(equalTo: facebookIndicator.bottomAnchor, constant: 24),
            logo.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 32),
            logo.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
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

    @objc func back() {
        dismiss(animated: true)
    }

    @objc func addPicture() {
        showPicker(sourceView: imageView)
    }

    @objc func countryCode() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "PickerVC") as? PickerVC {
            viewController.array = codesArray
            viewController.selectItem = selectCode
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }

    @objc func terms() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "AboutVC") as? AboutVC {
            viewController.titleString = Strings.terms
            viewController.path = "terms.php"
            present(viewController, animated: true, completion: nil)
        }
    }

    @objc func register() {
        view.endEditing(true)
        guard let name = nameTextField.text, !name.isEmpty,
              let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty,
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

        let phone = "+\(code)\(phoneNumber)"
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
        vc.name = nameTextField.text ?? ""
        vc.avatarImage = imageView.image
        vc.modalPresentationStyle = .currentContext
        present(vc, animated: true)
    }

    @objc func facebookRegister() {
        facebookButton.isHidden = true
        facebookIndicator.startAnimating()
        facebookRegisterFlow()
    }

    @objc func appleRegister() {
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

    func facebookRegisterFlow() {
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
