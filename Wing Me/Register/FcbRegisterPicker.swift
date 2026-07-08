
import UIKit

extension FcbRegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func showPicker(button: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) {
            _ in
            picker.allowsEditing = false
            picker.sourceType = .camera
            self.present(picker, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) {
            _ in
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = button
        actionSheet.popoverPresentationController?.sourceRect = button.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        let image = (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage)!
        imageView.image = resizeImage(image: image, pixel: 1080)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, pixel: CGFloat) -> UIImage {
        var scale = CGFloat()
        var newHeight = CGFloat()
        var newWidth = CGFloat()
        
        if image.size.height < image.size.width {
            scale = pixel / image.size.width
            newHeight = image.size.height * scale
            newWidth = pixel
        } else {
            scale = pixel / image.size.height
            newWidth = image.size.width * scale
            newHeight = pixel
        }
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func sendData() {
        registerButton.isHidden = true
        registerIndicator.startAnimating()
        Task {
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
        var avatarURL: String? = nil
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
            display_name: nameTextField.getText(),
            phone: nil,
            gender: getGender(),
            date_of_birth: birthDate,
            avatar_url: avatarURL
        ))
    }

    func openMain() {
        let vc = WAPTabBarVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    func getGender() -> String {
        let genders = ["M", "F", "O"]
        guard lastGender >= 11, lastGender - 11 < genders.count else { return "O" }
        return genders[lastGender - 11]
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
