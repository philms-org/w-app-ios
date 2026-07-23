import UIKit

// Programmatic "Check-in History" screen — pink/gold gradient container with
// a dark-pill list of venues the current user has checked into (most recent
// first). Tapping a row opens WAPHistoryDetailVC for that venue's visit log.
final class WAPHistoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let indicator = UIActivityIndicatorView(style: .large)

    private var venues: [WAPVenue] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
        load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }

    // MARK: - Layout
    private func setupUI() {
        gradientLayer.colors = [
            UIColor(red: 0.93, green: 0.42, blue: 0.63, alpha: 1).cgColor,
            UIColor(red: 0.93, green: 0.72, blue: 0.35, alpha: 1).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientView.layer.addSublayer(gradientLayer)
        gradientView.layer.cornerRadius = 16
        gradientView.clipsToBounds = true
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "History"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "VenueCell")
        tableView.rowHeight = 68
        tableView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.text = "No check-ins yet"
        emptyLabel.textColor = .white
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        indicator.hidesWhenStopped = true
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(gradientView)
        gradientView.addSubview(titleLabel)
        gradientView.addSubview(tableView)
        gradientView.addSubview(emptyLabel)
        gradientView.addSubview(indicator)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            gradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 12),
            tableView.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -12),
            tableView.bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: -12),

            emptyLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),

            indicator.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
        ])
    }

    // MARK: - Data
    private func load() {
        tableView.isHidden = true
        emptyLabel.isHidden = true
        indicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let venues = try await WAPData.shared.fetchLastVisited(limit: 50)
                await MainActor.run {
                    self.venues = venues
                    self.indicator.stopAnimating()
                    self.emptyLabel.isHidden = !venues.isEmpty
                    self.tableView.isHidden = venues.isEmpty
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

    // MARK: - UITableViewDataSource / Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { venues.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VenueCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        let pill = cell.contentView.viewWithTag(501) ?? {
            let container = UIView()
            container.tag = 501
            container.backgroundColor = Colors.back_gray
            container.layer.cornerRadius = 10
            container.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(container)

            let label = UILabel()
            label.tag = 502
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = .lightGray
            chevron.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(chevron)

            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
                container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),

                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),

                chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
            return container
        }()

        (pill.viewWithTag(502) as? UILabel)?.text = venues[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = WAPHistoryDetailVC(venue: venues[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}
