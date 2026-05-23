
import UIKit

class EventsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var eventsArray: [EventStruct] = []
    
    var isMaster = Bool()
    var isOwner = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        request()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        cell.updateCell(item: eventsArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let width = tableView.frame.width - 40
        let height = width * 1/2 + 20
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        let item = eventsArray[indexPath.row]
        
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Edit Event", style: .default) {
            _ in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "EditEventVC") as? EditEventVC {
                viewController.reloadEvents = self.reload
                viewController.event = item
                viewController.isMaster = self.isMaster
                viewController.isOwner = self.isOwner
                viewController.modalPresentationStyle = .currentContext
                self.present(viewController, animated: true, completion: nil)
            }
        })
        
        if item.status == "Active" {
            actionSheet.addAction(UIAlertAction(title: "Disable Event", style: .destructive) {
                _ in
                self.indicator.startAnimating()
                self.changeStatus(index: indexPath.row, status: "Inactive")
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: "Enable Event", style: .default) {
                _ in
                self.indicator.startAnimating()
                self.changeStatus(index: indexPath.row, status: "Active")
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func add(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "CreateEventVC") as? CreateEventVC {
            viewController.reloadEvents = reload
            viewController.isMaster = isMaster
            viewController.isOwner = isOwner
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func reload() {
        eventsArray = []
        tableView.reloadData()
        
        indicator.startAnimating()
        request()
    }
    
    func request() {
        var path: String {
            if isMaster {
                return "master_get_events.php"
            } else {
                return "get_my_events.php"
            }
        }
        
        let params: NSDictionary = [
            "language": Strings.language,
            "LIMIT": 100,
            "OFFSET": 0
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
                imageView.imageFromServerURL(urlString: each.getString(key: "image_path"),
                                             tableView: tableView)
                
                let start_date = each.getString(key: "start_date")
                let end_date = each.getString(key: "end_date")
                
                var startDate = ""
                var endDate = ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                if let date = dateFormatter.date(from: start_date) {
                    dateFormatter.dateFormat = "EEEE dd MMM yyyy"
                    startDate = dateFormatter.string(from: date)
                }
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                if let date = dateFormatter.date(from: end_date) {
                    dateFormatter.dateFormat = "EEEE dd MMM yyyy"
                    endDate = dateFormatter.string(from: date)
                }
                eventsArray.append(EventStruct(imageView: imageView,
                                               id: each.getString(key: "Id"),
                                               title: each.getString(key: "title"),
                                               details: each.getString(key: "description"),
                                               startDate: startDate,
                                               endDate: endDate,
                                               status: each.getString(key: "status")))
            }
            tableView.reloadData()
        }
    }
    
    func changeStatus(index: Int, status: String) {
        let path = "enable_disable_event.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "Id": eventsArray[index].id,
            "status": status
        ]
        
        params.request(delegate: self, path: path, stopLoading: changeStopLoading, requestSuccess: {
            jsonObject in
            self.changeSuccess(jsonObject: jsonObject, index: index, status: status)
        })
    }
    
    func changeStopLoading() {
        indicator.stopAnimating()
    }
    
    func changeSuccess(jsonObject: AnyObject, index: Int, status: String) {
        eventsArray[index].status = status
        tableView.reloadData()
    }
}
