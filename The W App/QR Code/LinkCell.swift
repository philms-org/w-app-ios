
import UIKit

class LinkCell: UICollectionViewCell {

    @IBOutlet weak var linkImageView: UIImageView!

    func configure(method: WAPContactMethod) {
        linkImageView.image = UIImage(named: LinkCell.assetName(for: method.type))
        alpha = method.isEnabled ? 1.0 : 0.3
    }

    // Kept for any remaining callers during transition
    func updateCell(item: LinkStruct) {
        linkImageView.image = item.image
        alpha = 1.0
    }

    static func assetName(for type: String) -> String {
        switch type {
        case "whatsapp":  return "image_whatsapp"
        case "linkedin":  return "image_linkedin"
        case "facebook":  return "image_facebook"
        case "instagram": return "image_instagram"
        case "phone":     return "social_call"
        default:          return "social_website"
        }
    }
}

struct LinkStruct {
    let image: UIImage
    let url: String
}
