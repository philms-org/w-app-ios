import UIKit

class FcbRegisterVC: UIViewController {

    // Passed from RegisterVC
    var name        = String()
    var email       = String()
    var imageURL    = String()
    var affiliation: String?
    var industry:    String?
    var role:        String?

    // UI — accessed by FcbRegisterPicker extension
    let imageView         = UIImageView()
    let registerButton    = WPillButton()
    let registerIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.black
        setupUI()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Add Your Photo"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Let people know who you are"
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = Colors.back_gray
        imageView.layer.cornerRadius = 64
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = Colors.blue.cgColor
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addPicture)))

        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = UIColor.white.withAlphaComponent(0.6)
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(cameraIcon)

        let addPhotoButton = UIButton(type: .system)
        addPhotoButton.setTitle("Tap to add photo", for: .normal)
        addPhotoButton.setTitleColor(Colors.blue, for: .normal)
        addPhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addPhotoButton.addTarget(self, action: #selector(addPicture), for: .touchUpInside)
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false

        registerButton.setTitle("Complete Sign Up", for: .normal)
        registerButton.applyTealStyle()
        registerButton.addTarget(self, action: #selector(register), for: .touchUpInside)
        registerButton.translatesAutoresizingMaskIntoConstraints = false

        registerIndicator.color = .white
        registerIndicator.hidesWhenStopped = true
        registerIndicator.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(named: "icon_watermark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, subtitleLabel, imageView, addPhotoButton,
         registerButton, registerIndicator, logo].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            cameraIcon.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 34),
            cameraIcon.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            imageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 128),
            imageView.heightAnchor.constraint(equalToConstant: 128),

            addPhotoButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            addPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            logo.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 32),

            registerButton.bottomAnchor.constraint(equalTo: logo.topAnchor, constant: -24),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            registerButton.heightAnchor.constraint(equalToConstant: 56),

            registerIndicator.bottomAnchor.constraint(equalTo: registerButton.topAnchor, constant: -12),
            registerIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc func addPicture() {
        showPicker(sourceView: imageView)
    }

    @objc func register(_ sender: UIButton? = nil) {
        guard let image = imageView.image, image.pngData() != nil else {
            AlertClass().showWarningAlert(delegate: self, message: "Please add a profile photo to continue")
            return
        }
        registerButton.isHidden = true
        registerIndicator.startAnimating()
        sendData()
    }
}
