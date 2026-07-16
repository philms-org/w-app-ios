
import UIKit

class BadgeCategoryCell: UICollectionViewCell {

    @IBOutlet weak var selectedView: UIViewDesignable!
    @IBOutlet weak var categoryLabel: UILabel!
    
    func updateCell(item: BadgeCategoryStruct) {
        categoryLabel.text = item.title
        
        if item.isSelected {
            selectedView.isHidden = false
            categoryLabel.textColor = UIColor.white
        } else {
            selectedView.isHidden = true
            categoryLabel.textColor = Colors.black
        }
    }
}

struct BadgeCategoryStruct {
    let id: String
    let title: String
    var isSelected: Bool
    var isRequested: Bool
    var array: [BadgeStruct]
}
