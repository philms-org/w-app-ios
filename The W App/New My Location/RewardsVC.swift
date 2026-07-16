import UIKit

class RewardsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let locationId: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var rewards: [WAPReward] = []

    init(locationId: String) {
        self.locationId = locationId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHeader()
        setupTableView()
        loadRewards()
    }

    private func setupHeader() {
        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 20)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "Rewards"
        title.font = .boldSystemFont(ofSize: 18)
        title.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(close)
        view.addSubview(title)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            title.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RewardCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadRewards() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await WAPData.shared.fetchRewards(locationId: locationId)
                await MainActor.run {
                    self.rewards = fetched
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rewards.isEmpty ? 1 : rewards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RewardCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        if rewards.isEmpty {
            config.text = "No rewards available at this venue."
            config.textProperties.color = .secondaryLabel
            cell.selectionStyle = .none
        } else {
            let r = rewards[indexPath.row]
            config.text = r.name
            config.secondaryText = r.dealText
            config.image = UIImage(systemName: iconSystemName(for: r.iconType))
        }
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !rewards.isEmpty else { return }
        let r = rewards[indexPath.row]
        let msg = r.instructions ?? r.dealText ?? "No details available."
        let alert = UIAlertController(title: r.name, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func iconSystemName(for iconType: String?) -> String {
        switch iconType {
        case "drink":   return "cup.and.saucer.fill"
        case "food":    return "fork.knife"
        case "ticket":  return "ticket.fill"
        case "percent": return "percent"
        case "vip":     return "star.fill"
        case "valet":   return "car.fill"
        default:        return "gift.fill"
        }
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}
