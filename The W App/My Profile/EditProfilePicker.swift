import UIKit

extension EditProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showPicker(button: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self

        let sheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) { [weak self] _ in
            guard let self else { return }
            picker.sourceType = .camera
            self.present(picker, animated: true)
        })
        sheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) { [weak self] _ in
            guard let self else { return }
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        sheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        sheet.popoverPresentationController?.sourceView = button
        sheet.popoverPresentationController?.sourceRect = button.bounds
        sheet.popoverPresentationController?.permittedArrowDirections = .up
        present(sheet, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        let resized = resizedImage(image, to: CGSize(width: 300, height: 300))
        imageView.image = resized
        pickedImage = resized
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func resizedImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let scale = min(size.width / image.size.width, size.height / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return result
    }
}
