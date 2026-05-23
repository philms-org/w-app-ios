
import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var selectedView: UIViewDesignable!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        categoryLabel.text = customCell.string2
        countLabel.text = "\(customCell.count!)"
        
        if customCell.isSelected {
            selectedView.isHidden = false
            categoryLabel.textColor = UIColor.white
        } else {
            selectedView.isHidden = true
            categoryLabel.textColor = Colors.black
        }
    }
}
