
import UIKit

class LinkCell: UICollectionViewCell {
    
    @IBOutlet weak var linkImageView: UIImageView!
    
    func updateCell(item: LinkStruct) {
        linkImageView.image = item.image
    }
}

struct LinkStruct {
    let image: UIImage
    let url: String
}
