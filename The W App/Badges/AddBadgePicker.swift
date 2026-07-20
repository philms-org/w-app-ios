
import UIKit
import UniformTypeIdentifiers

extension AddBadgeVC: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func showPicker(button: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionMyFiles, style: .default) {
            _ in
            self.pickDocument()
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
    
    func pickDocument() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.png], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        if let imageData = try? Data(contentsOf: selectedFileURL), let image = UIImage(data: imageData) {
            imageView.image = resizeImage(image: image, pixel: 50)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        let image = (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage)!
        imageView.image = resizeImage(image: image, pixel: 50)
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
        // Legacy PHP multipart upload removed (dead endpoint, no host configured).
        // No Supabase Storage equivalent exists yet for badge images.
        addButton.isHidden = false
        addIndicator.stopAnimating()
        reloadBadges?()
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertBadgeAdded) {
            self.dismiss(animated: true)
        }
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
