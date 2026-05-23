
import UIKit

class CreateEventVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextView: UITextView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var createIndicator: UIActivityIndicatorView!
    
    var reloadEvents: (() -> ())?
    
    var isMaster = Bool()
    var isOwner = Bool()
    var startDate = String()
    var endDate = String()
    
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
    
    @IBAction func addImage(_ sender: UIButton) {
        showPicker(button: sender)
    }
    
    @IBAction func startDate(_ sender: UIButton) {
        view.endEditing(true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "DatePickerVC") as? DatePickerVC {
            viewController.selectDate = {
                date in
                self.selectStartDate(date: date)
            }
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func endDate(_ sender: UIButton) {
        view.endEditing(true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "DatePickerVC") as? DatePickerVC {
            viewController.selectDate = {
                date in
                self.selectEndDate(date: date)
            }
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func create(_ sender: UIButton) {
        view.endEditing(true)
        
        guard !titleTextField.getText().isEmpty && !detailsTextView.getText().isEmpty && !startDate.isEmpty && !startDate.isEmpty,
              let image = imageView.image, let _ = image.pngData() else {
            
            let alertClass = AlertClass()
            alertClass.showWarningAlert(delegate: self, message: Strings.alertEmpty)
            return
        }
        createButton.isHidden = true
        createIndicator.startAnimating()
        sendData()
    }
    
    func selectStartDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd 00:00:00"
        startDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "dd MMMM yyyy - 00:00"
        let dateString = dateFormatter.string(from: date)
        startButton.setTitle(dateString, for: .normal)
        startButton.setTitleColor(UIColor.black, for: .normal)
    }
    
    func selectEndDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd 23:59:59"
        endDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "dd MMMM yyyy - 23:59"
        let dateString = dateFormatter.string(from: date)
        endButton.setTitle(dateString, for: .normal)
        endButton.setTitleColor(UIColor.black, for: .normal)
    }
}
