
import UIKit

class BlockListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockListCell", for: indexPath) as! BlockListCell
        cell.updateCell(customCell: array[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        let id = array[indexPath.row].string1!
        
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: Strings.unblock, style: .destructive) {
            _ in
            self.unblockUser(id: id)
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func unblockUser(id: String) {
        let alertClass = AlertClass()
        alertClass.showWarningAlert(delegate: self, message: Strings.alertUnblock, buttonTitle: Strings.unblock, action: {
            self.indicator.startAnimating()
            self.unblock(id: id)
        })
    }
    
    func request() {
        let path = "block_list.php"
        
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
                let imageView = UIImageView()
                imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                             tableView: tableView)
                
                array.append(CustomCell.init(imageView: imageView,
                                             string1: each.getString(key: "Id"),
                                             string2: each.getString(key: "name")))
            }
            tableView.reloadData()
        }
    }
    
    func unblock(id: String) {
        let path = "block_user.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "user_Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: unblockStopLoading, requestSuccess: {
            jsonObject in
            self.unblockSuccess(jsonObject: jsonObject, id: id)
        })
    }
    
    func unblockStopLoading() {
        indicator.stopAnimating()
    }
    
    func unblockSuccess(jsonObject: AnyObject, id: String) {
        if let reloadMessages = appDelegate.reloadMessages {
            reloadMessages()
        }
        if let index = array.firstIndex(where: {
            customCell in
            customCell.string1 == id
        }) {
            let indexPath = IndexPath(row: index, section: 0)
            array.remove(at: index)
            tableView.deleteRows(at: [indexPath], with: .right)
        }
    }
}
