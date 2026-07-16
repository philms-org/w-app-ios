
import UIKit

class PickerVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var mainView: UIViewDesignable!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var array: [CustomCell] = []
    
    var selectItem: ((_ customCell: CustomCell) -> ())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.transform = CGAffineTransform(translationX: 0, y: mainView.frame.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        UIView.animate(withDuration: 0.3) {
            self.mainView.transform = .identity
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        close()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return array.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return array[row].string2
    }
    
    @IBAction func selectItem(_ sender: UIButton) {
        if array.isEmpty {
            return
        }
        let index = pickerView.selectedRow(inComponent: 0)
        selectItem(array[index])
        close()
    }
    
    func close() {
        UIView.animate(withDuration: 0.2) {
            self.mainView.transform = CGAffineTransform(translationX: 0, y: self.mainView.frame.height)
        } completion: { (_) in
            self.dismiss(animated: true, completion: nil)
        }
    }
}
