import UIKit

// Detail view for a single venue's visit history — groups the current user's
// own feed posts at that location by calendar day (DATE header rows), each
// followed by that day's feed-style comments.
final class WAPHistoryDetailVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private struct DayGroup {
        let dateLabel: String
        let items: [WAPFeedItem]
    }

    private let venue: WAPVenue
    private let headerView = UIView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let indicator = UIActivityIndicatorView(style: .large)

    private var groups: [DayGroup] = []

    init(venue: WAPVenue) {
        self.venue = venue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
        load()
    }

    // MARK: - Layout
    private func setupUI() {
        headerView.backgroundColor = Colors.back_gray
        headerView.layer.cornerRadius = 12
        headerView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.text = venue.name
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        addressLabel.text = venue.address
        addressLabel.textColor = .lightGray
        addressLabel.font = UIFont.systemFont(ofSize: 13)
        addressLabel.numberOfLines = 0
        addressLabel.isHidden = (venue.address ?? "").isEmpty
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.text = "No activity logged for this venue yet"
        emptyLabel.textColor = .lightGray
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(nameLabel)
        headerView.addSubview(addressLabel)
        [headerView, tableView, emptyLabel, indicator].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            addressLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            addressLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 40),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 40),
        ])
    }

    // MARK: - Data
    private func load() {
        guard let uid = WAPAuth.currentUserID else { return }
        emptyLabel.isHidden = true
        indicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let feed = try await WAPData.shared.fetchFeed(locationId: self.venue.id)
                let mine = feed.filter { $0.userId == uid }
                await MainActor.run {
                    self.groups = Self.groupByDay(mine)
                    self.indicator.stopAnimating()
                    self.emptyLabel.isHidden = !self.groups.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    private static func groupByDay(_ items: [WAPFeedItem]) -> [DayGroup] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MMMM d, yyyy"

        var order: [String] = []
        var buckets: [String: [WAPFeedItem]] = [:]
        for item in items {
            let date = item.createdAt.asDate() ?? Date()
            let key = dayFormatter.string(from: date)
            if buckets[key] == nil {
                buckets[key] = []
                order.append(key)
            }
            buckets[key]?.append(item)
        }
        return order.map { key in DayGroup(dateLabel: key, items: buckets[key] ?? []) }
    }

    // MARK: - UITableViewDataSource / Delegate
    func numberOfSections(in tableView: UITableView) -> Int { groups.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        groups[section].dateLabel
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = Colors.blue
        header.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        header.contentView.backgroundColor = Colors.black
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let item = groups[indexPath.section].items[indexPath.row]

        let container = UIView()
        container.backgroundColor = Colors.back_gray
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        contentLabel.text = item.content
        contentLabel.textColor = .white
        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        let timeLabel = UILabel()
        timeLabel.text = item.createdAt.asMessageTimeDisplay()
        timeLabel.textColor = .lightGray
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(contentLabel)
        container.addSubview(timeLabel)
        cell.contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

            contentLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            contentLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            timeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])
        return cell
    }
}
