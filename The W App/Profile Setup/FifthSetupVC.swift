import UIKit

class FifthSetupVC: UIViewController, UITextFieldDelegate {

    // Pre-filled when opened from profile edit
    var city:       String?
    var drink:      String?
    var activity:   String?
    var profession: String?

    // MARK: - Fields + eye buttons
    private let cityField       = UITextField()
    private let drinkField      = UITextField()
    private let fridayField     = UITextField()
    private let professionField = UITextField()

    private let cityEye       = UIButton(type: .custom)
    private let drinkEye      = UIButton(type: .custom)
    private let fridayEye     = UIButton(type: .custom)
    private let professionEye = UIButton(type: .custom)

    private var cityVisible       = true
    private var drinkVisible      = true
    private var fridayVisible     = true
    private var professionVisible = true

    private let saveButton    = WPillButton()
    private let saveIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
        cityField.text       = city
        drinkField.text      = drink
        fridayField.text     = activity
        professionField.text = profession
    }

    // MARK: - Layout
    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        let titleLabel = UILabel()
        titleLabel.text = "About You"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Help others connect with you.\nTap the eye icon to control what's visible."
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let cityRow       = makeRow(field: cityField,       eye: cityEye,       placeholder: "City of residence",    tag: 0)
        let drinkRow      = makeRow(field: drinkField,      eye: drinkEye,      placeholder: "Favourite drink",       tag: 1)
        let fridayRow     = makeRow(field: fridayField,     eye: fridayEye,     placeholder: "On friday night I...", tag: 2)
        let profRow       = makeRow(field: professionField, eye: professionEye, placeholder: "Profession / Industry", tag: 3)

        saveButton.setTitle("Save", for: .normal)
        saveButton.applyTealStyle()
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        saveIndicator.color = .white
        saveIndicator.hidesWhenStopped = true
        saveIndicator.translatesAutoresizingMaskIntoConstraints = false

        let skipButton = UIButton(type: .system)
        skipButton.setTitle("Skip for now", for: .normal)
        skipButton.setTitleColor(UIColor.lightGray, for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(named: "icon_watermark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, subtitleLabel,
         cityRow, drinkRow, fridayRow, profRow,
         saveButton, saveIndicator, skipButton, logo].forEach { content.addSubview($0) }

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

            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 48),
            titleLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            subtitleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            cityRow.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            cityRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            cityRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            cityRow.heightAnchor.constraint(equalToConstant: 56),

            drinkRow.topAnchor.constraint(equalTo: cityRow.bottomAnchor, constant: 14),
            drinkRow.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            drinkRow.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            drinkRow.heightAnchor.constraint(equalToConstant: 56),

            fridayRow.topAnchor.constraint(equalTo: drinkRow.bottomAnchor, constant: 14),
            fridayRow.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            fridayRow.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            fridayRow.heightAnchor.constraint(equalToConstant: 56),

            profRow.topAnchor.constraint(equalTo: fridayRow.bottomAnchor, constant: 14),
            profRow.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            profRow.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            profRow.heightAnchor.constraint(equalToConstant: 56),

            saveButton.topAnchor.constraint(equalTo: profRow.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: cityRow.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: cityRow.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 56),

            saveIndicator.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            saveIndicator.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            skipButton.topAnchor.constraint(equalTo: saveIndicator.bottomAnchor, constant: 8),
            skipButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            logo.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 24),
            logo.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 32),
            logo.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
    }

    private func makeRow(field: UITextField, eye: UIButton, placeholder: String, tag: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = Colors.back_gray
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        field.textColor = .white
        field.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        field.backgroundColor = .clear
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false

        eye.tag = tag
        eye.setImage(UIImage(systemName: "eye"), for: .normal)
        eye.tintColor = Colors.blue
        eye.addTarget(self, action: #selector(toggleVisibility(_:)), for: .touchUpInside)
        eye.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(field)
        container.addSubview(eye)
        NSLayoutConstraint.activate([
            eye.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            eye.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            eye.widthAnchor.constraint(equalToConstant: 28),
            eye.heightAnchor.constraint(equalToConstant: 28),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: eye.leadingAnchor, constant: -8),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    // MARK: - Eye toggle
    @objc private func toggleVisibility(_ sender: UIButton) {
        switch sender.tag {
        case 0: cityVisible       = !cityVisible;       sender.setImage(UIImage(systemName: cityVisible       ? "eye" : "eye.slash"), for: .normal)
        case 1: drinkVisible      = !drinkVisible;      sender.setImage(UIImage(systemName: drinkVisible      ? "eye" : "eye.slash"), for: .normal)
        case 2: fridayVisible     = !fridayVisible;     sender.setImage(UIImage(systemName: fridayVisible     ? "eye" : "eye.slash"), for: .normal)
        case 3: professionVisible = !professionVisible; sender.setImage(UIImage(systemName: professionVisible ? "eye" : "eye.slash"), for: .normal)
        default: break
        }
    }

    // MARK: - TextField
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return false
    }

    // MARK: - Actions
    @objc private func save() {
        view.endEditing(true)
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        send()
    }

    @objc private func skip() { openMain() }

    func send() {
        guard let uid = WAPAuth.currentUserID else {
            saveButton.isHidden = false
            saveIndicator.stopAnimating()
            return
        }
        let profile = WAPProfile(
            id: uid,
            displayName: "",
            city:        cityField.getText().isEmpty       ? nil : cityField.getText(),
            faveDrink:   drinkField.getText().isEmpty      ? nil : drinkField.getText(),
            fridayNight: fridayField.getText().isEmpty     ? nil : fridayField.getText(),
            profession:  professionField.getText().isEmpty ? nil : professionField.getText(),
            cityVisible:        cityVisible,
            faveDrinkVisible:   drinkVisible,
            fridayNightVisible: fridayVisible,
            professionVisible:  professionVisible
        )
        Task { [weak self] in
            guard let self else { return }
            do {
                try await WAPData.shared.upsertProfile(profile)
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
            await MainActor.run {
                self.saveButton.isHidden = false
                self.saveIndicator.stopAnimating()
                UserDefaults.standard.set(true, forKey: "Setup")
                self.openMain()
            }
        }
    }

    func openMain() {
        let vc = WAPTabBarVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
