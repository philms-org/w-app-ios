import UIKit

extension FcbRegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showPicker(sourceView: UIView) {
        let picker = UIImagePickerController()
        picker.delegate = self

        let sheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) { _ in
            picker.sourceType = .camera
            self.present(picker, animated: true)
        })
        sheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        sheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        sheet.popoverPresentationController?.sourceView = sourceView
        sheet.popoverPresentationController?.sourceRect = sourceView.bounds
        present(sheet, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = resizeImage(image: image, pixel: 1080)
            imageView.subviews.forEach { $0.isHidden = true }
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func resizeImage(image: UIImage, pixel: CGFloat) -> UIImage {
        let isLandscape = image.size.width > image.size.height
        let scale: CGFloat = isLandscape ? pixel / image.size.width : pixel / image.size.height
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return result
    }

    func sendData() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await upsertProfile()
                await MainActor.run { self.openMain() }
            } catch {
                await MainActor.run {
                    self.registerButton.isHidden = false
                    self.registerIndicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    private func upsertProfile() async throws {
        guard let uid = WAPAuth.currentUserID else { return }
        var avatarURL: String?

        if let image = imageView.image, let data = image.jpegData(compressionQuality: 0.7) {
            let path = "\(uid)/avatar.jpg"
            try await WAPSupabase.shared.client.storage
                .from("avatars")
                .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))
            let url = try WAPSupabase.shared.client.storage
                .from("avatars").getPublicURL(path: path)
            avatarURL = url.absoluteString
        }

        try await WAPSupabase.shared.upsertRegistrationProfile(WAPRegistrationProfile(
            id: uid,
            display_name: name,
            phone: nil,
            gender: nil,
            date_of_birth: nil,
            avatar_url: avatarURL,
            affiliation: affiliation,
            industry: industry,
            role: role
        ))
    }

    func openMain() {
        let vc = FifthSetupVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
