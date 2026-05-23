
import UIKit

class NationalityCell: UITableViewCell {

    @IBOutlet weak var selectedView: UIViewDesignable!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emojiLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        titleLabel.text = customCell.string2
        emojiLabel.text = customCell.string3
        
        if customCell.isSelected {
            selectedView.layer.borderWidth = 1
            selectedView.backgroundColor = Colors.black
            titleLabel.textColor = UIColor.white
        } else {
            selectedView.layer.borderWidth = 0
            selectedView.backgroundColor = Colors.back_gray
            titleLabel.textColor = Colors.dark_gray
        }
    }
}
