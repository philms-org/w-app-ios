
import UIKit

class LaunchVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let delay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            self.start()
        })
    }
    
    func start() {
        if let _ = UserDefaults.standard.object(forKey: "Start") {
            if let _ = UserDefaults.standard.object(forKey: "Token") {
                openMain()
            } else {
                openWelcome()
            }
        } else {
            openStart()
        }
    }
    
    func openStart() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "FirstStartVC") as? FirstStartVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func openWelcome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func openMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
