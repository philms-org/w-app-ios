
import UIKit

extension MainVC {
    
    func logout() {
        appDelegate.inLocation = false
        Constants.deleteUserData()
        
        if isLogin {
            dismiss(animated: true)
        } else {
            openWelcome()
        }
    }
    
    func openWelcome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
