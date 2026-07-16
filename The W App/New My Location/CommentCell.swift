
import UIKit

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    func updateCell(item: CommentStruct) {
        userImageView.image = item.imageView.image
        nameLabel.text = item.name
        
        if item.city.isEmpty {
            detailsLabel.isHidden = true
        } else {
            detailsLabel.isHidden = false
            detailsLabel.text = item.city
        }
        if item.comment.isEmpty {
            commentLabel.text = "Welcome to our venue!"
        } else {
            commentLabel.text = item.comment
        }
    }
}

struct CommentStruct {
    let imageView: UIImageView
    let badgeImageView: UIImageView
    let id: String
    let userID: String
    let name: String
    let age: String
    let gender: String
    let country: String
    let city: String
    let comment: String
    var likes: Int
    let isMyComment: Bool
    var isLiked: Bool
    var isAdded: Bool = false
    let badgeTitle: String
}
