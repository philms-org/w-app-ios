
import UIKit

class ChatRightCell: UITableViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        messageLabel.text = customCell.string2
        timeLabel.text = customCell.string3
    }
}
