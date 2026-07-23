import UIKit

// Programmatic Profile screen matching the RegisterVC / FifthSetupVC dark+teal
// aesthetic — replaces the legacy storyboard MyProfileVC as the reachable
// profile surface (wired in as a tab in WAPTabBarVC).
final class WAPProfileVC: UIViewController {

    private let scrollView = UIScrollView()
    private let content = UIView()
    private let indicator = UIActivityIndicatorView(style: .large)

    private let avatarImageView = UIImageView()
    private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let cityRow = InfoRow(icon: "building.2", title: "City")
    private let drinkRow = InfoRow(icon: "cup.and.saucer", title: "Fave Drink")
    private let fridayRow = InfoRow(icon: "moon.stars", title: "On Friday Night")
    private let professionRow = InfoRow(icon: "briefcase", title: "Profession")

    private let editProfileButton = WPillButton()
    private let editDetailsButton = WPillButton()
    private let contactsButton = WPillButton()
    private let historyButton = WPillButton()
    private let rewardsButton = WPillButton()
    private let logoutButton = UIButton(type: .system)

    private var profile: WAPProfile?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
        load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Cheap enough to re-fetch each time — keeps edits made elsewhere in sync.
        if profile != nil { load() }
    }

    // MARK: - Layout
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = Colors.back_gray
        avatarImageView.layer.cornerRadius = 56
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = Colors.blue.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        checkmarkImageView.tintColor = Colors.blue
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        [cityRow, drinkRow, fridayRow, professionRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        editProfileButton.setTitle("Edit Profile", for: .normal)
        editProfileButton.applyTealStyle()
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false

        editDetailsButton.setTitle("Edit Details", for: .normal)
        editDetailsButton.addTarget(self, action: #selector(editDetailsTapped), for: .touchUpInside)
        editDetailsButton.translatesAutoresizingMaskIntoConstraints = false

        contactsButton.setTitle("QR / Contacts", for: .normal)
        contactsButton.addTarget(self, action: #selector(contactsTapped), for: .touchUpInside)
        contactsButton.translatesAutoresizingMaskIntoConstraints = false

        historyButton.setTitle("History", for: .normal)
        historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
        historyButton.translatesAutoresizingMaskIntoConstraints = false

        rewardsButton.setTitle("Rewards", for: .normal)
        rewardsButton.addTarget(self, action: #selector(rewardsTapped), for: .touchUpInside)
        rewardsButton.translatesAutoresizingMaskIntoConstraints = false

        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.setTitleColor(Colors.red, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(named: "icon_watermark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)

        [avatarImageView, checkmarkImageView, nameLabel, subtitleLabel,
         cityRow, drinkRow, fridayRow, professionRow,
         editProfileButton, editDetailsButton, contactsButton, historyButton, rewardsButton, logoutButton, logo]
            .forEach { content.addSubview($0) }

        let pad: CGFloat = 24
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            avatarImageView.topAnchor.constraint(equalTo: content.topAnchor, constant: 32),
            avatarImageView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 112),
            avatarImageView.heightAnchor.constraint(equalToConstant: 112),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor, constant: pad),
            nameLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor, constant: -10),

            checkmarkImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            checkmarkImageView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 6),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 18),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 18),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            subtitleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            cityRow.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            cityRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            cityRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            cityRow.heightAnchor.constraint(equalToConstant: 56),

            drinkRow.topAnchor.constraint(equalTo: cityRow.bottomAnchor, constant: 12),
            drinkRow.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            drinkRow.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            drinkRow.heightAnchor.constraint(equalToConstant: 56),

            fridayRow.topAnchor.constraint(equalTo: drinkRow.bottomAnchor, constant: 12),
            fridayRow.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            fridayRow.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            fridayRow.heightAnchor.constraint(equalToConstant: 56),

            professionRow.topAnchor.constraint(equalTo: fridayRow.bottomAnchor, constant: 12),
            professionRow.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            professionRow.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            professionRow.heightAnchor.constraint(equalToConstant: 56),

            editProfileButton.topAnchor.constraint(equalTo: professionRow.bottomAnchor, constant: 32),
            editProfileButton.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            editProfileButton.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            editProfileButton.heightAnchor.constraint(equalToConstant: 52),

            editDetailsButton.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor, constant: 12),
            editDetailsButton.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            editDetailsButton.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            editDetailsButton.heightAnchor.constraint(equalToConstant: 52),

            contactsButton.topAnchor.constraint(equalTo: editDetailsButton.bottomAnchor, constant: 12),
            contactsButton.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            contactsButton.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            contactsButton.heightAnchor.constraint(equalToConstant: 52),

            historyButton.topAnchor.constraint(equalTo: contactsButton.bottomAnchor, constant: 12),
            historyButton.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            historyButton.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            historyButton.heightAnchor.constraint(equalToConstant: 52),

            rewardsButton.topAnchor.constraint(equalTo: historyButton.bottomAnchor, constant: 12),
            rewardsButton.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            rewardsButton.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            rewardsButton.heightAnchor.constraint(equalToConstant: 52),

            logoutButton.topAnchor.constraint(equalTo: rewardsButton.bottomAnchor, constant: 24),
            logoutButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            logo.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 28),
            logo.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 32),
            logo.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Data
    private func load() {
        guard let uid = WAPAuth.currentUserID else { return }
        scrollView.isHidden = true
        indicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let profile = try await WAPData.shared.fetchProfile(id: uid)
                await MainActor.run { self.display(profile) }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    private func display(_ profile: WAPProfile) {
        self.profile = profile

        nameLabel.text = profile.displayName
        checkmarkImageView.isHidden = !(profile.isVerified ?? false)

        let tags = [profile.affiliation?.first, profile.industry?.first, profile.role?.first]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        subtitleLabel.text = tags.isEmpty ? nil : tags.joined(separator: "  ·  ")
        subtitleLabel.isHidden = tags.isEmpty

        if let url = profile.avatarURL, !url.isEmpty {
            avatarImageView.imageFromServerURL(urlString: url)
        } else {
            avatarImageView.image = nil
        }

        cityRow.setValue(profile.city)
        drinkRow.setValue(profile.faveDrink)
        fridayRow.setValue(profile.fridayNight)
        professionRow.setValue(profile.profession)

        indicator.stopAnimating()
        scrollView.isHidden = false
    }

    // MARK: - Actions
    @objc private func editProfileTapped() {
        guard let profile else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "EditProfileVC") as? EditProfileVC else { return }
        vc.imageURL = profile.avatarURL ?? ""
        vc.name = profile.displayName
        vc.phone = profile.phone ?? ""
        vc.email = profile.email ?? ""
        vc.city = profile.city ?? ""
        vc.drink = profile.faveDrink ?? ""
        vc.activity = profile.fridayNight ?? ""
        vc.profession = profile.profession ?? ""
        vc.reloadProfile = { [weak self] in self?.load() }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc private func editDetailsTapped() {
        let vc = FifthSetupVC()
        vc.city = profile?.city
        vc.drink = profile?.faveDrink
        vc.activity = profile?.fridayNight
        vc.profession = profile?.profession
        vc.isEditingExistingProfile = true
        vc.reloadProfile = { [weak self] in self?.load() }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc private func contactsTapped() {
        let vc = WAPContactVC()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func historyTapped() {
        let vc = WAPHistoryVC()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func rewardsTapped() {
        let vc = WAPRewardsVC()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func logoutTapped() {
        AlertClass().showWarningAlert(delegate: self, message: Strings.alertLogout, buttonTitle: Strings.logout) { [weak self] in
            self?.performLogout()
        }
    }

    private func performLogout() {
        Task { [weak self] in
            guard let self else { return }
            await WAPAuth.signOut()
            await MainActor.run { self.goToWelcome() }
        }
    }

    private func goToWelcome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let welcomeVC = storyboard.instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeVC,
              let window = view.window else { return }
        window.rootViewController = welcomeVC
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}

// MARK: - InfoRow

private final class InfoRow: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(icon: String, title: String) {
        super.init(frame: .zero)
        backgroundColor = Colors.back_gray
        layer.cornerRadius = 10

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = Colors.blue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = .lightGray
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.text = "—"
        valueLabel.textColor = .white
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ value: String?) {
        let hasValue = !(value?.isEmpty ?? true)
        isHidden = !hasValue
        valueLabel.text = value
    }
}
