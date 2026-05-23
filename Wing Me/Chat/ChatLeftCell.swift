
import UIKit

class ChatLeftCell: UITableViewCell {
    
    @IBOutlet weak var messageView: UIViewDesignable!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func updateCell(customCell: CustomCell, gender: String) {
        messageLabel.text = customCell.string2
        timeLabel.text = customCell.string3
        
        if gender == "F" {
            messageView.backgroundColor = Colors.pink
        } else {
            messageView.backgroundColor = Colors.blue
        }
    }
}
