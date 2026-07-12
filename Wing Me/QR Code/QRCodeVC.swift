import UIKit
import CoreImage

class QRCodeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        generateAndDisplayQR()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true)
    }

    @IBAction func share(_ sender: UIButton) {
        guard let uid = WAPAuth.currentUserID else { return }
        let url = "openWAPContact://id=\(uid)"
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .up
        present(activity, animated: true, completion: nil)
    }

    private func generateAndDisplayQR() {
        guard let uid = WAPAuth.currentUserID,
              let imageView = view.subviews.first?.subviews.first as? UIImageView else { return }
        imageView.image = qrImage(from: "openWAPContact://id=\(uid)")
        imageView.contentMode = .scaleAspectFit
    }

    private func qrImage(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return UIImage(ciImage: scaled)
    }
}
