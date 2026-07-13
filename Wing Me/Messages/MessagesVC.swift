
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    // MARK: - UITableViewDataSource / Delegate stubs

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }

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
        messagesRefreshControl.endRefreshing()
    }

    @objc func refreshGroups() {
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
