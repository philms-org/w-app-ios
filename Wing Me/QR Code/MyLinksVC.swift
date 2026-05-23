
import UIKit

class MyLinksVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let array = [
        LinkStruct(image: UIImage(named: "social_email")!, url: ""),
        LinkStruct(image: UIImage(named: "social_website")!, url: ""),
        LinkStruct(image: UIImage(named: "social_call")!, url: ""),
        LinkStruct(image: UIImage(named: "image_facebook")!, url: ""),
        LinkStruct(image: UIImage(named: "image_instagram")!, url: ""),
        LinkStruct(image: UIImage(named: "image_whatsapp")!, url: ""),
        LinkStruct(image: UIImage(named: "image_twitter")!, url: ""),
        LinkStruct(image: UIImage(named: "image_linkedin")!, url: "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LinkCell", for: indexPath) as! LinkCell
        cell.updateCell(item: array[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/3, height: collectionView.frame.width/3)
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func edit(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "EditLinksVC") as? EditLinksVC {
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
}
