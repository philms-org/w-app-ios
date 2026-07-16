
import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textlabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        titleLabel.text = customCell.string1
        textlabel.text = customCell.string2
        timeLabel.text = customCell.string3
    }
}
