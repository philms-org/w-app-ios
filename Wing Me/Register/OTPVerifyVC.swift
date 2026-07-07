import UIKit

class OTPVerifyVC: UIViewController {
    var phone = ""
    var name = ""
    var gender = ""
    var birthDate = ""
    var avatarImage: UIImage?

    private let codeField = UITextField()
    private let verifyButton = UIButton(type: .system)
    private let indicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let label = UILabel()
        label.text = "Enter the code sent to \(phone)"
        label.textAlignment = .center
        label.numberOfLines = 0

        codeField.placeholder = "6-digit code"
        codeField.keyboardType = .numberPad
        codeField.textAlignment = .center
        codeField.borderStyle = .roundedRect

        verifyButton.setTitle("Verify", for: .normal)
        verifyButton.addTarget(self, action: #selector(verify), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, codeField, verifyButton, indicator])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
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
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            vc.modalPresentationStyle = .currentContext
            present(vc, animated: true)
        }
    }
}
