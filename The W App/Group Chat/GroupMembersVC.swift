
import UIKit

class GroupMembersVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    var groupID = String()
    var isAdmin = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.stopAnimating()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
