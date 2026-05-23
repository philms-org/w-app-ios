
import UIKit

class SecondSetupVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
    
    var lastSelected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageLabel.text = "1 / 4"
        
        if let index = Constants.relashionships.firstIndex(where: {
            customCell in
            customCell.string1 == relationship
        }) {
            lastSelected = index
        }
        for (index, each) in Constants.relashionships.enumerated() {
            array.append(CustomCell.init(string1: each.string1, string2: each.string2, isSelected: index == lastSelected))
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelationshipCell", for: indexPath) as! RelationshipCell
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        array[lastSelected].isSelected = false
        array[indexPath.row].isSelected = true
        tableView.reloadData()
        lastSelected = indexPath.row
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
    
    @IBAction func previous(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func next(_ sender: UIButton) {
        let customCell = array[lastSelected]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ThirdSetupVC") as? ThirdSetupVC {
            viewController.regionCode = regionCode
            viewController.city = city
            viewController.nationality = nationality
            viewController.height = height
            viewController.relationship = customCell.string1
            viewController.datingID = datingID
            viewController.socialisingID = socialisingID
            viewController.networkingID = networkingID
            viewController.drink = drink
            viewController.activity = activity
            viewController.profession = profession
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func save() {
        let customCell = array[lastSelected]
        let path = "set_up_profile.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "height": height,
            "relationship": customCell.string1!,
            "dating_Id": datingID,
            "socialising_Id": socialisingID,
            "networking_Id": networkingID,
            "nationality": nationality,
            "city": city,
            "drink": drink,
            "activity": activity,
            "profession": profession
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        backButton.isHidden = false
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
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
