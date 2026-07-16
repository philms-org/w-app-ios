
import UIKit

class GenerateUserVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var codeButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var generateIndicator: UIActivityIndicatorView!
    
    var codesArray: [CustomCell] = []
    
    var code = "1"
    var lastGender = Int()
    var birthDate = String()
    
    var isMaster = Bool()
    var isOwner = Bool()
    
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
    
    @IBAction func generate(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !nameTextField.getText().isEmpty && !emailTextField.getText().isEmpty && !phoneTextField.getPhone().isEmpty
                && lastGender != 0 && !birthDate.isEmpty else {
            
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        generateButton.isHidden = true
        generateIndicator.startAnimating()
        generate()
    }
    
    func selectCode(customCell: CustomCell) {
        code = customCell.string1
        codeButton.setTitle("+\(customCell.string1!)", for: .normal)
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
    
    func generate() {
        generateButton.isHidden = false
        generateIndicator.stopAnimating()
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertGenerated) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
