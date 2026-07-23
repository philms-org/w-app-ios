import UIKit

// Programmatic Rewards screen for the venue the user is currently checked
// into — banner image, "Rewards" / "Premium" segmented filter, and a 3-column
// grid of reward tiles (locked with a padlock overlay if gated by a feature
// flag the user doesn't have access to). Tapping a tile shows the deal text
// and redemption instructions.
final class WAPRewardsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let bannerImageView = UIImageView()
    private let segmentedControl = UISegmentedControl(items: ["Rewards", "Premium"])
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let emptyLabel = UILabel()
    private let indicator = UIActivityIndicatorView(style: .large)

    private var venue: WAPVenue?
    private var allRewards: [WAPReward] = []
    private var unlockedFeatureNames: Set<String> = []

    private var filteredRewards: [WAPReward] {
        segmentedControl.selectedSegmentIndex == 1
            ? allRewards.filter { $0.featureName != nil }
            : allRewards
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
        load()
    }

    // MARK: - Layout
    private func setupUI() {
        title = "Rewards"

        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerImageView.backgroundColor = Colors.back_gray
        bannerImageView.layer.cornerRadius = 12
        bannerImageView.isHidden = true
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = Colors.blue
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.backgroundColor = Colors.back_gray
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RewardTileCell.self, forCellWithReuseIdentifier: "RewardTile")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.text = "Check in to a venue to see its rewards"
        emptyLabel.textColor = .lightGray
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false

        [bannerImageView, segmentedControl, collectionView, emptyLabel, indicator].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            bannerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bannerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bannerImageView.heightAnchor.constraint(equalToConstant: 140),

            segmentedControl.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Data
    private func load() {
        let locationId = UserDefaults.getString(key: "LocationID")
        guard !locationId.isEmpty else {
            emptyLabel.isHidden = false
            return
        }

        indicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                async let venueTask = WAPData.shared.fetchVenue(id: locationId)
                async let rewardsTask = WAPData.shared.fetchRewards(locationId: locationId)
                let venue = try await venueTask
                let rewards = try await rewardsTask

                var unlocked: Set<String> = []
                for name in Set(rewards.compactMap { $0.featureName }) {
                    if (try? await WAPData.shared.hasFeatureAccess(featureName: name)) == true {
                        unlocked.insert(name)
                    }
                }

                await MainActor.run {
                    self.venue = venue
                    self.allRewards = rewards
                    self.unlockedFeatureNames = unlocked
                    self.indicator.stopAnimating()
                    if let bannerURLString = venue.bannerImage, !bannerURLString.isEmpty {
                        self.bannerImageView.isHidden = false
                        self.bannerImageView.imageFromServerURL(urlString: bannerURLString)
                    }
                    self.emptyLabel.isHidden = !rewards.isEmpty
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func segmentChanged() {
        emptyLabel.isHidden = !filteredRewards.isEmpty
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredRewards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RewardTile", for: indexPath) as? RewardTileCell else {
            return UICollectionViewCell()
        }
        let reward = filteredRewards[indexPath.item]
        let isLocked = reward.featureName.map { !unlockedFeatureNames.contains($0) } ?? false
        cell.configure(reward: reward, isLocked: isLocked)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 3
        let spacing: CGFloat = 12
        let width = (collectionView.bounds.width - spacing * (columns - 1)) / columns
        return CGSize(width: width, height: width + 24)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let reward = filteredRewards[indexPath.item]
        let isLocked = reward.featureName.map { !unlockedFeatureNames.contains($0) } ?? false
        if isLocked {
            AlertClass().showWarningAlert(delegate: self, message: "This reward requires premium access.")
            return
        }
        let message = [reward.dealText, reward.instructions].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n\n")
        AlertClass().showWarningAlert(delegate: self, message: message.isEmpty ? reward.name : message)
    }
}

// MARK: - RewardTileCell

private final class RewardTileCell: UICollectionViewCell {
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let lockOverlay = UIImageView(image: UIImage(systemName: "lock.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Colors.back_gray
        contentView.layer.cornerRadius = 10

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Colors.blue
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        lockOverlay.tintColor = .lightGray
        lockOverlay.contentMode = .scaleAspectFit
        lockOverlay.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lockOverlay)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            lockOverlay.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            lockOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            lockOverlay.widthAnchor.constraint(equalToConstant: 14),
            lockOverlay.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(reward: WAPReward, isLocked: Bool) {
        iconView.image = UIImage(systemName: RewardTileCell.symbolName(for: reward.iconType))
        nameLabel.text = reward.name
        lockOverlay.isHidden = !isLocked
        contentView.alpha = isLocked ? 0.5 : 1.0
    }

    static func symbolName(for iconType: String?) -> String {
        switch iconType {
        case "bogo":     return "2.circle"
        case "ticket":   return "ticket"
        case "discount": return "tag"
        case "confetti": return "party.popper"
        case "percent":  return "percent"
        case "food":     return "fork.knife"
        case "valet":    return "car"
        case "vip":      return "star.circle"
        case "drink":    return "cup.and.saucer"
        default:         return "gift"
        }
    }
}
