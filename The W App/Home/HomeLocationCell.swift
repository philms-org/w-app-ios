
import UIKit

class HomeLocationCell: UITableViewCell {

    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        locationImageView.image = customCell.imageView?.image
        locationLabel.text = customCell.string2
        detailsLabel.text = customCell.string3
    }
}
