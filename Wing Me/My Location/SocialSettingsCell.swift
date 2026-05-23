
import UIKit

class SocialSettingsCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstEmojiLabel: UILabel!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondEmojiLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdEmojiLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var fourthEmojiLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    var delegate: SocialSettingsVC!
    
    func updateCell(customCell: CustomCell) {
        titleLabel.text = customCell.string1
        firstEmojiLabel.text = customCell.emoji1.emoji
        firstLabel.text = customCell.emoji1.title
        secondEmojiLabel.text = customCell.emoji2.emoji
        secondLabel.text = customCell.emoji2.title
        thirdEmojiLabel.text = customCell.emoji3.emoji
        thirdLabel.text = customCell.emoji3.title
        fourthEmojiLabel.text = customCell.emoji4.emoji
        fourthLabel.text = customCell.emoji4.title
        slider.value = Float(customCell.progress)
    }
    
    @IBAction func slide(_ sender: UISlider) {
        let rounded = Int(sender.value)
        sender.value = Float(rounded)
        
        if let indexPath = delegate.tableView.indexPath(for: self) {
            delegate.array[indexPath.row].progress = rounded
        }
    }
}
