
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
    var allSelected = Bool()
    var isMaster = Bool()
    var isOwner = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        allSelectedView.isHidden = true
        sendButton.isEnabled = false
        setKeyboard()
        indicator.stopAnimating()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }

    @IBAction func back(_ sender: UIButton) { dismiss(animated: true) }

    @IBAction func editingChanged(_ sender: UITextField) {
        let s = searchTextField.getText().lowercased()
        usersArray = s.isEmpty ? allArray : allArray.filter { $0.name.lowercased().contains(s) }
        tableView.reloadData()
        updateUI()
        allLabel.text = "Select all (\(usersArray.count))"
    }

    @IBAction func filter(_ sender: UIButton) { }

    @IBAction func selectAllUsers(_ sender: UIButton) {
        allSelected = !allSelected
        for each in usersArray { each.isSelected = allSelected }
        allSelectedView.isHidden = !allSelected
        tableView.reloadData()
        updateUI()
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SendMessageVC") as? SendMessageVC {
            vc.usersArray = usersArray
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }

    func updateUI() {
        let count = usersArray.filter { $0.isSelected }.count
        sendButton.isEnabled = count > 0
        sendButton.setTitle(count == 0 ? "Send a Message" : "Send a Message (\(count))", for: .normal)
    }
}
