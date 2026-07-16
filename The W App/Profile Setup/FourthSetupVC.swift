
import UIKit

class FourthSetupVC: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pageLabel: UILabel!
    
    var allArray: [CustomCell] = []
    var searchArray: [CustomCell] = []
    
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
        setKeyboard()
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        pageLabel.text = "3 / 4"
        setCountriesArray()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NationalityCell", for: indexPath) as! NationalityCell
        cell.updateCell(customCell: searchArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let index = searchArray.firstIndex(where: {
            customCell in
            customCell.string1 == nationality
        }) {
            searchArray[index].isSelected = false
        }
        searchArray[indexPath.row].isSelected = true
        tableView.reloadData()
        nationality = searchArray[indexPath.row].string1
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
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "FifthSetupVC") as? FifthSetupVC {
            viewController.city = city
            viewController.nationality = nationality
            viewController.height = height
            viewController.relationship = relationship
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
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if searchTextField.getText().isEmpty {
            searchArray = allArray
        } else {
            searchArray = []
            
            for each in allArray {
                if each.string2.lowercased().starts(with: textField.getText().lowercased()) {
                    searchArray.append(each)
                }
            }
        }
        tableView.reloadSections([0], with: .automatic)
    }
    
    func setCountriesArray() {
        var array: [CustomCell] = []
        
        for (key, value) in Constants.flags {
            let name = getCountryName(countryCode: key)
            array.append(CustomCell.init(string1: key, string2: name, string3: value, isSelected: key == nationality))
        }
        allArray = array.sorted {
            customCell1, customCell2 in
            customCell1.isSelected || (customCell1.string2 < customCell2.string2)
        }
        searchArray = allArray
    }
    
    func getCountryName(countryCode: String) -> String {
        let current = Locale(identifier: "en_US")
        if let name = current.localizedString(forRegionCode: countryCode) {
            return name
        }
        return ""
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
