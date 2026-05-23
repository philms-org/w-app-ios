
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
        getCategories()
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
                indicator.startAnimating()
                getBadges(index: indexPath.row)
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
        
        actionSheet.addAction(UIAlertAction(title: "Delete Badge", style: .destructive) {
            _ in
            self.indicator.startAnimating()
            self.deleteBadge(id: item.id)
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
    
    func getCategories() {
        let path = "get_badge_categories.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: categoriesStopLoading, requestSuccess: categoriesSuccess)
    }
    
    func categoriesStopLoading() {
        indicator.stopAnimating()
    }
    
    func categoriesSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            for (index, each) in message.enumerated() {
                categoriesArray.append(BadgeCategoryStruct(id: each.getString(key: "Id"),
                                                           title: each.getString(key: "name"),
                                                           isSelected: index == 0,
                                                           isRequested: false,
                                                           array: []))
                
                if index == 0 {
                    categoriesArray[0].isRequested = true
                    indicator.startAnimating()
                    getBadges(index: 0)
                }
            }
            categoriesCollectionView.reloadData()
            badgesCollectionView.reloadData()
        }
    }
    
    func reload() {
        categoriesArray[lastCategorySelected].array = []
        badgesCollectionView.reloadData()
        
        indicator.startAnimating()
        getBadges(index: lastCategorySelected)
    }
    
    func getBadges(index: Int) {
        let path = "get_badges.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "badges_category_Id": categoriesArray[index].id
        ]
        
        params.request(delegate: self, path: path, stopLoading: badgesStopLoading, requestSuccess: {
            jsonObject in
            self.badgesSuccess(jsonObject: jsonObject, index: index)
        })
    }
    
    func badgesStopLoading() {
        indicator.stopAnimating()
    }
    
    func badgesSuccess(jsonObject: AnyObject, index: Int) {
        if let badges = jsonObject["badges"] as? [NSDictionary] {
            for each in badges {
                let imageView = UIImageView()
                imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                             collectionView: badgesCollectionView,
                                             tint: .white)
                
                categoriesArray[index].array.append(BadgeStruct(imageView: imageView,
                                                                id: each.getString(key: "Id"),
                                                                title: each.getString(key: "title")))
            }
            badgesCollectionView.reloadData()
        }
    }
    
    func deleteBadge(id: String) {
        let path = "delete_badge.php"
        
        let params: NSDictionary = [
            "language": Strings.language,
            "badge_Id": id
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
