import UIKit
import CoreImage

// Programmatic "Contact Profile" screen matching the dark+teal design system —
// avatar + small QR (tap for full-screen) + share, bio tags, 2x3 grid of
// contact methods (reuses the existing WAPContactMethod data layer and the
// already-built EditLinksVC / QRCodeVC screens for editing / full-screen QR).
final class WAPContactVC: UIViewController {

    private let scrollView = UIScrollView()
    private let content = UIView()
    private let indicator = UIActivityIndicatorView(style: .large)

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let qrThumbnailButton = UIButton(type: .custom)
    private let shareButton = UIButton(type: .system)
    private let editButton = WPillButton()

    private static let slots: [(type: String, label: String)] = [
        ("whatsapp",  "WhatsApp"),
        ("linkedin",  "LinkedIn"),
        ("facebook",  "Facebook"),
        ("instagram", "Instagram"),
        ("phone",     "Phone"),
        ("link",      "Link"),
    ]
    private var tileButtons: [UIButton] = []
    private var methods: [WAPContactMethod] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
        load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load()
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
        avatarImageView.layer.cornerRadius = 32
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = Colors.blue.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        bioLabel.textColor = .lightGray
        bioLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        bioLabel.numberOfLines = 0
        bioLabel.translatesAutoresizingMaskIntoConstraints = false

        qrThumbnailButton.backgroundColor = Colors.back_gray
        qrThumbnailButton.layer.cornerRadius = 10
        qrThumbnailButton.imageView?.contentMode = .scaleAspectFit
        var qrConfig = UIButton.Configuration.plain()
        qrConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        qrThumbnailButton.configuration = qrConfig
        qrThumbnailButton.addTarget(self, action: #selector(qrTapped), for: .touchUpInside)
        qrThumbnailButton.translatesAutoresizingMaskIntoConstraints = false

        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = Colors.blue
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false

        let gridLabel = UILabel()
        gridLabel.text = "Contact Links"
        gridLabel.textColor = .lightGray
        gridLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        gridLabel.translatesAutoresizingMaskIntoConstraints = false

        let gridStack = makeGrid()
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        editButton.setTitle("Edit Links", for: .normal)
        editButton.applyTealStyle()
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(named: "icon_watermark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)

        [avatarImageView, nameLabel, bioLabel, qrThumbnailButton, shareButton,
         gridLabel, gridStack, editButton, logo].forEach { content.addSubview($0) }

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

            avatarImageView.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            avatarImageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            avatarImageView.widthAnchor.constraint(equalToConstant: 64),
            avatarImageView.heightAnchor.constraint(equalToConstant: 64),

            shareButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            shareButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            shareButton.widthAnchor.constraint(equalToConstant: 28),
            shareButton.heightAnchor.constraint(equalToConstant: 28),

            qrThumbnailButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            qrThumbnailButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -16),
            qrThumbnailButton.widthAnchor.constraint(equalToConstant: 56),
            qrThumbnailButton.heightAnchor.constraint(equalToConstant: 56),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            nameLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            bioLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            bioLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            gridLabel.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 28),
            gridLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),

            gridStack.topAnchor.constraint(equalTo: gridLabel.bottomAnchor, constant: 12),
            gridStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            gridStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            editButton.topAnchor.constraint(equalTo: gridStack.bottomAnchor, constant: 28),
            editButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            editButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            editButton.heightAnchor.constraint(equalToConstant: 52),

            logo.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 28),
            logo.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 32),
            logo.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
    }

    private func makeGrid() -> UIStackView {
        let rows = stride(from: 0, to: WAPContactVC.slots.count, by: 3).map { start -> UIStackView in
            let rowSlots = WAPContactVC.slots[start..<min(start + 3, WAPContactVC.slots.count)]
            let rowButtons = rowSlots.enumerated().map { offset, slot -> UIButton in
                let button = makeTile(index: start + offset, type: slot.type, label: slot.label)
                tileButtons.append(button)
                return button
            }
            let row = UIStackView(arrangedSubviews: rowButtons)
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 12
            return row
        }
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func makeTile(index: Int, type: String, label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.backgroundColor = Colors.back_gray
        button.layer.cornerRadius = 10
        button.setImage(UIImage(named: LinkCell.assetName(for: type)), for: .normal)
        button.setTitle("  \(label)", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
        button.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
        return button
    }

    // MARK: - Data
    private func load() {
        guard let uid = WAPAuth.currentUserID else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                async let profileTask = WAPData.shared.fetchProfile(id: uid)
                async let methodsTask = WAPData.shared.fetchContactMethods(userId: uid)
                let profile = try await profileTask
                let fetched = (try? await methodsTask) ?? []
                await MainActor.run {
                    self.display(profile: profile, methods: fetched, uid: uid)
                }
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    private func display(profile: WAPProfile, methods: [WAPContactMethod], uid: String) {
        nameLabel.text = profile.displayName
        if let url = profile.avatarURL, !url.isEmpty {
            avatarImageView.imageFromServerURL(urlString: url)
        }

        let tags = [profile.profession, profile.affiliation?.first, profile.industry?.first]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        bioLabel.text = tags.isEmpty ? "No bio yet" : tags.joined(separator: "  ·  ")

        self.methods = WAPContactVC.slots.enumerated().map { i, slot in
            methods.first { $0.type == slot.type }
                ?? WAPContactMethod(id: "", userId: uid, slotOrder: i + 1, type: slot.type, value: nil, isEnabled: false)
        }
        for (i, button) in tileButtons.enumerated() where i < self.methods.count {
            button.alpha = self.methods[i].isEnabled ? 1.0 : 0.3
        }

        qrThumbnailButton.setImage(qrImage(from: "openWAPContact://id=\(uid)"), for: .normal)
    }

    private func qrImage(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 4, y: 4))
        return UIImage(ciImage: scaled)
    }

    // MARK: - Actions
    @objc private func tileTapped(_ sender: UIButton) {
        guard sender.tag < methods.count else { return }
        let method = methods[sender.tag]
        guard method.isEnabled, let value = method.value, !value.isEmpty else { return }
        openMethod(type: method.type, value: value)
    }

    private func openMethod(type: String, value: String) {
        let urlString: String
        switch type {
        case "whatsapp":
            urlString = "https://wa.me/\(value.filter { $0.isNumber })"
        case "phone":
            urlString = "tel:\(value.filter { $0.isNumber })"
        case "linkedin":
            urlString = value.hasPrefix("http") ? value : "https://linkedin.com/in/\(value)"
        case "facebook":
            urlString = value.hasPrefix("http") ? value : "https://facebook.com/\(value)"
        case "instagram":
            urlString = value.hasPrefix("http") ? value : "https://instagram.com/\(value)"
        default:
            urlString = value.hasPrefix("http") ? value : "https://\(value)"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func qrTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "QRCodeVC") as? QRCodeVC else { return }
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }

    @objc private func shareTapped() {
        guard let uid = WAPAuth.currentUserID else { return }
        let url = "openWAPContact://id=\(uid)"
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = shareButton
        activity.popoverPresentationController?.sourceRect = shareButton.bounds
        present(activity, animated: true)
    }

    @objc private func editTapped() {
        let vc = EditLinksVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
