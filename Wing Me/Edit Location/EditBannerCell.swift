
import UIKit

class EditBannerCell: UICollectionViewCell {

    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var delegate: BannerDelegate!
    
    func updateCell(item: EditBannerStruct) {
        bannerImageView.image = item.imageView.image
        
        if item.blurred {
            blurView.isHidden = false
            titleLabel.text = item.title
        } else {
            blurView.isHidden = true
        }
    }
    
    @IBAction func editBanner(_ sender: UIButton) {
        delegate.edit(cell: self)
    }
}

struct EditBannerStruct {
    let imageView: UIImageView
    let id: String
    let title: String
    let url: String
    let blurred: Bool
}

protocol BannerDelegate {
    func edit(cell: UICollectionViewCell)
}
