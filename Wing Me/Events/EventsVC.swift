
import UIKit

class EventsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var eventsArray: [EventStruct] = []
    
    var isMaster = Bool()
    var isOwner = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.stopAnimating()
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
            actionSheet.addAction(UIAlertAction(title: "Disable Event", style: .destructive) { [weak self] _ in
                _ = self
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: "Enable Event", style: .default) { [weak self] _ in
                _ = self
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
    }
}
