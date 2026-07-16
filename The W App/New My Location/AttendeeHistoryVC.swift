import UIKit

final class AttendeeHistoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let locationId: String
    private let locationName: String

    private let tableView = UITableView()
    private let indicator = UIActivityIndicatorView(style: .medium)
    private var attendees: [WAPProfile] = []
    private var hideSelfEnabled = false
    private var isHidden = false

    init(locationId: String, locationName: String) {
        self.locationId = locationId
        self.locationName = locationName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        title = "\(locationName) — Attendees"
        setupUI()
        Task { await load() }
    }

    private func setupUI() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AttendeeCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false

        [tableView, indicator].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func load() async {
        indicator.startAnimating()
        defer { indicator.stopAnimating() }
        guard let uid = WAPAuth.currentUserID else { return }
        do {
            let venue = try await WAPData.shared.fetchVenue(id: locationId)
            hideSelfEnabled = try await WAPData.shared.resolveFeatureFlag(
                featureName: "attendee_history_hide_self", userId: uid, location: venue
            )
            attendees = try await WAPData.shared.fetchAttendeeHistory(locationId: locationId)
            isHidden = try await WAPData.shared.isOptedOutOfAttendeeHistory(locationId: locationId)
            tableView.reloadData()
        } catch {
            AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
        }
    }

    // own row (hide toggle) + one row per attendee
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        attendees.count + (hideSelfEnabled ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttendeeCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.detailTextLabel?.textColor = UIColor.white.withAlphaComponent(0.5)
        cell.imageView?.layer.cornerRadius = 18
        cell.imageView?.layer.masksToBounds = true
        cell.imageView?.backgroundColor = Colors.back_gray

        if hideSelfEnabled && indexPath.row == 0 {
            cell.textLabel?.text = "Hide me from this venue's history"
            cell.detailTextLabel?.text = isHidden ? "Hidden" : "Visible"
            let toggle = UISwitch()
            toggle.isOn = isHidden
            toggle.addTarget(self, action: #selector(toggleHide(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell
        }

        let attendee = attendees[indexPath.row - (hideSelfEnabled ? 1 : 0)]
        cell.textLabel?.text = attendee.displayName
        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        if let urlString = attendee.avatarURL {
            cell.imageView?.imageFromServerURL(urlString: urlString, tableView: tableView)
        }
        return cell
    }

    @objc private func toggleHide(_ sender: UISwitch) {
        let hidden = sender.isOn
        Task {
            do {
                try await WAPData.shared.setAttendeeHistoryOptOut(locationId: locationId, hidden: hidden)
                isHidden = hidden
            } catch {
                sender.isOn = !hidden
                AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
            }
        }
    }
}
