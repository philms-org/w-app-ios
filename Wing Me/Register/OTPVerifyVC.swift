import UIKit

class OTPVerifyVC: UIViewController {
    var phone = ""
    var name = ""
    var gender = ""
    var birthDate = ""
    var avatarImage: UIImage?

    private let codeField = UITextField()
    private let verifyButton = UIButton(type: .custom)
    private let indicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
    }

    private func setupUI() {
        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "Enter the 6-digit code\nsent to \(phone)"
        subtitle.textColor = .white
        subtitle.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        // Code field — dark pill style matching app design
        codeField.placeholder = "_ _ _ _ _ _"
        codeField.attributedPlaceholder = NSAttributedString(
            string: "_ _ _ _ _ _",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        codeField.keyboardType = .numberPad
        codeField.textAlignment = .center
        codeField.textColor = .white
        codeField.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        codeField.backgroundColor = Colors.back_gray
        codeField.layer.cornerRadius = 10
        codeField.layer.masksToBounds = true
        codeField.translatesAutoresizingMaskIntoConstraints = false

        // Verify button — same pill style
        verifyButton.setTitle("Verify", for: .normal)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        verifyButton.backgroundColor = Colors.back_gray
        verifyButton.layer.cornerRadius = 10
        verifyButton.layer.masksToBounds = true
        verifyButton.addTarget(self, action: #selector(verify), for: .touchUpInside)
        verifyButton.translatesAutoresizingMaskIntoConstraints = false

        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true

        // W watermark logo at bottom
        let logo = UIImageView(image: UIImage(named: "icon_watermark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        [subtitle, codeField, verifyButton, indicator, logo].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            subtitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitle.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            subtitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            codeField.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 32),
            codeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            codeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            codeField.heightAnchor.constraint(equalToConstant: 56),

            verifyButton.topAnchor.constraint(equalTo: codeField.bottomAnchor, constant: 16),
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            verifyButton.heightAnchor.constraint(equalToConstant: 56),

            indicator.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 16),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            logo.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    @objc private func verify() {
        guard let code = codeField.text, code.count == 6 else { return }
        verifyButton.isEnabled = false
        indicator.startAnimating()
        Task {
            do {
                try await WAPAuth.verifyOTP(phone: phone, token: code)
                try await upsertProfile()
                await MainActor.run { self.openMain() }
            } catch {
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    private func upsertProfile() async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        var avatarURL: String? = nil
        if let image = avatarImage, let data = image.jpegData(compressionQuality: 0.7) {
            let path = "\(uid)/avatar.jpg"
            try await WAPSupabase.shared.client.storage
                .from("avatars")
                .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))
            let url = try WAPSupabase.shared.client.storage
                .from("avatars").getPublicURL(path: path)
            avatarURL = url.absoluteString
        }
        struct ProfileUpsert: Encodable {
            let id: String
            let display_name: String
            let phone: String
            let gender: String
            let date_of_birth: String
            let avatar_url: String?
        }
        try await WAPSupabase.shared.client
            .from("profiles")
            .upsert(ProfileUpsert(
                id: uid,
                display_name: name,
                phone: phone,
                gender: gender,
                date_of_birth: birthDate,
                avatar_url: avatarURL
            ))
            .execute()
    }

    private func openMain() {
        let vc = WAPTabBarVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
