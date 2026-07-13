
import UIKit

class EditProfileVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var agePrivateSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!

    var reloadProfile: (() -> ())?

    var pickedImage: UIImage?

    var imageURL = String()
    var name = String()
    var phone = String()
    var email = String()
    var city = String()
    var nationality = String()
    var birthDate = String()
    var agePrivacy = String()
    var gender = String()
    var height = String()
    var relationship = String()
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    var drink = String()
    var activity = String()
    var profession = String()

    var lastGender = Int()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        updateUI()
        // Hide dating-era fields — WAPProfile has no gender/birthdate/agePrivacy
        dateButton.isHidden = true
        agePrivateSwitch.superview?.isHidden = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func addPicture(_ sender: UIButton) {
        showPicker(button: sender)
    }

    @IBAction func selectGender(_ sender: UIButton) {
        view.endEditing(true)
        if sender.tag == lastGender { return }
        selectGender(tag: sender.tag)
    }

    @IBAction func selectBithDate(_ sender: Any) {
        // Dating-era — no-op (dateButton is hidden)
    }

    @IBAction func save(_ sender: UIButton) {
        view.endEditing(true)
        guard !nameTextField.getText().isEmpty else {
            AlertClass().showWarningAlert(delegate: self, message: "Please enter your name.")
            return
        }
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        saveProfile()
    }

    private func saveProfile() {
        guard let uid = WAPAuth.currentUserID else {
            saveButton.isHidden = false
            saveIndicator.stopAnimating()
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                var avatarURL: String? = self.imageURL.isEmpty ? nil : self.imageURL
                if let newImage = self.pickedImage,
                   let data = newImage.jpegData(compressionQuality: 0.8) {
                    avatarURL = try await WAPData.shared.uploadAvatar(imageData: data, userId: uid)
                }
                let profile = WAPProfile(
                    id: uid,
                    displayName: self.nameTextField.getText(),
                    email: self.emailTextField.getText().isEmpty ? nil : self.emailTextField.getText(),
                    phone: self.phoneTextField.getText().isEmpty ? nil : self.phoneTextField.getText(),
                    avatarURL: avatarURL
                )
                try await WAPData.shared.upsertProfile(profile)
                await MainActor.run {
                    self.saveButton.isHidden = false
                    self.saveIndicator.stopAnimating()
                    self.reloadProfile?()
                    AlertClass().showSuccessAlert(delegate: self, message: Strings.alertInfoEdited, action: {
                        self.dismiss(animated: true)
                    })
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isHidden = false
                    self.saveIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func setupProfile(_ sender: UIButton) {
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? ""

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SecondSetupVC") as? SecondSetupVC {
            viewController.regionCode = regionCode
            viewController.city = city
            viewController.nationality = nationality
            viewController.height = height
            viewController.relationship = relationship
            viewController.datingID = datingID
            viewController.socialisingID = socialisingID
            viewController.networkingID = networkingID
            viewController.drink = drink
            viewController.activity = activity
            viewController.profession = profession
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }

    @IBAction func deleteAccount(_ sender: UIButton) {
        if let encodedURL = Constants.deleteAccountURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedURL) {
            UIApplication.shared.open(url, options: [:])
        }
    }

    func selectGender(tag: Int) {
        if let lastView = view.viewWithTag(lastGender + 5), let lastButton = view.viewWithTag(lastGender) as? UIButton {
            lastView.layer.borderWidth = 0
            lastView.backgroundColor = Colors.back_gray
            lastButton.setTitleColor(Colors.dark_gray, for: .normal)
        }
        if let selectedView = view.viewWithTag(tag + 5), let button = view.viewWithTag(tag) as? UIButton {
            selectedView.layer.borderWidth = 1
            selectedView.backgroundColor = Colors.black
            button.setTitleColor(UIColor.white, for: .normal)
        }
        lastGender = tag
    }

    func updateUI() {
        if !imageURL.isEmpty { imageView.imageFromServerURL(urlString: imageURL) }
        nameTextField.text = name
        phoneTextField.text = phone
        emailTextField.text = email
    }
}
