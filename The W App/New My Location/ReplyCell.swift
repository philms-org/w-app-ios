
import UIKit

class ReplyCell: UITableViewCell {

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var genderView: ShadowDesignable!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    
    var delegate: ReplyDelegate!
    
    func updateCell(item: CommentStruct, isMyComment: Bool) {
        userImageView.image = item.imageView.image
        badgeImageView.image = item.badgeImageView.image
        nameLabel.text = item.name
        badgeLabel.text = item.badgeTitle
        commentLabel.text = item.comment
        likesLabel.text = "\(item.likes)"
        
        detailsLabel.isHidden = false
        
        if item.age.isEmpty {
            if item.city.isEmpty {
                if let emoji = Constants.flags[item.country] {
                    detailsLabel.text = "\(emoji)"
                } else {
                    detailsLabel.isHidden = true
                }
            } else {
                if let emoji = Constants.flags[item.country] {
                    detailsLabel.text = "\(item.city) \(emoji)"
                } else {
                    detailsLabel.text = "\(item.city)"
                }
            }
        } else {
            if item.city.isEmpty {
                if let emoji = Constants.flags[item.country] {
                    detailsLabel.text = "Age: \(item.age) \(emoji)"
                } else {
                    detailsLabel.text = "Age: \(item.age)"
                }
            } else {
                if let emoji = Constants.flags[item.country] {
                    detailsLabel.text = "Age: \(item.age), \(item.city) \(emoji)"
                } else {
                    detailsLabel.text = "Age: \(item.age), \(item.city)"
                }
            }
        }
        if item.gender == "F" {
            genderView.layer.shadowColor = Colors.pink.cgColor
        } else {
            genderView.layer.shadowColor = Colors.blue.cgColor
        }
        if item.isLiked {
            likeButton.setImage(UIImage(named: "icon_heart_full"), for: .normal)
            likeButton.tintColor = Colors.red
        } else {
            likeButton.setImage(UIImage(named: "icon_heart"), for: .normal)
            likeButton.tintColor = UIColor.white
        }
        guard let addButton = addButton else {
            return
        }
        if isMyComment {
            if item.isMyComment {
                addButton.isHidden = true
            } else {
                addButton.isHidden = false
                
                if item.isAdded {
                    addButton.setImage(UIImage(named: "icon_remove"), for: .normal)
                } else {
                    addButton.setImage(UIImage(named: "icon_add"), for: .normal)
                }
            }
        } else {
            addButton.isHidden = true
        }
    }
    
    @IBAction func openProfile(_ sender: UIButton) {
        delegate.openProfile(cell: self)
    }
    
    @IBAction func like(_ sender: UIButton) {
        delegate.like(cell: self)
    }
    
    @IBAction func addGroup(_ sender: UIButton) {
        delegate.add(cell: self)
    }
}

protocol ReplyDelegate {
    func openProfile(cell: UITableViewCell)
    func like(cell: UITableViewCell)
    func add(cell: UITableViewCell)
}
