
import UIKit
import FirebaseAuth

class ForgotPasswordVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var verificationView: UIView!
    @IBOutlet weak var verificationTextField: UITextField!
    @IBOutlet weak var passwordView: UIStackView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nextIndicator: UIActivityIndicatorView!
    
    var codesArray: [CustomCell] = []
    
    var step = 1
    var code = "1"
    var verificationID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        verificationView.isHidden = true
        passwordView.isHidden = true
        
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
    
    @IBAction func next(_ sender: UIButton) {
        view.endEditing(true)
        
        if step == 1 {
            guard !phoneTextField.getPhone().isEmpty else {
                let alertClass = AlertClass()
                alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
                return
            }
            nextButton.isHidden = true
            nextIndicator.startAnimating()
            sendCode()
        } else if step == 2 {
            guard !verificationTextField.getText().isEmpty else {
                let alertClass = AlertClass()
                alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
                return
            }
            nextButton.isHidden = true
            nextIndicator.startAnimating()
            verifyCode()
        } else {
            guard !passwordTextField.getText().isEmpty && !confirmTextField.getText().isEmpty else {
                let alertClass = AlertClass()
                alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
                return
            }
            guard passwordTextField.getText() == confirmTextField.getText() else {
                let alertClass = AlertClass()
                alertClass.showWarningAlert(delegate: self, message: Strings.alertBoth)
                return
            }
            nextButton.isHidden = true
            nextIndicator.startAnimating()
            reset()
        }
    }
    
    func selectCode(customCell: CustomCell) {
        code = customCell.string1
        codeButton.setTitle("+\(customCell.string1!)", for: .normal)
    }
    
    func sendCode() {
        setPhoneDisabled()
        
        PhoneAuthProvider.provider().verifyPhoneNumber("+\(code + phoneTextField.getPhone())", uiDelegate: nil) {
            (verificationID, error) in
            self.nextButton.isHidden = false
            self.nextIndicator.stopAnimating()
            
            guard let verificationID = verificationID, error == nil else {
                let alertClass = AlertClass()
                alertClass.showErrorAlert(delegate: self, message: error.debugDescription)
                
                self.setPhoneEnabled()
                return
            }
            self.step = 2
            self.verificationID = verificationID
            self.verificationView.isHidden = false
        }
    }
    
    func setPhoneDisabled() {
        codeButton.alpha = 0.2
        phoneTextField.alpha = 0.2
        
        codeButton.isEnabled = false
        phoneTextField.isEnabled = false
    }
    
    func setPhoneEnabled() {
        codeButton.alpha = 1
        phoneTextField.alpha = 1
        
        codeButton.isEnabled = true
        phoneTextField.isEnabled = true
    }
    
    func verifyCode() {
        setVerificationDisabled()
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationTextField.getText())
        
        Auth.auth().signIn(with: credential) {
            (authResult, error) in
            self.nextButton.isHidden = false
            self.nextIndicator.stopAnimating()
            
            if let _ = error {
                let alertClass = AlertClass()
                alertClass.showErrorAlert(delegate: self, message: Strings.alertVerification)
                
                self.setVerificationEnabled()
                return
            }
            self.step = 3
            self.passwordView.isHidden = false
            self.nextButton.setTitle("Reset Password", for: .normal)
        }
    }
    
    func setVerificationDisabled() {
        verificationTextField.alpha = 0.2
        verificationTextField.isEnabled = false
    }
    
    func setVerificationEnabled() {
        verificationTextField.alpha = 1
        verificationTextField.isEnabled = true
    }
    
    func reset() {
        let path = "reset_password.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "phone": code + phoneTextField.getPhone(),
            "password": passwordTextField.getText(),
            "uid": Constants.getUID()
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        nextButton.isHidden = false
        nextIndicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        let alertClass = AlertClass()
        alertClass.showSuccessAlert(delegate: self, message: Strings.alertPasswordReset, action: {
            self.dismiss(animated: true)
        })
    }
}
