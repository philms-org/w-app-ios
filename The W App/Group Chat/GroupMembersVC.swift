
import UIKit

class GroupMembersVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    var groupID = String()
    var isAdmin = Bool()
    var membersArray: [WAPProfile] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.startAnimating()
        reload()
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let members = try await WAPData.shared.fetchGroupMembers(conversationId: groupID)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.membersArray = members
                    self.tableView.reloadData()
                    self.indicator.stopAnimating()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { membersArray.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profile = membersArray[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocationPersonCell", for: indexPath) as? LocationPersonCell else {
            assertionFailure("GroupMembersVC storyboard cell identifier drifted from \"LocationPersonCell\"")
            return UITableViewCell()
        }
        let imageView = UIImageView()
        if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
            imageView.imageFromServerURL(urlString: avatarURL, tableView: tableView)
        }
        let customCell = CustomCell(imageView: imageView,
                                     string1: profile.id,
                                     string2: profile.displayName,
                                     string3: "",
                                     string4: "",
                                     string5: "",
                                     string6: "",
                                     string7: "",
                                     isMaster: false)
        cell.updateCell(customCell: customCell)
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
