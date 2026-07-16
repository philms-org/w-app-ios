
import UIKit

class FullImageVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var image = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true)
    }
}
