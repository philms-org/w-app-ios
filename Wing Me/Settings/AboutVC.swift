
import UIKit

class AboutVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var titleString = String()
    var path = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleString
        request()
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func request() {
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
        }
    }
}
