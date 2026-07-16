
import UIKit
import Supabase

class ChangePasswordVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var oldTextField: UITextField!
    @IBOutlet weak var newTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var changeIndicator: UIActivityIndicatorView!

    var fromLogin = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func change(_ sender: UIButton) {
        view.endEditing(true)
        guard !newTextField.getText().isEmpty && !confirmTextField.getText().isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        guard newTextField.getText() == confirmTextField.getText() else {
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertBoth)
            return
        }
        changeButton.isHidden = true
        changeIndicator.startAnimating()
        changePassword()
    }

    private func changePassword() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPSupabase.shared.client.auth.update(
                    user: UserAttributes(password: self.newTextField.getText())
                )
                await MainActor.run {
                    self.changeButton.isHidden = false
                    self.changeIndicator.stopAnimating()
                    AlertClass().showSuccessAlert(delegate: self, message: Strings.alertPasswordChanged, action: { [weak self] in
                        self?.dismiss(animated: true)
                    })
                }
            } catch {
                await MainActor.run {
                    self.changeButton.isHidden = false
                    self.changeIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
}
