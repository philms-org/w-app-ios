
import UIKit

class NotificationVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var array: [CustomCell] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        request()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func request() {
        let path = "get_notification.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            for each in message {
                let insert_at = each.getString(key: "insert_at")
                let date: String = insert_at.getDate(format: "dd MMMM yyyy - hh:mm a")
                
                array.append(CustomCell.init(string1: each.getString(key: "title"),
                                             string2: each.getString(key: "text"),
                                             string3: date))
            }
            tableView.reloadData()
        }
    }
}
