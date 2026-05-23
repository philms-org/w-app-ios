
import UIKit
import UniformTypeIdentifiers

extension MyProfileVC: UIDocumentPickerDelegate {
    
    func showActionSheet(button: UIButton) {
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Generate a Single User", style: .default) {
            _ in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "GenerateUserVC") as? GenerateUserVC {
                viewController.isMaster = self.isMaster
                viewController.isOwner = self.isOwner
                viewController.modalPresentationStyle = .currentContext
                self.present(viewController, animated: true, completion: nil)
            }
        })
        
        actionSheet.addAction(UIAlertAction(title: "Select CSV File", style: .default) {
            _ in
            self.pickDocument()
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = button
        actionSheet.popoverPresentationController?.sourceRect = button.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    func pickDocument() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        readCSVFile(from: selectedFileURL)
    }
    
    func readCSVFile(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            var lines = content.components(separatedBy: "\n").map {
                $0.components(separatedBy: ",")
            }
            let first = lines[0]
            
            guard first[0].contains("Name") && first[1].contains("Email") && first[2].contains("Phone Number")
                    && first[3].contains("Date of Birth (dd/MM/yyyy)") && first[4].contains("Gender (M/F)") else {
                
                AlertClass().showErrorAlert(delegate: self, message: "Wrong CSV format!")
                return
            }
            generateArray = []
            
            lines.remove(at: 0)
            
            for (index, each) in lines.enumerated() {
                let name = each[0]
                let email = each[1]
                let phone = each[2]
                let birth = each[3]
                let gender = each[4].replacingOccurrences(of: "\r", with: "")
                
                if name.isEmpty || email.isEmpty || phone.isEmpty || birth.isEmpty || gender.isEmpty {
                    AlertClass().showErrorAlert(delegate: self, message: "Error reading CSV file line \(index + 1)")
                    return
                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                
                if let date = dateFormatter.date(from: birth) {
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: date)
                    
                    let dictionary: NSDictionary = [
                        "name": name,
                        "email": email,
                        "phone": phone,
                        "date_of_birth": dateString,
                        "gender": gender
                    ]
                    
                    generateArray.append(dictionary)
                } else {
                    AlertClass().showErrorAlert(delegate: self, message: "Wrong date format line \(index + 1)")
                    return
                }
            }
            if generateArray.isEmpty {
                AlertClass().showErrorAlert(delegate: self, message: "CSV file is empty")
                return
            }
            AlertClass().showWarningAlert(delegate: self, message: Strings.alertGenerate, buttonTitle: "Generate") {
                self.generateUsersButton.isHidden = true
                self.generateUsersIndicator.startAnimating()
                self.generate()
            }
        } catch {
            AlertClass().showErrorAlert(delegate: self, message: "Error reading CSV file: \(error)")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("User cancelled document picker")
    }
    
    func generate() {
        var path: String {
            if isMaster {
                return "generate_users.php"
            } else {
                return "generate_location_users.php"
            }
        }
        
        let data = try? JSONSerialization.data(withJSONObject: generateArray)
        let jsonObject = String(data: data!, encoding: .utf8)!
        
        let params: NSDictionary = [
            "language": Strings.language,
            "users": jsonObject
        ]
        
        params.request(delegate: self, path: path, stopLoading: generateStopLoading, requestSuccess: generateSuccess)
    }
    
    func generateStopLoading() {
        generateUsersButton.isHidden = false
        generateUsersIndicator.stopAnimating()
    }
    
    func generateSuccess(jsonObject: AnyObject) {
        let alertClass = AlertClass()
        alertClass.showSuccessAlert(delegate: self, message: Strings.alertGenerated, action: {
            
        })
    }
}
