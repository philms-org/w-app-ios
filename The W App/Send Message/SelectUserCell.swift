
import UIKit

class SelectUserCell: UITableViewCell {

    @IBOutlet weak var genderView: ShadowDesignable!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var selectedView: UIViewDesignable!
    
    func updateCell(item: UserClass) {
        userImageView.image = item.imageView.image
        nameLabel.text = item.name
        
        selectedView.isHidden = !item.isSelected
        
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
        if item.gender == "F" {
            genderView.layer.shadowColor = Colors.pink.cgColor
        } else {
            genderView.layer.shadowColor = Colors.blue.cgColor
        }
    }
}

class UserClass {
    let imageView: UIImageView
    let id: String
    let name: String
    let age: String
    let gender: String
    let country: String
    let city: String
    var isSelected: Bool
    
    init(imageView: UIImageView, id: String, name: String, age: String, gender: String, country: String, city: String, isSelected: Bool) {
        self.imageView = imageView
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.country = country
        self.city = city
        self.isSelected = isSelected
    }
}
