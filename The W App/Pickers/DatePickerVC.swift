
import UIKit

class DatePickerVC: UIViewController {

    @IBOutlet weak var mainView: UIViewDesignable!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var selectDate: ((_ date: Date) -> ())!
    
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
    
    @IBAction func save(_ sender: UIButton) {
        let date = datePicker.date
        selectDate(date)
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
