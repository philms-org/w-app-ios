
import UIKit

class SelectUsersVC: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var allLabel: UILabel!
    @IBOutlet weak var allSelectedView: UIViewDesignable!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var allArray: [UserClass] = []
    var usersArray: [UserClass] = []
    var countiresArray: [String] = []
    var citiesArray: [String] = []
    
    var allSelected = Bool()
    var countrySelected = String()
    var citySelected = String()
    var lastGender = Int()
    
    var isMaster = Bool()
    var isOwner = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allSelectedView.isHidden = true
        sendButton.isEnabled = false
        setKeyboard()
        request()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectUserCell", for: indexPath) as! SelectUserCell
        cell.updateCell(item: usersArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = usersArray[indexPath.row]
        item.isSelected = !item.isSelected
        tableView.reloadData()
        
        allSelected = false
        allSelectedView.isHidden = true
        
        updateUI()
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        let searchString = searchTextField.getText().lowercased()
        
        if searchString.isEmpty {
            usersArray = allArray
        } else {
            usersArray = []
            
            for each in allArray {
                if each.name.lowercased().contains(searchString) {
                    usersArray.append(each)
                }
            }
        }
        tableView.reloadSections([0], with: .automatic)
        updateUI()
        
        allLabel.text = "Select all (\(usersArray.count))"
    }
    
    @IBAction func filter(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "FilterVC") as? FilterVC {
            viewController.countiresArray = countiresArray
            viewController.citiesArray = citiesArray
            viewController.filter = filter
            viewController.countrySelected = countrySelected
            viewController.citySelected = citySelected
            viewController.lastGender = lastGender
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func selectAllUsers(_ sender: UIButton) {
        if allSelected {
            allSelected = false
            
            for each in usersArray {
                each.isSelected = false
            }
            allSelectedView.isHidden = true
        } else {
            allSelected = true
            
            for each in usersArray {
                each.isSelected = true
            }
            allSelectedView.isHidden = false
        }
        tableView.reloadData()
        updateUI()
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SendMessageVC") as? SendMessageVC {
            viewController.usersArray = usersArray
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func updateUI() {
        let count = usersArray.filter({
            $0.isSelected
        }).count
        
        if (count == 0) {
            sendButton.isEnabled = false
            sendButton.setTitle("Send a Message", for: .normal)
        } else {
            sendButton.isEnabled = true
            sendButton.setTitle("Send a Message (\(count))", for: .normal)
        }
    }
    
    func filter(countrySelected: String, citySelected: String, lastGender: Int) {
        self.countrySelected = countrySelected
        self.citySelected = citySelected
        self.lastGender = lastGender
        
        print(countrySelected)
        print(citySelected)
        print(lastGender)
        
        usersArray = []
        
        for each in allArray {
            if lastGender == 0 {
                if (countrySelected.isEmpty || each.country.contains(countrySelected)) && (citySelected.isEmpty || each.city.contains(citySelected)) {
                    usersArray.append(each)
                }
            } else {
                let gender = ["M", "F", "O"]
                
                if (countrySelected.isEmpty || each.country.contains(countrySelected)) && (citySelected.isEmpty || each.city.contains(citySelected))
                    && each.gender == gender[lastGender - 11] {
                    
                    usersArray.append(each)
                }
            }
        }
        tableView.reloadData()
        updateUI()
        
        allLabel.text = "Select all (\(usersArray.count))"
    }
    
    func request() {
        var path: String {
            if isMaster {
                return "get_all_users.php"
            } else {
                return "get_users.php"
            }
        }
        
        var locationID: String {
            let locationID = UserDefaults.getString(key: "MyLocationID")
            
            if locationID.contains("Event") {
                return locationID.replacingOccurrences(of: "Event_", with: "")
            } else {
                return locationID
            }
        }
        
        let params: NSDictionary = [
            "language": Strings.language,
            "location_Id": locationID
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            for each in message {
                let imageView = UIImageView()
                imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                             tableView: tableView)
                
                let Id = each.getString(key: "Id")
                
                if Id == "0" {
                    continue
                }
                let country = each.getString(key: "nationality")
                let city = each.getString(key: "city")
                
                let userClass = UserClass(imageView: imageView,
                                          id: Id,
                                          name: each.getString(key: "name"),
                                          age: each.getString(key: "age"),
                                          gender: each.getString(key: "gender"),
                                          country: country,
                                          city: city,
                                          isSelected: false)
                
                allArray.append(userClass)
                usersArray.append(userClass)
                
                if !countiresArray.contains(country) {
                    countiresArray.append(country)
                }
                if !citiesArray.contains(city) {
                    citiesArray.append(city)
                }
                allLabel.text = "Select all (\(usersArray.count))"
            }
            tableView.reloadData()
        }
    }
}
