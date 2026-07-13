import UIKit

class UserProfileVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var sendView: UIViewDesignable!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    @IBOutlet weak var cityView: UIView!
    @IBOutlet weak var cityLabel: UILabel!

    @IBOutlet weak var nationalityView: UIView!
    @IBOutlet weak var nationalityLabel: UILabel!

    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!

    @IBOutlet weak var heightView: UIView!
    @IBOutlet weak var heightLabel: UILabel!

    @IBOutlet weak var relationshipView: UIView!
    @IBOutlet weak var relationshipLabel: UILabel!

    @IBOutlet weak var drinkView: UIView!
    @IBOutlet weak var drinkLabel: UILabel!

    @IBOutlet weak var fridayActivityView: UIView!
    @IBOutlet weak var fridayActivityLabel: UILabel!

    @IBOutlet weak var professionView: UIView!
    @IBOutlet weak var professionLabel: UILabel!

    var close: (() -> ())?

    var id = String()
    var fromChat = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        request()
    }

    @IBAction func back(_ sender: UIButton) {
        if let reloadMessages = appDelegate.reloadMessages {
            reloadMessages()
        }
        dismiss(animated: true)
    }

    @IBAction func menu(_ sender: UIButton) {
        let sheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Strings.block, style: .destructive) { [weak self] _ in
            self?.blockUser()
        })
        sheet.addAction(UIAlertAction(title: Strings.report, style: .destructive) { [weak self] _ in
            self?.reportUser()
        })
        sheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds
        sheet.popoverPresentationController?.permittedArrowDirections = .up
        present(sheet, animated: true)
    }

    @IBAction func viewImage(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "FullImageVC") as? FullImageVC {
            vc.image = image
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true)
        }
    }

    // MARK: - Data

    func request() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let profile = try await WAPData.shared.fetchProfile(id: self.id)
                await MainActor.run {
                    self.displayProfile(profile)
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    private func displayProfile(_ profile: WAPProfile) {
        nameLabel.text = profile.displayName
        checkmarkImageView.isHidden = !(profile.isVerified ?? false)

        if let url = profile.avatarURL, !url.isEmpty {
            imageView.imageFromServerURL(urlString: url)
        } else {
            imageView.image = UIImage(named: "icon_logo_profile")
        }

        cityView.isHidden = (profile.city ?? "").isEmpty
        cityLabel.text = profile.city ?? ""

        drinkView.isHidden = (profile.faveDrink ?? "").isEmpty
        drinkLabel.text = profile.faveDrink ?? ""

        fridayActivityView.isHidden = (profile.fridayNight ?? "").isEmpty
        fridayActivityLabel.text = profile.fridayNight ?? ""

        professionView.isHidden = (profile.profession ?? "").isEmpty
        professionLabel.text = profile.profession ?? ""

        // Dating-era fields — hide permanently (no WAPProfile equivalent)
        nationalityView.isHidden = true
        heightView.isHidden = true
        relationshipView.isHidden = true
        ageLabel.isHidden = true
        genderLabel.isHidden = true

        indicator.stopAnimating()
        scrollView.isHidden = false
    }

    // MARK: - Block / Report (stubs — no Supabase method yet)

    func blockUser() {
        AlertClass().showWarningAlert(delegate: self, message: "Block is coming soon.", buttonTitle: "OK", action: {})
    }

    func reportUser() {
        AlertClass().showWarningAlert(delegate: self, message: "Report is coming soon.", buttonTitle: "OK", action: {})
    }
}
