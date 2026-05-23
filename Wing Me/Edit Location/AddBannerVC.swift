
import UIKit

class AddBannerVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var blurSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var titleTextFIeld: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addIndicator: UIActivityIndicatorView!
    
    var reload: (() -> ())!
    
    var image = UIImage()
    var urlString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        blurView.isHidden = true
        bannerView.isHidden = true
        titleLabel.text = ""
        setKeyboard()
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func blurSwitched(_ sender: UISwitch) {
        if sender.isOn {
            blurView.isHidden = false
            bannerView.isHidden = true
        } else {
            blurView.isHidden = true
            
            if !titleTextFIeld.getText().isEmpty {
                bannerView.isHidden = false
            }
        }
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        titleLabel.text = sender.getText()
        
        if sender.getText().isEmpty || blurSwitch.isOn {
            bannerView.isHidden = true
        } else {
            bannerView.isHidden = false
            bannerLabel.text = sender.getText()
        }
    }
    
    @IBAction func add(_ sender: UIButton) {
        urlString = urlTextField.getText()
        
        if !urlString.isEmpty && !urlString.contains("https://") {
            urlString = "https://" + urlString
        }
        addButton.isHidden = true
        addIndicator.startAnimating()
        sendData()
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
        addButton.isHidden = false
        addIndicator.stopAnimating()
        
        let alertClass = AlertClass()
        alertClass.showErrorAlert(delegate: self, message: Strings.alertConnection)
    }
    
    func sendSuccess(jsonObject: AnyObject) {
        if let error = jsonObject["error"] as? String {
            if error == "0" {
                reload()
                
                AlertClass().showSuccessAlert(delegate: self, message: Strings.alertImageAdded) {
                    self.dismiss(animated: true)
                }
            } else {
                if let dictionary = jsonObject as? NSDictionary {
                    let alertClass = AlertClass()
                    alertClass.showErrorAlert(delegate: self, message: dictionary.getString(key: "message"))
                }
            }
        }
        addButton.isHidden = false
        addIndicator.stopAnimating()
    }
    
    func createRequest() throws -> URLRequest {
        let parameters: [String: Any] = [
            "language": Strings.language,
            "title": titleTextFIeld.getText(),
            "url": urlString,
            "blurred": blurSwitch.isOn ? "1" : "0"
        ]
        
        let boundary = generateBoundaryString()
        let url = URL(string: Constants.url + "add_banner_image.php")!
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
        if let data = image.jpegData(compressionQuality: 0.5) {
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
}
