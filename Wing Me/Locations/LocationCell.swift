
import UIKit

class LocationCell: UITableViewCell {

    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        locationImageView.image = customCell.imageView.image
        locationLabel.text = customCell.string2
        detailsLabel.text = customCell.string3
        countLabel.text = "\(customCell.count!)"
    }

    func updateCell(venue: WAPVenue) {
        locationLabel.text = venue.name
        detailsLabel.text = venue.address ?? venue.city ?? ""
        countLabel.text = ""
        locationImageView.image = nil
    }
}
