
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
        indicator.stopAnimating()
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
