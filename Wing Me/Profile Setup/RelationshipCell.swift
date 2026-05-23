
import UIKit

class RelationshipCell: UITableViewCell {
    
    @IBOutlet weak var selectedView: UIViewDesignable!
    @IBOutlet weak var titleLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        titleLabel.text = customCell.string2
        
        if customCell.isSelected {
            selectedView.backgroundColor = Colors.black
            titleLabel.textColor = UIColor.white
        } else {
            selectedView.backgroundColor = Colors.back_gray
            titleLabel.textColor = UIColor.black
        }
    }
}
