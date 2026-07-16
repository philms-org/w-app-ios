
import UIKit

class WelcomeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func register(_ sender: UIButton) {
        let viewController = RegisterVC()
        viewController.modalPresentationStyle = .currentContext
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func login(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func privacy(_ sender: UIButton) {
        openAbout(title: Strings.privacy, path: "privacy.php")
    }
    
    func openAbout(title: String, path: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "AboutVC") as? AboutVC {
            viewController.titleString = title
            viewController.path = path
            present(viewController, animated: true, completion: nil)
        }
    }
}
