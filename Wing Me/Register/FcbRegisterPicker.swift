
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
        let request: URLRequest
        
        do {
            request = try createRequest()
        } catch {
            sendError()
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            guard let data = data, error == nil else {
                let delay = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: delay, execute: {
                    self.sendError()
                })
                return
            }
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject {
                DispatchQueue.main.async {
                    print(jsonObject)
                    self.sendSuccess(jsonObject: jsonObject)
                }
            } else {
                let responseString = String(data: data, encoding: .utf8)
                print(responseString as AnyObject)
            }
        }
        task.resume()
    }
    
    func sendError() {
        registerButton.isHidden = false
        registerIndicator.stopAnimating()
        
        let alertClass = AlertClass()
        alertClass.showErrorAlert(delegate: self, message: Strings.alertConnection)
    }
    
    func sendSuccess(jsonObject: AnyObject) {
        if let error = jsonObject["error"] as? String {
            if error == "0" {
                if let message = jsonObject["message"] as? NSDictionary {
                    let token = message.getString(key: "token")
                    UserDefaults.standard.set(token, forKey: "Token")
                    
                    openMain()
                }
            } else {
                if let dictionary = jsonObject as? NSDictionary {
                    let alertClass = AlertClass()
                    alertClass.showErrorAlert(delegate: self, message: dictionary.getString(key: "message"))
                }
            }
        }
        registerButton.isHidden = false
        registerIndicator.stopAnimating()
    }
    
    func openMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func createRequest() throws -> URLRequest {
        let parameters: [String: Any] = [
            "language": Strings.language,
            "facebook_Id": id,
            "name": nameTextField.getText(),
            "email": emailTextField.getText(),
            "phone": phoneTextField.getPhone(),
            "gender": getGender(),
            "birth": birthDate,
            "uid": Constants.getUID()
        ]
        
        let boundary = generateBoundaryString()
        let url = URL(string: Constants.url + "sign_up_facebook.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try createBody(with: parameters, boundary: boundary)
        
        if let token = UserDefaults.standard.object(forKey: "Token") as? String {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    func createBody(with parameters: [String: Any], boundary: String) throws -> Data {
        var body = Data()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        if let image = imageView.image, let data = image.jpegData(compressionQuality: 0.5) {
            let mimetype = "image/jpeg"
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpeg\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func getGender() -> String {
        let genders = ["M", "F", "O"]
        return genders[lastGender - 11]
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
