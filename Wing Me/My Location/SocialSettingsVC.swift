
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
        
        array = Constants.lookingFor
        
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
        let path = "update_emojis.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "dating_Id": String(array[0].progress),
            "socialising_Id": String(array[1].progress),
            "networking_Id": String(array[2].progress)
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        saveButton.isHidden = false
        saveIndicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        appDelegate.inLocation = false
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
