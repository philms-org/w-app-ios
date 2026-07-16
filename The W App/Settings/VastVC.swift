
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
        indicator.stopAnimating()
        stackView.isHidden = true
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func facebook(_ sender: UIButton) {
        guard !facebookURL.isEmpty, let url = URL(string: facebookURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func instagram(_ sender: UIButton) {
        guard !instagramURL.isEmpty, let url = URL(string: instagramURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func twitter(_ sender: UIButton) {
        guard !twitterURL.isEmpty, let url = URL(string: twitterURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func whatsapp(_ sender: UIButton) {
        guard !whatsappURL.isEmpty, let url = URL(string: whatsappURL) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @IBAction func phone(_ sender: UIButton) {
        guard !phone.isEmpty, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
