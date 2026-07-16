
import UIKit

class EventCell: UITableViewCell {

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    func updateCell(item: EventStruct) {
        eventImageView.image = item.imageView.image
        titleLabel.text = item.title
        detailsLabel.text = item.details
        
        if item.startDate == item.endDate {
            dateLabel.text = "\(item.startDate)"
        } else {
            dateLabel.text = "\(item.startDate) - \(item.endDate)"
        }
        if item.status == "Active" {
            colorView.backgroundColor = Colors.green
        } else if item.status == "Inactive" {
            colorView.backgroundColor = Colors.red
        } else {
            colorView.backgroundColor = Colors.dark_gray
        }
    }
}

struct EventStruct {
    let imageView: UIImageView
    let id: String
    let title: String
    let details: String
    let startDate: String
    let endDate: String
    var status: String
}
