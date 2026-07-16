# Beta Phase 2 — Registration Screen Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Apply the `ponytail` skill's YAGNI discipline — no Affiliation/Industry/Role fields, no multi-select component, no Email field; those are explicitly deferred per the spec.

**Goal:** Convert `RegisterVC` to a fully programmatic, WAP-styled screen collecting only photo/name/phone/terms, per `docs/superpowers/specs/2026-07-08-beta-phase2-registration-design.md`.

**Architecture:** Task 1 makes `WAPRegistrationProfile`'s gender/date_of_birth optional (small, isolated data-layer change). Task 2 replaces `RegisterVC.swift` entirely with a programmatic-UI version matching `OTPVerifyVC`'s visual style, widens `RegisterPicker.swift`'s `showPicker` to accept any `UIView` (not just `UIButton`, since the photo picker is now a tapped `UIImageView`), and removes the now-dead gender/birthdate helper.

**Tech Stack:** Swift 5, UIKit, AuthenticationServices, FBSDKLoginKit (unchanged Facebook path).

## Global Constraints

- Open `The W App.xcworkspace`, never `.xcodeproj`.
- Verify each task with a full build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build` from `/Users/sr/thewapp-copy`.
- No functional XCTest target exists (known, pre-existing) — verification is build-only, no test files in this plan.
- Do not modify `FcbRegisterVC.swift`/`FcbRegisterPicker.swift` (Facebook-path screen, out of scope) beyond what Task 1's optional-field change requires — which is nothing, since non-optional values assign fine to optional parameters.
- Do not modify `PickerVC.swift` (country code) or the storyboard `AboutVC` scene (terms) — both stay as-is.

---

### Task 1: Make registration profile gender/birthdate optional

**Files:**
- Modify: `The W App/Classes/WAPSupabase.swift` (the `WAPRegistrationProfile` struct)
- Modify: `The W App/Register/OTPVerifyVC.swift` (the `gender`/`birthDate` properties)

**Interfaces:**
- Produces: `WAPRegistrationProfile.gender: String?`, `.date_of_birth: String?`; `OTPVerifyVC.gender: String?`, `.birthDate: String?` — Task 2's new `RegisterVC.openOTPVerify` relies on being able to leave these unset (defaulting to `nil`).

- [ ] **Step 1: Update `WAPRegistrationProfile`**

In `The W App/Classes/WAPSupabase.swift`, replace:

```swift
struct WAPRegistrationProfile: Encodable {
    let id: String
    let display_name: String
    let phone: String?
    let gender: String
    let date_of_birth: String
    let avatar_url: String?
}
```

with:

```swift
struct WAPRegistrationProfile: Encodable {
    let id: String
    let display_name: String
    let phone: String?
    let gender: String?
    let date_of_birth: String?
    let avatar_url: String?
}
```

- [ ] **Step 2: Update `OTPVerifyVC`'s properties**

In `The W App/Register/OTPVerifyVC.swift`, replace:

```swift
    var phone = ""
    var name = ""
    var gender = ""
    var birthDate = ""
    var avatarImage: UIImage?
```

with:

```swift
    var phone = ""
    var name = ""
    var gender: String? = nil
    var birthDate: String? = nil
    var avatarImage: UIImage?
```

No other changes needed in this file — `upsertProfile()`'s `WAPRegistrationProfile(..., gender: gender, date_of_birth: birthDate, ...)` call already passes these straight through, and now both sides are optional so it compiles unchanged.

- [ ] **Step 3: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED. (`RegisterVC.openOTPVerify` still assigns non-optional `getGender()`/`birthDate` at this point — Task 2 hasn't run yet — which still compiles fine since non-optional assigns to optional.)

- [ ] **Step 4: Commit**

```bash
cd /Users/sr/thewapp-copy
git add "The W App/Classes/WAPSupabase.swift" "The W App/Register/OTPVerifyVC.swift"
git commit -m "fix: make WAPRegistrationProfile/OTPVerifyVC gender and birthdate optional"
```

---

### Task 2: Rebuild RegisterVC as a programmatic screen

**Files:**
- Modify: `The W App/Register/RegisterVC.swift` (full rewrite of the class body — same class name, same file, storyboard scene abandoned)
- Modify: `The W App/Register/RegisterPicker.swift` (widen `showPicker`'s parameter type, remove the now-dead `getGender()` method)

**Interfaces:**
- Consumes: `WAPRegistrationProfile`/`OTPVerifyVC.gender`/`.birthDate` optionality (Task 1); `WAPAuth.signInWithPhone`/`.signInWithApple` (existing, unchanged); `WPillButton`, `Colors`, `WAPTabBarVC` (existing, from Phase 0); `RegisterPicker.swift`'s `showPicker(sourceView:)`/`imagePickerController`/`resizeImage` (this task widens `showPicker`'s signature, see Step 2); `PickerVC` (existing storyboard scene, unchanged); `AboutVC` (existing storyboard scene, unchanged).
- Produces: `RegisterVC` with `imageView: UIImageView` (non-private — `RegisterPicker.swift`'s extension methods reference `self.imageView`).

- [ ] **Step 1: Replace `RegisterVC.swift` entirely**

Replace the full contents of `The W App/Register/RegisterVC.swift` with:

```swift
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
```

Note: the original `RegisterVC` had a `setKeyboard()` call in `viewDidLoad` that registered keyboard notification observers with empty handler bodies (`keyboardWillShow`/`keyboardWillHide` did nothing) — dead code, correctly dropped in this rewrite rather than carried forward.

- [ ] **Step 2: Widen `showPicker`'s parameter type in `RegisterPicker.swift`**

The old `RegisterVC` triggered the photo picker from a `UIButton`'s `@IBAction`; the new one triggers it from a tap gesture on `imageView` (a `UIImageView`, not a button). `RegisterPicker.swift`'s `showPicker(button: UIButton)` only uses the parameter for `sourceView`/`.sourceRect` (any `UIView` works there), so widen it.

In `The W App/Register/RegisterPicker.swift`, replace:

```swift
    func showPicker(button: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self

        let actionSheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) {
            _ in
            picker.allowsEditing = false
            picker.sourceType = .camera
            self.present(picker, animated: true)
        })

        actionSheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) {
            _ in
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })

        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))

        actionSheet.popoverPresentationController?.sourceView = button
        actionSheet.popoverPresentationController?.sourceRect = button.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
```

with:

```swift
    func showPicker(sourceView: UIView) {
        let picker = UIImagePickerController()
        picker.delegate = self

        let actionSheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) {
            _ in
            picker.allowsEditing = false
            picker.sourceType = .camera
            self.present(picker, animated: true)
        })

        actionSheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) {
            _ in
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })

        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))

        actionSheet.popoverPresentationController?.sourceView = sourceView
        actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
```

- [ ] **Step 3: Remove the dead `getGender()` from `RegisterPicker.swift`**

`RegisterVC` no longer has a `lastGender` property (the gender-selection UI is gone), so `RegisterPicker.swift`'s `getGender()` method (which reads `lastGender`) no longer compiles. Remove it entirely:

```swift
    func getGender() -> String {
        let genders = ["M", "F", "O"]
        return genders[lastGender - 11]
    }
```

Delete this method from `The W App/Register/RegisterPicker.swift`. Confirm nothing else calls `RegisterVC`'s `getGender()` first: `grep -rn "\.getGender()" "The W App" --include="*.swift"` — expect only `FcbRegisterPicker.swift`'s own separate `getGender()` (on a different type, `FcbRegisterVC`, untouched by this plan) to remain.

- [ ] **Step 4: Check for other callers of the old `showPicker(button:)` signature**

Run: `grep -rn "showPicker(button:\|showPicker(sourceView:" "The W App" --include="*.swift"` from `/Users/sr/thewapp-copy`. Expect: `RegisterPicker.swift`'s new definition and `RegisterVC.swift`'s new call (both `sourceView:`), plus `FcbRegisterPicker.swift`'s own separate `showPicker(button:)` on a different type (`FcbRegisterVC`) — confirm that one is untouched (still says `button: UIButton`), not accidentally caught by find-and-replace.

- [ ] **Step 5: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace "The W App.xcworkspace" -scheme "The W App" -destination "generic/platform=iOS Simulator" build`
Expected: BUILD SUCCEEDED. This is a large rewrite — if anything fails to compile, check that `Strings.alertEmpty`/`Strings.alertTerms`/`Strings.alertConnection`/`Strings.terms`/`Strings.optionTitle`/`Strings.optionCamera`/`Strings.optionGallery`/`Strings.optionCancel`/`Strings.optionDetails` all exist with those exact names in `The W App/Classes/Strings.swift`, and that `AlertClass().showWarningAlert(delegate:message:)`/`.showErrorAlert(delegate:message:)` and `NSDictionary.getString(key:)` have the exact signatures used above (all of these existed in the original file this replaces, so they should already be correct — this check is a safety net, not an expected failure).

- [ ] **Step 6: Confirm the storyboard entry point still works**

The old `RegisterVC` storyboard scene in `Main.storyboard` may still be instantiated via `storyboard.instantiateViewController(withIdentifier: "RegisterVC")` somewhere (e.g. from a Welcome/FirstStart screen). Run: `grep -rn "instantiateViewController(withIdentifier: \"RegisterVC\")" "The W App" --include="*.swift"`. If found, leave it as-is — instantiating the class via a storyboard identifier still works even though the class no longer declares any `@IBOutlet`s (there's simply nothing for the storyboard to connect, which is harmless), so no code change is needed. Do not hand-edit `Main.storyboard` XML to remove the scene — out of scope and risky for this plan.

- [ ] **Step 7: Commit**

```bash
git add "The W App/Register/RegisterVC.swift" "The W App/Register/RegisterPicker.swift"
git commit -m "feat: rebuild RegisterVC as a programmatic WAP-styled screen (photo/name/phone/terms only)"
```

---

## Verification

1. Both tasks committed, `xcodebuild ... build` succeeds at HEAD.
2. Manual: run the app, tap through to Register — verify photo picker, name field, country code + phone, terms toggle, Register button, Apple button, and Facebook button (still broken, as expected) all render in the dark WAP style and don't crash. Enter name + phone + accept terms + tap Register → OTP screen appears (existing, unchanged flow).
3. `grep -rn "lastGender\|selectGender\|selectBithDate\|dateButton\|passwordTextField\|confirmTextField\|emailTextField" "The W App/Register/RegisterVC.swift"` returns zero hits — confirms the old fields are fully gone, not just hidden.

## Known Deferred
- Affiliation/Industry/Role fields + multi-select component — future profile-edit phase.
- Email field — future profile-edit phase.
- Facebook sign-in logic itself — still broken (`signInWithFacebook` OIDC mismatch), unchanged, tracked separately.
- Hand-editing `Main.storyboard` to remove the now-unused `RegisterVC` scene XML — left in place, harmless, not worth the risk of manual storyboard XML surgery for this phase.
