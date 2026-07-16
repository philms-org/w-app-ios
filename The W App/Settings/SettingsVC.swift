
import UIKit

class SettingsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func about(_ sender: UIButton) {
        openURL(Constants.aboutURL)
    }

    @IBAction func terms(_ sender: UIButton) {
        openURL(Constants.termsURL)
    }

    @IBAction func privacy(_ sender: UIButton) {
        openURL(Constants.privacyURL)
    }

    @IBAction func vast(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VastVC") as? VastVC {
            present(vc, animated: true)
        }
    }

    @IBAction func blockList(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BlockListVC") as? BlockListVC {
            present(vc, animated: true)
        }
    }

    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .up
        present(activity, animated: true)
    }

    @IBAction func contact(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ContactVC") as? ContactVC {
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }

    @IBAction func changePassword(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as? ChangePasswordVC {
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url, options: [:])
    }
}
