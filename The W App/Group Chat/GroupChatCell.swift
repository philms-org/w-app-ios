
import UIKit

class GroupChatCell: UITableViewCell {

    @IBOutlet weak var messageView: UIViewDesignable!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        userLabel.text = customCell.string2
        messageLabel.text = customCell.string3
        timeLabel.text = customCell.string4
        
        if customCell.string5 == "F" {
            messageView.backgroundColor = Colors.pink
        } else {
            messageView.backgroundColor = Colors.blue
        }
    }
}
