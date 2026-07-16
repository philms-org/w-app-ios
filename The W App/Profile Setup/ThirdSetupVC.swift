
import UIKit

class ThirdSetupVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pageLabel: UILabel!
    
    var array: [CustomCell] = []
    
    var regionCode = String()
    var city = String()
    var nationality = String()
    var height = String()
    var relationship = String()
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    var drink = String()
    var activity = String()
    var profession = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageLabel.text = "2 / 4"

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "LookingForCell", for: indexPath) as! LookingForCell
        cell.delegate = self
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    @IBAction func back(_ sender: UIButton) {
        let alert = UIAlertController(title: Strings.alertWarning, message: Strings.alertSaveProfile, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: Strings.saveChanges, style: .default, handler: {
            _ in
            self.backButton.isHidden = true
            self.indicator.startAnimating()
            self.save()
        }))
        
        alert.addAction(UIAlertAction(title: Strings.discardChanges, style: .destructive, handler: {
            _ in
            self.openMain()
        }))
        
        alert.addAction(UIAlertAction(title: Strings.alertCancel, style: .cancel))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func lexicon(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "LexiconVC") as? LexiconVC {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func previous(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func next(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "FourthSetupVC") as? FourthSetupVC {
            viewController.regionCode = regionCode
            viewController.city = city
            viewController.nationality = nationality
            viewController.height = height
            viewController.relationship = relationship
            viewController.datingID = String(array[0].progress)
            viewController.socialisingID = String(array[1].progress)
            viewController.networkingID = String(array[2].progress)
            viewController.drink = drink
            viewController.activity = activity
            viewController.profession = profession
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func save() {
        backButton.isHidden = false
        indicator.stopAnimating()
        openMain()
    }

    func openMain() {
        appDelegate.inLocation = false
        UserDefaults.standard.set(true, forKey: "Setup")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
