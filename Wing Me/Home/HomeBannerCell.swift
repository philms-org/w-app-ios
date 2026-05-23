
import UIKit

class HomeBannerCell: UICollectionViewCell {

    @IBOutlet weak var bannerImageView: UIImageView!
    
    func updateCell(customCell: CustomCell) {
        bannerImageView.image = customCell.imageView.image
    }
}
