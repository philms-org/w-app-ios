
import UIKit

class FifthSetupVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var drinkTextField: UITextField!
    @IBOutlet weak var fridayTextField: UITextField!
    @IBOutlet weak var professionTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!
    
    var city = String()
    var nationality = String()
    var height = String()
    var relationship = String()
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    var drink = String()
    var activity = String()
    var profession = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        
        cityTextField.text = city
        drinkTextField.text = drink
        fridayTextField.text = activity
        professionTextField.text = profession
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func save(_ sender: UIButton) {
        view.endEditing(true)
        
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        send()
    }
    
    func send() {
        guard let uid = WAPAuth.currentUserID else {
            saveButton.isHidden = false
            saveIndicator.stopAnimating()
            return
        }
        let profile = WAPProfile(
            id: uid,
            displayName: "",
            city: cityTextField.getText().isEmpty ? nil : cityTextField.getText(),
            faveDrink: drinkTextField.getText().isEmpty ? nil : drinkTextField.getText(),
            fridayNight: fridayTextField.getText().isEmpty ? nil : fridayTextField.getText(),
            profession: professionTextField.getText().isEmpty ? nil : professionTextField.getText(),
            height: Double(height),
            nationality: nationality.isEmpty ? nil : nationality,
            relationship: relationship.isEmpty ? nil : relationship,
            datingId: Int(datingID),
            socialisingId: Int(socialisingID),
            networkingId: Int(networkingID)
        )
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPData.shared.upsertProfile(profile)
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
            await MainActor.run {
                self.saveButton.isHidden = false
                self.saveIndicator.stopAnimating()
                appDelegate.inLocation = false
                UserDefaults.standard.set(true, forKey: "Setup")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
                    vc.modalPresentationStyle = .currentContext
                    self.present(vc, animated: true)
                }
            }
        }
    }
}
