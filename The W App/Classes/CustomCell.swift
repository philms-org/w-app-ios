
import UIKit

class CustomCell {
    
    var imageView: UIImageView!
    var string1: String!
    var string2: String!
    var string3: String!
    var string4: String!
    var string5: String!
    var string6: String!
    var string7: String!
    
    var latitude: Double!
    var longitude: Double!
    var radius: Double!
    
    var count: Int!
    var progress: Int!
    
    var isSelected: Bool!
    var isMaster: Bool!
    
    var array: [CustomCell]!
    
    var emoji1: (emoji: String, title: String)!
    var emoji2: (emoji: String, title: String)!
    var emoji3: (emoji: String, title: String)!
    var emoji4: (emoji: String, title: String)!
    
    var reload: (() -> ())!
    
    init(string1: String, string2: String) {
        self.string1 = string1
        self.string2 = string2
    }
    
    init(imageView: UIImageView, string1: String) {
        self.imageView = imageView
        self.string1 = string1
    }
    
    init(string1: String, string2: String, string3: String) {
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
    }
    
    init(string1: String, string2: String, isSelected: Bool) {
        self.string1 = string1
        self.string2 = string2
        self.isSelected = isSelected
    }
    
    init(imageView: UIImageView, string1: String, string2: String) {
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
    }
    
    init(string1: String, string2: String, string3: String, isSelected: Bool) {
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.isSelected = isSelected
    }
    
    init(imageView: UIImageView, string1: String, reload: @escaping () -> ()) {
        self.imageView = imageView
        self.string1 = string1
        self.reload = reload
    }
    
    init(imageView: UIImageView, string1: String, string2: String, string3: String) {
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
    }
    
    init(string1: String, string2: String, isSelected: Bool, count: Int, array: [CustomCell]) {
        self.string1 = string1
        self.string2 = string2
        self.isSelected = isSelected
        self.count = count
        self.array = array
    }
    
    init(string1: String, string2: String, string3: String, latitude: Double, longitude: Double, radius: Double) {
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
    
    init(imageView: UIImageView, string1: String, string2: String, string3: String, string4: String) {
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.string4 = string4
    }
    
    init(imageView: UIImageView, string1: String, string2: String, string3: String, latitude: Double, longitude: Double, radius: Double) {
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
    
    init(imageView: UIImageView, string1: String, string2: String, string3: String, latitude: Double, longitude: Double, count: Int, radius: Double) {
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.latitude = latitude
        self.longitude = longitude
        self.count = count
        self.radius = radius
    }
    
    init(string1: String, string2: String, string3: String, string4: String, string5: String) {
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.string4 = string4
        self.string5 = string5
    }
    
    init(string1: String, string2: String, string3: String, string4: String, string5: String, progress: Int) {
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.string4 = string4
        self.string5 = string5
        self.progress = progress
    }
    
    init(imageView: UIImageView, string1: String, string2: String, string3: String, string4: String, string5: String, string6: String,
         string7: String, isMaster: Bool) {
        
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.string4 = string4
        self.string5 = string5
        self.string6 = string6
        self.string7 = string7
        self.isMaster = isMaster
    }
    
    init(imageView: UIImageView, string1: String, string2: String, string3: String, string4: String, string5: String, string6: String,
         string7: String, isSelected: Bool, isMaster: Bool) {
        
        self.imageView = imageView
        self.string1 = string1
        self.string2 = string2
        self.string3 = string3
        self.string4 = string4
        self.string5 = string5
        self.string6 = string6
        self.string7 = string7
        self.isSelected = isSelected
        self.isMaster = isMaster
    }
    
    init(string1: String, emoji1: (emoji: String, title: String), emoji2: (emoji: String, title: String), emoji3: (emoji: String, title: String),
         emoji4: (emoji: String, title: String), progress: Int) {
        
        self.string1 = string1
        self.emoji1 = emoji1
        self.emoji2 = emoji2
        self.emoji3 = emoji3
        self.emoji4 = emoji4
        self.progress = progress
    }
}
