import UIKit
import CryptoKit
import FBSDKLoginKit
import AuthenticationServices

class RegisterVC: UIViewController, UITextFieldDelegate,
                  ASAuthorizationControllerDelegate,
                  ASAuthorizationControllerPresentationContextProviding {

    // MARK: - UI
    private let nameTextField      = UITextField()
    private let emailTextField     = UITextField()
    private let passwordTextField  = UITextField()
    private let affiliationButton  = UIButton(type: .system)
    private let industryButton     = UIButton(type: .system)
    private let roleButton         = UIButton(type: .system)
    private let termsSwitch        = UISwitch()
    private let registerButton     = WPillButton()
    private let registerIndicator  = UIActivityIndicatorView(style: .medium)
    private let appleButton        = UIButton(type: .custom)
    private let facebookButton     = WPillButton()
    private let facebookIndicator  = UIActivityIndicatorView(style: .medium)

    // MARK: - State
    private var currentNonce: String?
    private var selectedAffiliation: String?
    private var selectedIndustry: String?
    private var selectedRole: String?

    private let affiliations = [
        "Corporate", "Startup", "Agency", "Non-Profit",
        "Government", "Academic", "Healthcare", "Independent", "Other"
    ]
    private let industries = [
        "Technology", "Finance", "Real Estate", "Healthcare",
        "Entertainment", "Food & Beverage", "Fashion & Beauty",
        "Legal", "Marketing", "Consulting", "Education", "Other"
    ]
    private let roles = [
        "Executive / C-Suite", "Director", "Manager", "Professional",
        "Entrepreneur", "Creative", "Consultant", "Student", "Other"
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
    }

    // MARK: - UI Setup
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

        let titleLabel = UILabel()
        titleLabel.text = "Sign Up"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        configure(textField: nameTextField,     placeholder: "Name")
        configure(textField: emailTextField,    placeholder: "Email", keyboard: .emailAddress)
        configure(textField: passwordTextField, placeholder: "Password", secure: true)

        configure(dropdownButton: affiliationButton, placeholder: "Affiliation")
        affiliationButton.addTarget(self, action: #selector(pickAffiliation), for: .touchUpInside)

        configure(dropdownButton: industryButton, placeholder: "Industry")
        industryButton.addTarget(self, action: #selector(pickIndustry), for: .touchUpInside)

        configure(dropdownButton: roleButton, placeholder: "Role")
        roleButton.addTarget(self, action: #selector(pickRole), for: .touchUpInside)

        let termsLabel = UILabel()
        termsLabel.text = "I agree to the Terms & Privacy Policy"
        termsLabel.textColor = .white
        termsLabel.font = UIFont.systemFont(ofSize: 13)
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

        let dividerStack = makeDivider()

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

        [backButton, titleLabel,
         nameTextField, emailTextField, passwordTextField,
         affiliationButton, industryButton, roleButton,
         termsSwitch, termsLabel,
         registerButton, registerIndicator,
         dividerStack,
         appleButton, facebookButton, facebookIndicator,
         logo].forEach { content.addSubview($0) }

        let pad: CGFloat = 24

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

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            nameTextField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 32),
            nameTextField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            nameTextField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            nameTextField.heightAnchor.constraint(equalToConstant: 56),

            emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 14),
            emailTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: 56),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 14),
            passwordTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 56),

            affiliationButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 14),
            affiliationButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            affiliationButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            affiliationButton.heightAnchor.constraint(equalToConstant: 56),

            industryButton.topAnchor.constraint(equalTo: affiliationButton.bottomAnchor, constant: 14),
            industryButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            industryButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            industryButton.heightAnchor.constraint(equalToConstant: 56),

            roleButton.topAnchor.constraint(equalTo: industryButton.bottomAnchor, constant: 14),
            roleButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            roleButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            roleButton.heightAnchor.constraint(equalToConstant: 56),

            termsSwitch.topAnchor.constraint(equalTo: roleButton.bottomAnchor, constant: 20),
            termsSwitch.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),

            termsLabel.centerYAnchor.constraint(equalTo: termsSwitch.centerYAnchor),
            termsLabel.leadingAnchor.constraint(equalTo: termsSwitch.trailingAnchor, constant: 10),
            termsLabel.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),

            registerButton.topAnchor.constraint(equalTo: termsSwitch.bottomAnchor, constant: 24),
            registerButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            registerButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            registerButton.heightAnchor.constraint(equalToConstant: 56),

            registerIndicator.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 12),
            registerIndicator.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            dividerStack.topAnchor.constraint(equalTo: registerIndicator.bottomAnchor, constant: 20),
            dividerStack.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            dividerStack.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),

            appleButton.topAnchor.constraint(equalTo: dividerStack.bottomAnchor, constant: 20),
            appleButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            appleButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            appleButton.heightAnchor.constraint(equalToConstant: 50),

            facebookButton.topAnchor.constraint(equalTo: appleButton.bottomAnchor, constant: 12),
            facebookButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            facebookButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
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

    // MARK: - Field helpers
    private func configure(textField: UITextField, placeholder: String,
                            keyboard: UIKeyboardType = .default, secure: Bool = false) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        textField.backgroundColor = Colors.back_gray
        textField.layer.cornerRadius = 10
        textField.keyboardType = keyboard
        textField.autocapitalizationType = keyboard == .emailAddress ? .none : .words
        textField.autocorrectionType = keyboard == .emailAddress ? .no : .default
        textField.isSecureTextEntry = secure
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        textField.leftViewMode = .always
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configure(dropdownButton button: UIButton, placeholder: String) {
        button.backgroundColor = Colors.back_gray
        button.layer.cornerRadius = 10
        button.contentHorizontalAlignment = .left
        button.setTitle(placeholder, for: .normal)
        button.setTitleColor(.lightGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 40)
        button.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .lightGray
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    private func setDropdown(_ button: UIButton, value: String) {
        button.setTitle(value, for: .normal)
        button.setTitleColor(.white, for: .normal)
    }

    private func makeDivider() -> UIStackView {
        func line() -> UIView {
            let v = UIView()
            v.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 1).isActive = true
            return v
        }
        let label = UILabel()
        label.text = "or"
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        label.font = UIFont.systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [line(), label, line()])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    // MARK: - Dropdown pickers
    @objc private func pickAffiliation() {
        showPicker(title: "Affiliation", options: affiliations) { [weak self] value in
            guard let self else { return }
            self.selectedAffiliation = value
            self.setDropdown(self.affiliationButton, value: value)
        }
    }

    @objc private func pickIndustry() {
        showPicker(title: "Industry", options: industries) { [weak self] value in
            guard let self else { return }
            self.selectedIndustry = value
            self.setDropdown(self.industryButton, value: value)
        }
    }

    @objc private func pickRole() {
        showPicker(title: "Role", options: roles) { [weak self] value in
            guard let self else { return }
            self.selectedRole = value
            self.setDropdown(self.roleButton, value: value)
        }
    }

    private func showPicker(title: String, options: [String], onSelect: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for option in options {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in onSelect(option) })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - TextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true); return false
    }

    // MARK: - Register action
    @objc private func register() {
        view.endEditing(true)
        guard let name     = nameTextField.text,    !name.isEmpty,
              let email    = emailTextField.text,   !email.isEmpty,
              let password = passwordTextField.text, password.count >= 6 else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty); return
        }
        guard termsSwitch.isOn else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertTerms); return
        }
        registerButton.isHidden = true
        registerIndicator.startAnimating()

        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPAuth.signUp(email: email, password: password)
                await MainActor.run {
                    self.openRegister(name: name, email: email,
                                      affiliation: self.selectedAffiliation,
                                      industry: self.selectedIndustry,
                                      role: self.selectedRole)
                }
            } catch {
                await MainActor.run {
                    self.registerButton.isHidden = false
                    self.registerIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Navigation
    @objc private func back() { dismiss(animated: true) }

    @objc private func terms() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AboutVC") as? AboutVC {
            vc.titleString = Strings.terms
            vc.path = "terms.php"
            present(vc, animated: true)
        }
    }

    func openRegister(name: String, email: String, imageURL: String = "",
                      affiliation: String?, industry: String?, role: String?) {
        let vc = FcbRegisterVC()
        vc.name = name
        vc.email = email
        vc.imageURL = imageURL
        vc.affiliation = affiliation
        vc.industry = industry
        vc.role = role
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    // MARK: - Apple Sign In
    @objc private func appleRegister() {
        let rawNonce = randomNonceString()
        currentNonce = rawNonce
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(rawNonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred      = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let idToken   = String(data: tokenData, encoding: .utf8),
              let nonce     = currentNonce else { return }
        let firstName = cred.fullName?.givenName  ?? ""
        let lastName  = cred.fullName?.familyName ?? ""
        let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPAuth.signInWithApple(idToken: idToken, nonce: nonce)
                await MainActor.run {
                    self.openRegister(name: name, email: cred.email ?? "",
                                      affiliation: nil, industry: nil, role: nil)
                }
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        print(error.localizedDescription)
    }

    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    // MARK: - Facebook Sign In
    @objc private func facebookRegister() {
        facebookButton.isHidden = true
        facebookIndicator.startAnimating()
        facebookRegisterFlow()
    }

    func facebookRegisterFlow() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { [weak self] result, error in
            guard let self else { return }
            if error != nil { self.facebookStopLoading(); self.facebookError(); return }
            if let token = result?.token {
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        try await WAPAuth.signInWithFacebook(accessToken: token.tokenString)
                        await MainActor.run { self.request(token: token.tokenString) }
                    } catch {
                        await MainActor.run { self.facebookStopLoading(); self.facebookError() }
                    }
                }
            } else {
                self.facebookStopLoading()
            }
        }
    }

    func request(token: String) {
        let req = GraphRequest(
            graphPath: "me",
            parameters: ["fields": "id, name, email, picture.width(1080).height(1080)"],
            tokenString: token, version: nil, httpMethod: HTTPMethod(rawValue: "GET")
        )
        req.start { [weak self] _, result, error in
            guard let self else { return }
            self.facebookStopLoading()
            guard let dict = result as? NSDictionary, error == nil else {
                self.facebookError(); return
            }
            self.facebookSuccess(result: dict)
        }
    }

    func facebookSuccess(result: NSDictionary) {
        let name  = result.getString(key: "name")
        let email = result.getString(key: "email")
        var imageURL = ""
        if let pic  = result["picture"] as? NSDictionary,
           let data = pic["data"] as? NSDictionary {
            imageURL = data.getString(key: "url")
        }
        openRegister(name: name, email: email, imageURL: imageURL,
                     affiliation: nil, industry: nil, role: nil)
    }

    func facebookError() {
        AlertClass().showErrorAlert(delegate: self, message: Strings.alertConnection)
    }

    func facebookStopLoading() {
        facebookButton.isHidden = false
        facebookIndicator.stopAnimating()
    }

    // MARK: - Crypto
    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}
