
import UIKit

class AddBannerVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var blurSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var titleTextFIeld: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addIndicator: UIActivityIndicatorView!
    
    var reload: (() -> ())!
    
    var image = UIImage()
    var urlString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        blurView.isHidden = true
        bannerView.isHidden = true
        titleLabel.text = ""
        setKeyboard()
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func blurSwitched(_ sender: UISwitch) {
        if sender.isOn {
            blurView.isHidden = false
            bannerView.isHidden = true
        } else {
            blurView.isHidden = true
            
            if !titleTextFIeld.getText().isEmpty {
                bannerView.isHidden = false
            }
        }
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        titleLabel.text = sender.getText()
        
        if sender.getText().isEmpty || blurSwitch.isOn {
            bannerView.isHidden = true
        } else {
            bannerView.isHidden = false
            bannerLabel.text = sender.getText()
        }
    }
    
    @IBAction func add(_ sender: UIButton) {
        urlString = urlTextField.getText()
        
        if !urlString.isEmpty && !urlString.contains("https://") {
            urlString = "https://" + urlString
        }
        addButton.isHidden = true
        addIndicator.startAnimating()
        sendData()
    }
    
    func sendData() {
        // Legacy PHP multipart upload removed (dead endpoint, no host configured).
        // No Supabase Storage equivalent exists yet for location banners.
        addButton.isHidden = false
        addIndicator.stopAnimating()
        reload()
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertImageAdded) {
            self.dismiss(animated: true)
        }
    }
}
