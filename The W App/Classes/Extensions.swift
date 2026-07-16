
import UIKit

extension UIImageView {
    
    func imageFromServerURLWithoutQueue(urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        URLSession.shared.dataTask(with: url, completionHandler: {
            (data, response, error) in
            self.moveQueue()
            
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self.image = image
            }
        }).resume()
    }
    
    func imageFromServerURL(urlString: String) {
        if let image = Constants.savedImages[urlString] {
            self.image = image
        } else {
            downloadImage(imageView: self, urlString: urlString, reload: {

            })
        }
    }

    func imageFromServerURL(urlString: String, tableView: UITableView) {
        if let image = Constants.savedImages[urlString] {
            self.image = image
        } else {
            downloadImage(imageView: self, urlString: urlString, reload: {
                tableView.reloadData()
            })
        }
    }

    func imageFromServerURL(urlString: String, tableView: UITableView, tint: UIColor) {
        // TODO: Task 6 — replace with Supabase Storage download
    }

    func imageFromServerURL(urlString: String, collectionView: UICollectionView) {
        if let image = Constants.savedImages[urlString] {
            self.image = image
        } else {
            downloadImage(imageView: self, urlString: urlString, reload: {
                collectionView.reloadData()
            })
        }
    }

    func imageFromServerURL(urlString: String, collectionView: UICollectionView, tint: UIColor) {
        // TODO: Task 6 — replace with Supabase Storage download
    }

    func downloadImage(imageView: UIImageView, urlString: String, reload: @escaping () -> ()) {
        // TODO: Task 6 — replace with Supabase Storage download
    }
    
    func moveQueue() {
        Constants.imagesDownloading -= 1
        
        guard let queue = Constants.queueArray.first else {
            return
        }
        Constants.queueArray.removeFirst()
        downloadImage(imageView: queue.imageView, urlString: queue.string1, reload: queue.reload)
    }
    
    func saveImage(urlString: String, image: UIImage?) {
        deleteImages()

        if let image = image {
            Constants.savedImages[urlString] = image
        }
    }
    
    func deleteImages() {
        if Constants.savedImages.count < 300 {
            return
        }
        var count = Int()
        
        for each in Constants.savedImages.keys where count < 100 {
            Constants.savedImages.removeValue(forKey: each)
            count += 1
        }
    }
    
    func decode(codeString: String) {
        let dataDecoded: Data = Data(base64Encoded: codeString, options: .ignoreUnknownCharacters)!
        let decodedimage = UIImage(data: dataDecoded)
        self.image = decodedimage
    }
}

extension UIViewController {
    
    func setKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func setKeyboard(tableView: UITableView) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension Data {
    
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension NSDictionary {
    
    func getString(key: String) -> String {
        if let value = self[key] as? String {
            return value
        } else if let value = self[key] as? Int {
            return String(value)
        }
        return ""
    }
    
    func getDouble(key: String) -> Double {
        if let value = self[key] as? String {
            if let double = Double(value) {
                return double
            }
        } else if let value = self[key] as? Int {
            return Double(value)
        } else if let value = self[key] as? Double {
            return value
        }
        return 0
    }
    
    func getInt(key: String) -> Int {
        if let value = self[key] as? String {
            if let integer = Int(value) {
                return integer
            }
        } else if let value = self[key] as? Double {
            return Int(value)
        } else if let value = self[key] as? Int {
            return value
        }
        return 0
    }
    
    func getBool(key: String) -> Bool {
        if let value = self[key] as? String {
            if value == "1" {
                return true
            }
        } else if let value = self[key] as? Int {
            if value == 1 {
                return true
            }
        } else if let value = self[key] as? Bool {
            return value
        }
        return false
    }
    
    func request(delegate: UIViewController, path: String, stopLoading: @escaping () -> (), requestSuccess: @escaping (_ jsonObject: AnyObject) -> ()) {
        // TODO: Task 6 — replace with Supabase
        stopLoading()
    }
    
    func connectionError(delegate: UIViewController) {
        let alertClass = AlertClass()
        alertClass.showErrorAlert(delegate: delegate, message: Strings.alertConnection)
    }
    
    func requestSuccess(delegate: UIViewController, jsonObject: AnyObject, requestSuccess: @escaping (_ jsonObject: AnyObject) -> ()) {
        if let error = jsonObject["error"] as? String {
            if error == "0" {
                requestSuccess(jsonObject)
            } else if error == "6" {
                if let dictionary = jsonObject as? NSDictionary {
                    // TODO: Task 6 — replace with WAPAuth.signOut()

                    let alertClass = AlertClass()
                    alertClass.showErrorAlert(delegate: delegate, message: dictionary.getString(key: "message"), action: {
                        self.openWelcome(delegate: delegate)
                    })
                }
            } else {
                if let dictionary = jsonObject as? NSDictionary {
                    let alertClass = AlertClass()
                    alertClass.showErrorAlert(delegate: delegate, message: dictionary.getString(key: "message"))
                }
            }
        }
    }
    
    func getPostString(dictionary: NSDictionary) -> String {
        var postString = "laguage=\(Strings.language)"
        
        for (key, value) in dictionary {
            postString += "&\(key)=\(value)"
        }
        return postString
    }
    
    func openWelcome(delegate: UIViewController) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeVC {
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
}

extension Date {
    
    func getDate(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

extension String {
    
    func getDate(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = format
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    func getDate(format: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: self) {
            return date
        }
        return Date()
    }
    
    func fill() -> String {
        if self.isEmpty {
            return "---"
        } else {
            return self
        }
    }
}

extension UITextField {
    
    func getText() -> String {
        return (self.text?.trimmingCharacters(in: .whitespaces))!
    }
    
    func getPhone() -> String {
        let phone = self.getText().replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        return phone
    }
}

extension UITextView {
    
    func getText() -> String {
        return (self.text?.trimmingCharacters(in: .whitespaces))!
    }
}

extension UserDefaults {
    
    static func getString(key: String) -> String {
        if let value = UserDefaults.standard.object(forKey: key) as? String {
            return value
        }
        return ""
    }
}

extension UIApplication {
    
    var currentKeyWindow: UIWindow? {
        return connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }
    }
}
