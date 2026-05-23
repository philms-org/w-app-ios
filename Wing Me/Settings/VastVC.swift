
import UIKit

class VastVC: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var facebookView: UIViewDesignable!
    @IBOutlet weak var instagramView: UIViewDesignable!
    @IBOutlet weak var twitterView: UIViewDesignable!
    @IBOutlet weak var whatsappView: UIViewDesignable!
    @IBOutlet weak var phoneView: UIViewDesignable!
    
    var facebookURL = String()
    var instagramURL = String()
    var twitterURL = String()
    var whatsappURL = String()
    var mapsURL = String()
    var phone = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.isHidden = true
        request()
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func facebook(_ sender: UIButton) {
        if let encodedURL = (facebookURL).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    
    @IBAction func instagram(_ sender: UIButton) {
        if let encodedURL = (instagramURL).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    
    @IBAction func twitter(_ sender: UIButton) {
        if let encodedURL = (twitterURL).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    
    @IBAction func whatsapp(_ sender: UIButton) {
        if let encodedURL = (whatsappURL).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    
    @IBAction func phone(_ sender: UIButton) {
        if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func request() {
        let path = "vast.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            textView.text = message.getString(key: "text")
            
            facebookURL = message.getString(key: "facebook")
            instagramURL = message.getString(key: "instagram")
            twitterURL = message.getString(key: "twitter")
            whatsappURL = message.getString(key: "whatsapp")
            phone = message.getString(key: "phone")
            
            facebookView.isHidden = facebookURL.isEmpty
            instagramView.isHidden = instagramURL.isEmpty
            twitterView.isHidden = twitterURL.isEmpty
            whatsappView.isHidden = whatsappURL.isEmpty
            phoneView.isHidden = phone.isEmpty
            
            stackView.isHidden = false
        }
    }
}
