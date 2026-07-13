
import UIKit

class BadgesVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var badgesCollectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var categoriesArray: [BadgeCategoryStruct] = []
    
    var assignBadge: ((_ id: String) -> ())?
    
    var lastCategorySelected = Int()
    
    var isMaster = Bool()
    var isOwner = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.stopAnimating()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == categoriesCollectionView {
            return 1
        } else {
            return 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return categoriesArray.count
        } else {
            if categoriesArray.isEmpty {
                return 0
            } else {
                if section == 0 {
                    let array = categoriesArray[lastCategorySelected].array
                    return array.count
                } else {
                    return 1
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCategoryCell", for: indexPath) as! BadgeCategoryCell
            cell.updateCell(item: categoriesArray[indexPath.row])
            return cell
        } else {
            if indexPath.section == 0 {
                let array = categoriesArray[lastCategorySelected].array
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCell
                cell.updateCell(item: array[indexPath.row])
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeAddCell", for: indexPath) as! BadgeAddCell
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoriesCollectionView {
            let fontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]
            let width = (categoriesArray[indexPath.row].title as NSString).size(withAttributes: fontAttributes).width
            return CGSize(width: width + 40, height: collectionView.frame.height)
        } else {
            return CGSize(width: 80, height: 106)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoriesCollectionView {
            categoriesArray[lastCategorySelected].isSelected = false
            categoriesArray[indexPath.row].isSelected = true
            lastCategorySelected = indexPath.row
            categoriesCollectionView.reloadData()
            badgesCollectionView.reloadData()
            
            categoriesCollectionView.scrollToItem(at: IndexPath(item: indexPath.row, section: 0), at: .centeredHorizontally, animated: true)
            
            if !categoriesArray[indexPath.row].isRequested {
                categoriesArray[indexPath.row].isRequested = true
            }
        } else {
            if indexPath.section == 0 {
                if let assignBadge = assignBadge {
                    let array = categoriesArray[lastCategorySelected].array
                    let item = array[indexPath.row]
                    assignBadge(item.id)
                    dismiss(animated: true)
                } else {
                    if isMaster {
                        showDeleteSheet(indexPath: indexPath)
                    }
                }
            } else {
                openAddBadges()
            }
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func showDeleteSheet(indexPath: IndexPath) {
        guard let cell = badgesCollectionView.cellForItem(at: indexPath) else {
            return
        }
        let item = categoriesArray[lastCategorySelected].array[indexPath.row]
        
        let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Delete Badge", style: .destructive) { [weak self] _ in
            _ = item.id
            _ = self
        })
        
        actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
        
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        present(actionSheet, animated: true, completion: nil)
    }
    
    func openAddBadges() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "AddBadgeVC") as? AddBadgeVC {
            viewController.reloadBadges = reload
            viewController.categoryID = categoriesArray[lastCategorySelected].id
            viewController.modalPresentationStyle = .currentContext
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func reload() {
        guard !categoriesArray.isEmpty else { return }
        categoriesArray[lastCategorySelected].array = []
        badgesCollectionView.reloadData()
    }
}
