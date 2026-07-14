
import UIKit

class SocialSettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!
    
    var array: [CustomCell] = []
    
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard array.count >= 3 else { return }
        if let index = Int(datingID) {
            array[0].progress = index
        } else {
            array[0].progress = 0
        }
        if let index = Int(socialisingID) {
            array[1].progress = index
        } else {
            array[1].progress = 0
        }
        if let index = Int(networkingID) {
            array[2].progress = index
        } else {
            array[2].progress = 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialSettingsCell", for: indexPath) as! SocialSettingsCell
        cell.delegate = self
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func lexicon(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "LexiconVC") as? LexiconVC {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func save(_ sender: UIButton) {
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        send()
    }
    
    func send() {
        guard let uid = WAPAuth.currentUserID, array.count >= 3 else {
            saveButton.isHidden = false
            saveIndicator.stopAnimating()
            dismiss(animated: true)
            return
        }
        let profile = WAPProfile(id: uid, displayName: "",
                                  datingId: array[0].progress,
                                  socialisingId: array[1].progress,
                                  networkingId: array[2].progress)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPData.shared.upsertProfile(profile)
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
            await MainActor.run {
                self.saveButton.isHidden = false
                self.saveIndicator.stopAnimating()
                self.dismiss(animated: true)
            }
        }
    }
}
