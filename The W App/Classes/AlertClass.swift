
import UIKit

class AlertClass {
    
    func showErrorAlert(delegate: UIViewController, message: String) {
        let alert = UIAlertController(title: Strings.alertError, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.alertOK, style: .default, handler: nil))
        delegate.present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert(delegate: UIViewController, message: String, action: @escaping () -> ()) {
        let alert = UIAlertController(title: Strings.alertError, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.alertOK, style: .default, handler: {
            _ in
            action()
        }))
        delegate.present(alert, animated: true, completion: nil)
    }
    
    func showWarningAlert(delegate: UIViewController, message: String) {
        let alert = UIAlertController(title: Strings.alertWarning, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.alertOK, style: .default, handler: nil))
        delegate.present(alert, animated: true, completion: nil)
    }
    
    func showWarningAlert(delegate: UIViewController, message: String, buttonTitle: String, action: @escaping () -> ()) {
        let alert = UIAlertController(title: Strings.alertWarning, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.alertCancel, style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: {
            _ in
            action()
        }))
        delegate.present(alert, animated: true, completion: nil)
    }
    
    func showSuccessAlert(delegate: UIViewController, message: String, action: @escaping () -> ()) {
        let alert = UIAlertController(title: Strings.alertSuccess, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.alertOK, style: .default, handler: {
            _ in
            action()
        }))
        delegate.present(alert, animated: true, completion: nil)
    }
}
