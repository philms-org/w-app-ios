
import UIKit

class MessagesVC: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var groupsTableView: UITableView!
    @IBOutlet weak var noMessagesView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    let messagesRefreshControl = UIRefreshControl()
    let groupsRefreshControl = UIRefreshControl()

    var messagesArray: [CustomCell] = []
    var groupsArray: [CustomCell] = []

    var delegate: MainVC!

    var lastTag = 12

    override func viewDidLoad() {
        super.viewDidLoad()
        noMessagesView.isHidden = true

        setKeyboard()

        messagesRefreshControl.tintColor = Colors.blue
        messagesRefreshControl.addTarget(self, action: #selector(refreshMessages), for: .valueChanged)
        messagesTableView.addSubview(messagesRefreshControl)

        groupsRefreshControl.tintColor = Colors.blue
        groupsRefreshControl.addTarget(self, action: #selector(refreshGroups), for: .valueChanged)
        groupsTableView.addSubview(groupsRefreshControl)

        setTab(tag: 11)
        indicator.stopAnimating()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    func reload() {
        indicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let conversations = try await WAPData.shared.fetchConversations()
                await MainActor.run {
                    self.messagesArray = conversations.filter { !$0.isGroup }.map(self.toCell)
                    self.groupsArray = conversations.filter { $0.isGroup }.map(self.toCell)
                    self.messagesTableView.reloadData()
                    self.groupsTableView.reloadData()
                    self.noMessagesView.isHidden = !(self.lastTag == 11 ? self.messagesArray.isEmpty : self.groupsArray.isEmpty)
                    self.indicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func toCell(_ conversation: WAPConversation) -> CustomCell {
        let imageView = UIImageView()
        if let avatarURL = conversation.otherProfile?.avatarURL, !avatarURL.isEmpty {
            imageView.imageFromServerURL(urlString: avatarURL, tableView: messagesTableView)
        }
        let name = conversation.isGroup ? (conversation.name ?? "Group") : (conversation.otherProfile?.displayName ?? "")
        let statusLabel = conversation.myStatus == "pending" ? "Request" : ""
        return CustomCell(imageView: imageView,
                          string1: conversation.id,
                          string2: name,
                          string3: conversation.lastMessage ?? "",
                          string4: statusLabel,
                          string5: "",
                          string6: "",
                          string7: "",
                          isMaster: false)
    }

    // MARK: - UITableViewDataSource / Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == messagesTableView ? messagesArray.count : groupsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableView == messagesTableView ? messagesArray[indexPath.row] : groupsArray[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            assertionFailure("MessagesVC storyboard cell identifier drifted from \"MessageCell\"")
            return UITableViewCell()
        }
        cell.updateCell(customCell: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = tableView == messagesTableView ? messagesArray[indexPath.row] : groupsArray[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if tableView == messagesTableView, let vc = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            vc.id = item.string1
            navigationController?.pushViewController(vc, animated: true)
        } else if let vc = storyboard.instantiateViewController(withIdentifier: "GroupChatVC") as? GroupChatVC {
            vc.id = item.string1
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }

    // MARK: - IBActions

    @IBAction func sort(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "", message: "Sort by", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Recently Added (Default)", style: .default))
        actionSheet.addAction(UIAlertAction(title: "Oldest to Recent", style: .default))
        actionSheet.addAction(UIAlertAction(title: "Looking For", style: .default))
        actionSheet.addAction(UIAlertAction(title: "Males First", style: .default))
        actionSheet.addAction(UIAlertAction(title: "Females First", style: .default))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true)
    }

    @IBAction func selectTab(_ sender: UIButton) {
        if sender.tag == lastTag { return }
        UIView.animate(withDuration: 0.3) {
            self.setTab(tag: sender.tag)
        }
    }

    @IBAction func shareApp(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [Constants.appURL], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .down
        present(activity, animated: true)
    }

    @objc func refreshMessages() {
        reload()
        messagesRefreshControl.endRefreshing()
    }

    @objc func refreshGroups() {
        reload()
        groupsRefreshControl.endRefreshing()
    }

    func setTab(tag: Int) {
        messagesTableView.isHidden = !(tag == 11)
        groupsTableView.isHidden = !(tag == 12)

        if let lastButton = view.viewWithTag(lastTag) as? UIButton,
           let selectedButton = view.viewWithTag(tag) as? UIButton {
            lastButton.setTitleColor(.white, for: .normal)
            selectedButton.setTitleColor(Colors.blue, for: .normal)
        }
        if let lastView = view.viewWithTag(lastTag + 5),
           let selectedView = view.viewWithTag(tag + 5) {
            lastView.transform = CGAffineTransform(scaleX: 0.001, y: 1)
            selectedView.transform = .identity
        }
        lastTag = tag
    }
}
