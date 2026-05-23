
import UIKit
import SafariServices

class EditLocationVC: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BannerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var whatsappTextField: UITextField!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveIndicator: UIActivityIndicatorView!
    
    let picker = UIImagePickerController()
    let maximumBanner = 5
    
    var bannerArray: [EditBannerStruct] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        bannerView.isHidden = true
        stackView.isHidden = true
        
        setKeyboard()
        request()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return bannerArray.count
        } else {
            if bannerArray.count < maximumBanner {
                return 1
            } else {
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditBannerCell", for: indexPath) as! EditBannerCell
            cell.delegate = self
            cell.updateCell(item: bannerArray[indexPath.row])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddBannerCell", for: indexPath) as! AddBannerCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let item = bannerArray[indexPath.row]
            
            if let encodedURL = (item.url).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                if let url = URL(string: encodedURL) {
                    let config = SFSafariViewController.Configuration()
                    config.entersReaderIfAvailable = true
                    
                    let viewController = SFSafariViewController(url: url, configuration: config)
                    present(viewController, animated: true)
                }
            }
        } else {
            guard let cell = collectionView.cellForItem(at: indexPath) else {
                return
            }
            showPicker(cell: cell)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            let index = Int(collectionView.contentOffset.x/collectionView.frame.width)
            pageControl.currentPage = index
            
            if index > bannerArray.count - 1 {
                return
            }
            let item = bannerArray[index]
            updateUI(item: item)
        }
    }
    
    func edit(cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        let item = bannerArray[indexPath.row]
        
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) {
            _ in
            self.indicator.startAnimating()
            self.delete(id: item.id)
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func save(_ sender: UIButton) {
        saveButton.isHidden = true
        saveIndicator.startAnimating()
        save()
    }
    
    func updateUI(item: EditBannerStruct) {
        if item.blurred || item.title.isEmpty {
            bannerView.isHidden = true
        } else {
            bannerView.isHidden = false
            bannerLabel.text = item.title
        }
    }
    
    func reload() {
        bannerArray = []
        collectionView.reloadData()
        
        stackView.isHidden = true
        indicator.startAnimating()
        request()
    }
    
    func request() {
        let path = "get_my_location_info.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            if let banner = message["banner"] as? [NSDictionary] {
                for (index, each) in banner.enumerated() {
                    let imageView = UIImageView()
                    imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                                 collectionView: collectionView)
                    
                    let item = EditBannerStruct(imageView: imageView,
                                                id: each.getString(key: "Id"),
                                                title: each.getString(key: "title"),
                                                url: each.getString(key: "url"),
                                                blurred: each.getBool(key: "blurred"))
                    
                    if index == 0 {
                        updateUI(item: item)
                    }
                    bannerArray.append(item)
                }
            }
            collectionView.reloadData()
            
            if bannerArray.count == 0 {
                pageControl.numberOfPages = 0
            } else if bannerArray.count < maximumBanner {
                collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
                pageControl.numberOfPages = bannerArray.count + 1
                pageControl.currentPage = 0
            } else {
                collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
                pageControl.numberOfPages = maximumBanner
                pageControl.currentPage = 0
            }
            titleLabel.text = message.getString(key: "name")
            
            messageTextView.text = message.getString(key: "default_message")
            whatsappTextField.text = message.getString(key: "whatsapp")
            addressTextView.text = message.getString(key: "address")
            descriptionView.text = message.getString(key: "description")
            
            stackView.isHidden = false
        }
    }
    
    func save() {
        let path = "edit_my_location.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "default_message": messageTextView.getText(),
            "whatsapp": whatsappTextField.getText(),
            "address": addressTextView.getText(),
            "description": descriptionView.getText()
        ]
        
        params.request(delegate: self, path: path, stopLoading: saveStopLoading, requestSuccess: saveSuccess)
    }
    
    func saveStopLoading() {
        saveButton.isHidden = false
        saveIndicator.stopAnimating()
    }
    
    func saveSuccess(jsonObject: AnyObject) {
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertLocationInfo, action: {
            self.dismiss(animated: true)
        })
    }
    
    func delete(id: String) {
        let path = "delete_banner_image.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "Id": id
        ]
        
        params.request(delegate: self, path: path, stopLoading: deleteStopLoading, requestSuccess: deleteSuccess)
    }
    
    func deleteStopLoading() {
        indicator.stopAnimating()
    }
    
    func deleteSuccess(jsonObject: AnyObject) {
        reload()
    }
}
