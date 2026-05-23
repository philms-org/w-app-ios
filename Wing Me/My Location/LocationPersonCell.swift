
import UIKit

class LocationPersonCell: UITableViewCell {
    
    @IBOutlet weak var genderView: ShadowDesignable!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var namelabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    
    func updateCell(customCell: CustomCell) {
        userImageView.image = customCell.imageView.image
        namelabel.text = customCell.string2
        
        if customCell.isMaster {
            checkmarkImageView.isHidden = false
            detailsLabel.isHidden = true
        } else {
            checkmarkImageView.isHidden = true
            detailsLabel.isHidden = false
            
            let nationality = customCell.string7!
            let city = customCell.string6!
            let age = customCell.string5!
            
            if age.isEmpty {
                if city.isEmpty {
                    if let emoji = Constants.flags[nationality] {
                        detailsLabel.text = "\(emoji)"
                    } else {
                        detailsLabel.isHidden = true
                    }
                } else {
                    if let emoji = Constants.flags[nationality] {
                        detailsLabel.text = "\(city) \(emoji)"
                    } else {
                        detailsLabel.text = "\(city)"
                    }
                }
            } else {
                if city.isEmpty {
                    if let emoji = Constants.flags[nationality] {
                        detailsLabel.text = "Age: \(age) \(emoji)"
                    } else {
                        detailsLabel.text = "Age: \(age)"
                    }
                } else {
                    if let emoji = Constants.flags[nationality] {
                        detailsLabel.text = "Age: \(age), \(city) \(emoji)"
                    } else {
                        detailsLabel.text = "Age: \(age), \(city)"
                    }
                }
            }
        }
        if customCell.string4 == "F" {
            genderView.layer.shadowColor = Colors.pink.cgColor
        } else {
            genderView.layer.shadowColor = Colors.blue.cgColor
        }
    }
}
