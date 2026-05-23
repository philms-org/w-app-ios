
import UIKit

class LocationBannerCell: UICollectionViewCell {
    
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!

    func updateCell(item: BannerStruct) {
        bannerImageView.image = item.imageView.image
        
        if item.blurred {
            blurView.isHidden = false
            titleLabel.text = item.title
        } else {
            blurView.isHidden = true
        }
    }
}

struct BannerStruct {
    let imageView: UIImageView
    let title: String
    let url: String
    let blurred: Bool
}
