
import UIKit

class BadgeCell: UICollectionViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func updateCell(item: BadgeStruct) {
        badgeImageView.image = item.imageView.image
        titleLabel.text = item.title
    }
}

struct BadgeStruct {
    let imageView: UIImageView
    let id: String
    let title: String
}
