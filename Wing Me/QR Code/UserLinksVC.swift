import UIKit

class UserLinksVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    var id = String()   // user UUID passed from AppDelegate deep link

    private var methods: [WAPContactMethod] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        if collectionView == nil {
            collectionView = view.subviews.flatMap { $0.subviews }
                .compactMap { $0 as? UICollectionView }.first
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !id.isEmpty else { return }
        loadMethods()
    }

    private func loadMethods() {
        Task { @MainActor in
            do {
                let fetched = try await WAPData.shared.fetchContactMethods(userId: id)
                methods = fetched.filter { $0.isEnabled && !($0.value ?? "").isEmpty }
                collectionView?.reloadData()
            } catch {
                AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        methods.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LinkCell", for: indexPath) as! LinkCell
        cell.configure(method: methods[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = collectionView.frame.width / 3
        return CGSize(width: side, height: side)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let method = methods[indexPath.row]
        guard let value = method.value, !value.isEmpty else { return }
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

    // MARK: - IBActions

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func share(_ sender: UIButton) {
        guard !id.isEmpty else { return }
        let url = "openWAPContact://id=\(id)"
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .up
        present(activity, animated: true, completion: nil)
    }
}
