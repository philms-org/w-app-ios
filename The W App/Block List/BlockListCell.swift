
import UIKit

class BlockListCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        userImageView.image = customCell.imageView.image
        nameLabel.text = customCell.string2
    }
}
