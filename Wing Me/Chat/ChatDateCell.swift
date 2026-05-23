
import UIKit

class ChatDateCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        dateLabel.text = customCell.string2
    }
}
