
import UIKit

extension EditLocationVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func showPicker(cell: UICollectionViewCell) {
        let actionSheet = UIAlertController(title: Strings.optionTitle, message: Strings.optionDetails, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCamera, style: .default) {
            _ in
            self.picker.allowsEditing = false
            self.picker.sourceType = .camera
            self.present(self.picker, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionGallery, style: .default) {
            _ in
            self.picker.allowsEditing = false
            self.picker.sourceType = .photoLibrary
            self.present(self.picker, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        let image = (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage)!
        
        let delay = DispatchTime.now() + 0.4
        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            let resizedImage = self.resizeImage(image: image, pixel: 800)
            self.openAddBanner(image: resizedImage)
        })
        picker.dismiss(animated: true, completion: nil)
    }
    
    func openAddBanner(image: UIImage) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "AddBannerVC") as? AddBannerVC {
            viewController.reload = reload
            viewController.image = image
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
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
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
