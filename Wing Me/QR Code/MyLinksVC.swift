
import UIKit

class MyLinksVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    private static let slotTypes = ["whatsapp", "linkedin", "facebook", "instagram", "phone", "link"]

    private var methods: [WAPContactMethod] = MyLinksVC.slotTypes.enumerated().map { i, type in
        WAPContactMethod(id: "", userId: "", slotOrder: i + 1, type: type, value: nil, isEnabled: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fallback if storyboard outlet is not wired
        if collectionView == nil {
            collectionView = view.subviews.flatMap { $0.subviews }
                .compactMap { $0 as? UICollectionView }.first
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMethods()
    }

    private func loadMethods() {
        guard let uid = WAPAuth.currentUserID else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await WAPData.shared.fetchContactMethods(userId: uid)
                await MainActor.run {
                    self.methods = MyLinksVC.slotTypes.enumerated().map { i, type in
                        fetched.first { $0.type == type }
                            ?? WAPContactMethod(id: "", userId: uid,
                                               slotOrder: i + 1, type: type,
                                               value: nil, isEnabled: false)
                    }
                    self.collectionView?.reloadData()
                }
            } catch {
                await MainActor.run {
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
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

    // MARK: - IBActions

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func edit(_ sender: UIButton) {
        let vc = EditLinksVC()
        vc.modalPresentationStyle = .currentContext
        present(vc, animated: true)
    }
}
