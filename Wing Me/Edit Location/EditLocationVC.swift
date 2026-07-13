
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
        indicator.stopAnimating()
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
        
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            _ = item.id
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
    }

    func save() {
        saveButton.isHidden = false
        saveIndicator.stopAnimating()
        AlertClass().showSuccessAlert(delegate: self, message: Strings.alertLocationInfo) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
