
import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        codeButton.isHidden = true
        verificationView.isHidden = true
        passwordView.isHidden = true
        phoneTextField.placeholder = "Email address"
        phoneTextField.keyboardType = .emailAddress
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func countryCode(_ sender: UIButton) {
        // No-op — codeButton is hidden; IBAction kept for storyboard compatibility
    }

    @IBAction func next(_ sender: UIButton) {
        view.endEditing(true)
        let email = phoneTextField.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        nextButton.isHidden = true
        nextIndicator.startAnimating()
        sendReset(email: email)
    }

    private func sendReset(email: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPSupabase.shared.client.auth.resetPasswordForEmail(email)
                await MainActor.run {
                    self.nextButton.isHidden = false
                    self.nextIndicator.stopAnimating()
                    AlertClass().showSuccessAlert(delegate: self, message: "Password reset link sent. Check your email.", action: { [weak self] in
                        self?.dismiss(animated: true)
                    })
                }
            } catch {
                await MainActor.run {
                    self.nextButton.isHidden = false
                    self.nextIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
}
