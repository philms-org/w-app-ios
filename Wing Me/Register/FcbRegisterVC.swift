
import UIKit

class FcbRegisterVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var registerIndicator: UIActivityIndicatorView!
    
    var id = String()
    var name = String()
    var email = String()
    var imageURL = String()
    var lastGender = Int()
    var birthDate = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        updateUI()
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
        
        if (sender.tag == lastGender) {
            return
        }
        if let lastView = view.viewWithTag(lastGender + 5), let lastButton = view.viewWithTag(lastGender) as? UIButton {
            lastView.layer.borderWidth = 0
            lastView.backgroundColor = Colors.back_gray
            lastButton.setTitleColor(Colors.dark_gray, for: .normal)
        }
        if let selectedView = view.viewWithTag(sender.tag + 5) {
            selectedView.layer.borderWidth = 1
            selectedView.backgroundColor = Colors.black
            sender.setTitleColor(UIColor.white, for: .normal)
        }
        lastGender = sender.tag
    }
    
    @IBAction func selectBithDate(_ sender: Any) {
        view.endEditing(true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "DatePickerVC") as? DatePickerVC {
            viewController.selectDate = {
                date in
                self.selectDate(date: date)
            }
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func selectDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        birthDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "dd MMMM yyyy"
        let dateString = dateFormatter.string(from: date)
        dateButton.setTitle(dateString, for: .normal)
        dateButton.setTitleColor(UIColor.black, for: .normal)
    }
    
    @IBAction func register(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !nameTextField.getText().isEmpty && lastGender != 0 && !birthDate.isEmpty, let image = imageView.image, let _ = image.pngData() else {
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        registerButton.isHidden = true
        registerIndicator.startAnimating()
        sendData()
    }
    
    func updateUI() {
        nameTextField.text = name
        emailTextField.text = email
        imageView.imageFromServerURLWithoutQueue(urlString: imageURL)
    }
}
