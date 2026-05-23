
import UIKit

class SettingsVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func about(_ sender: UIButton) {
        openAbout(title: Strings.about, path: "about.php")
    }
    
    @IBAction func terms(_ sender: UIButton) {
        openAbout(title: Strings.terms, path: "terms.php")
    }
    
    @IBAction func privacy(_ sender: UIButton) {
        openAbout(title: Strings.privacy, path: "privacy.php")
    }
    
    @IBAction func vast(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "VastVC") as? VastVC {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func blockList(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "BlockListVC") as? BlockListVC {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .up
        present(activity, animated: true, completion: nil)
    }
    
    @IBAction func contact(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ContactVC") as? ContactVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func changePassword(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as? ChangePasswordVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
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
