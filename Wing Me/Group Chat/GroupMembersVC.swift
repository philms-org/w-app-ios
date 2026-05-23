
import UIKit

class GroupMembersVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var array: [CustomCell] = []
    
    var groupID = String()
    var isAdmin = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        request()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationPersonCell", for: indexPath) as! LocationPersonCell
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let customCell = array[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as? UserProfileVC {
            viewController.id = customCell.string1
            viewController.close = {
                self.dismiss(animated: true)
            }
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if isAdmin {
            let customCell = array[indexPath.row]
            
            let messageRowAction = UIContextualAction(style: .destructive, title: "Remove Member") {
                (_, _, _) in
                self.indicator.startAnimating()
                self.removeMember(userID: customCell.string1)
            }
            return UISwipeActionsConfiguration(actions: [messageRowAction])
        } else {
            return nil
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func reload() {
        array = []
        tableView.reloadData()
        
        indicator.startAnimating()
        request()
    }
    
    func request() {
        let path = "get_group_users.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": groupID
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            for each in message {
                let image = each.getString(key: "image")
                let name = each.getString(key: "name")
                let dating_Id = each.getString(key: "dating_Id")
                let socialising_Id = each.getString(key: "socialising_Id")
                let networking_Id = each.getString(key: "networking_Id")
                let lookingFor = Constants.getLookingFor(datingID: dating_Id, socialisingID: socialising_Id, networkingID: networking_Id)
                let is_master_account = each.getBool(key: "is_master_account")
                
                let imageView = UIImageView()
                
                if image.isEmpty {
                    imageView.image = UIImage(named: "icon_logo_profile")
                } else {
                    imageView.imageFromServerURL(urlString: image,
                                                 tableView: tableView)
                }
                array.append(CustomCell.init(imageView: imageView,
                                             string1: each.getString(key: "Id"),
                                             string2: name + lookingFor,
                                             string3: each.getString(key: "details"),
                                             string4: each.getString(key: "gender"),
                                             string5: each.getString(key: "age"),
                                             string6: each.getString(key: "city"),
                                             string7: each.getString(key: "nationality"),
                                             isMaster: is_master_account))
            }
            tableView.reloadData()
        }
    }
    
    func removeMember(userID: String) {
        let path = "remove_user_group.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "comment_Id": groupID,
            "user_Id": userID
        ]
        
        params.request(delegate: self, path: path, stopLoading: removeStopLoading, requestSuccess: removeSuccess)
    }
    
    func removeStopLoading() {
        indicator.stopAnimating()
    }
    
    func removeSuccess(jsonObject: AnyObject) {
        reload()
    }
}
