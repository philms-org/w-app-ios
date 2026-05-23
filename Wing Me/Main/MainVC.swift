
import UIKit

class MainVC: UIViewController {
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var middleView: ShadowDesignable!
    @IBOutlet weak var messageBadge: UIViewDesignable!
    
    var viewControllers: [UIViewController] = []
    
    var wingMe: ((_ customCell: CustomCell) -> ())!
    var hideLocation: (() -> ())!
    var checkLocation: (() -> ())!
    
    var lastTag = 2
    var isLogin = Bool()
    
    var datingID = String()
    var socialisingID = String()
    var networkingID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageBadge.isHidden = true
        appDelegate.inLocation = false
        appDelegate.getToken()
        
        setVC()
        selectTab(tag: lastTag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        var count = Int()
        
        for each in Constants.savedImages.keys where count < 100 {
            Constants.savedImages.removeValue(forKey: each)
            count += 1
        }
    }
    
    @IBAction func selectTab(_ sender: UIButton) {
        if sender.tag == lastTag {
            return
        }
        if sender.tag == 3 {
            let locationID = UserDefaults.getString(key: "LocationID")
            let locationName = UserDefaults.getString(key: "LocationName")
            
            if locationID.isEmpty && locationName.isEmpty {
                UserDefaults.standard.removeObject(forKey: "LocationID")
                UserDefaults.standard.removeObject(forKey: "LocationName")
                UserDefaults.standard.removeObject(forKey: "LastLocationAlert")
                UserDefaults.standard.removeObject(forKey: "LastLocationNotification")
                checkLocation()
            }
            middleView.ShadowOpacity = 1
        } else {
            middleView.ShadowOpacity = 0
        }
        if sender.tag == 4 {
            messageBadge.isHidden = true
        }
        selectTab(tag: sender.tag)
    }
    
    func selectTab(tag: Int) {
        if let lastButton = view.viewWithTag(lastTag) as? UIButton, let button = view.viewWithTag(tag) as? UIButton {
            lastButton.tintColor = UIColor.white
            button.tintColor = Colors.blue
        }
        let viewController = viewControllers[tag - 1]
        
        UIView.animate(withDuration: 0.2) {
            self.viewControllers[self.lastTag - 1].view.alpha = 0
            viewController.view.alpha = 1
        }
        lastTag = tag
    }
    
    func setVC() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "HomeVC") as? HomeVC {
            viewController.delegate = self
            addVC(viewController: viewController)
        }
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "LocationsVC") as? LocationsVC {
            viewController.delegate = self
            checkLocation = viewController.checkLocation
            addVC(viewController: viewController)
        }
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "NewMyLocationVC") as? NewMyLocationVC {
            viewController.delegate = self
            addVC(viewController: viewController)
        }
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "MessagesVC") as? MessagesVC {
            viewController.delegate = self
            addVC(viewController: viewController)
        }
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "MyProfileVC") as? MyProfileVC {
            viewController.delegate = self
            addVC(viewController: viewController)
        }
    }
    
    func addVC(viewController: UIViewController) {
        viewController.view.alpha = 0
        addChild(viewController)
        view.addSubview(viewController.view)
        view.bringSubviewToFront(bottomView)
        viewControllers.append(viewController)
    }
    
    func showBadge() {
        if lastTag == 4 {
            return
        }
        messageBadge.isHidden = false
    }
}
