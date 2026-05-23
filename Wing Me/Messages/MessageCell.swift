
import UIKit

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var genderView: ShadowDesignable!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var badgeView: UIViewDesignable!
    
    func updateCell(customCell: CustomCell) {
        userImageView.image = customCell.imageView.image
        nameLabel.text = customCell.string2
        messageLabel.text = customCell.string3
        timeLabel.text = customCell.string4
        
        messageLabel.isHidden = customCell.string3.isEmpty
        
        if customCell.isMaster {
            checkmarkImageView.isHidden = false
            badgeView.isHidden = true
        } else {
            checkmarkImageView.isHidden = true
            badgeView.isHidden = !customCell.isSelected
        }
        if customCell.string7 == "1" {
            genderView.layer.shadowColor = Colors.red.cgColor
        } else {
            if customCell.string5.isEmpty {
                genderView.layer.shadowColor = UIColor.white.cgColor
            } else if customCell.string5 == "F" {
                genderView.layer.shadowColor = Colors.pink.cgColor
            } else {
                genderView.layer.shadowColor = Colors.blue.cgColor
            }
        }
    }
}
