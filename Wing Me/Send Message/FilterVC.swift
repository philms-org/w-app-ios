
import UIKit

class FilterVC: UIViewController {
    
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var cityButton: UIButton!
    
    var countiresArray: [String] = []
    var citiesArray: [String] = []
    
    var filter: ((_ country: String, _ city: String, _ gender: Int) -> ())?
    
    var countrySelected = String()
    var citySelected = String()
    var lastGender = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !countrySelected.isEmpty {
            let code = countrySelected
            let country = getCountryName(countryCode: code)
            selectCountry(customCell: CustomCell(string1: code, string2: country))
        }
        if !citySelected.isEmpty {
            selectCity(customCell: CustomCell(string1: citySelected, string2: citySelected))
        }
        selectGender(tag: lastGender)
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func selectGender(_ sender: UIButton) {
        view.endEditing(true)
        
        if (sender.tag == lastGender) {
            return
        }
        selectGender(tag: sender.tag)
    }
    
    @IBAction func selectCountry(_ sender: UIButton) {
        var array: [CustomCell] = []
        
        for each in countiresArray {
            let country = getCountryName(countryCode: each)
            
            array.append(CustomCell(string1: each,
                                    string2: country))
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "PickerVC") as? PickerVC {
            viewController.array = array
            viewController.selectItem = selectCountry
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func selectCity(_ sender: UIButton) {
        var array: [CustomCell] = []
        
        for each in citiesArray {
            array.append(CustomCell(string1: each,
                                    string2: each))
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "PickerVC") as? PickerVC {
            viewController.array = array
            viewController.selectItem = selectCity
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func filter(_ sender: UIButton) {
        filter?(countrySelected, citySelected, lastGender)
        dismiss(animated: true)
    }
    
    func getCountryName(countryCode: String) -> String {
        let current = Locale(identifier: "en_US")
        if let name = current.localizedString(forRegionCode: countryCode) {
            return name
        }
        return ""
    }
    
    func selectGender(tag: Int) {
        if let lastView = view.viewWithTag(lastGender + 5), let lastButton = view.viewWithTag(lastGender) as? UIButton {
            lastView.layer.borderWidth = 0
            lastView.backgroundColor = Colors.back_gray
            lastButton.setTitleColor(Colors.dark_gray, for: .normal)
        }
        if let selectedView = view.viewWithTag(tag + 5), let button = view.viewWithTag(tag) as? UIButton {
            selectedView.layer.borderWidth = 1
            selectedView.backgroundColor = Colors.black
            button.setTitleColor(UIColor.white, for: .normal)
        }
        lastGender = tag
    }
    
    func selectCountry(customCell: CustomCell) {
        countrySelected = customCell.string1
        countryButton.setTitle(customCell.string2, for: .normal)
        countryButton.setTitleColor(UIColor.black, for: .normal)
    }
    
    func selectCity(customCell: CustomCell) {
        citySelected = customCell.string1
        cityButton.setTitle(customCell.string2, for: .normal)
        cityButton.setTitleColor(UIColor.black, for: .normal)
    }
}
