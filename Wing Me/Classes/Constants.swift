import UIKit

class Constants {
    static let appURL = "https://thewapp.com/"
    static let deleteAccountURL = "https://thewapp.com/delete_account"
    static var savedImages = [String: UIImage]()

    // UserDefaults keys (auth token lives in Keychain, not here)
    static let locationID = "LocationID"
    static let locationName = "LocationName"
    static let setup = "Setup"
    static let lastDate = "LastDate"
    static let lastLocationAlert = "LastLocationAlert"
    static let lastLocationNotification = "LastLocationNotification"

    static let countryCodes: [String: String] = [
        "Afghanistan": "+93", "Albania": "+355", "Algeria": "+213",
        "Argentina": "+54", "Australia": "+61", "Austria": "+43",
        "Bahrain": "+973", "Bangladesh": "+880", "Belgium": "+32",
        "Brazil": "+55", "Canada": "+1", "Chile": "+56",
        "China": "+86", "Colombia": "+57", "Croatia": "+385",
        "Czech Republic": "+420", "Denmark": "+45", "Egypt": "+20",
        "Finland": "+358", "France": "+33", "Germany": "+49",
        "Ghana": "+233", "Greece": "+30", "Hong Kong": "+852",
        "Hungary": "+36", "India": "+91", "Indonesia": "+62",
        "Iran": "+98", "Iraq": "+964", "Ireland": "+353",
        "Israel": "+972", "Italy": "+39", "Japan": "+81",
        "Jordan": "+962", "Kenya": "+254", "Kuwait": "+965",
        "Lebanon": "+961", "Libya": "+218", "Malaysia": "+60",
        "Mexico": "+52", "Morocco": "+212", "Netherlands": "+31",
        "New Zealand": "+64", "Nigeria": "+234", "Norway": "+47",
        "Oman": "+968", "Pakistan": "+92", "Palestine": "+970",
        "Peru": "+51", "Philippines": "+63", "Poland": "+48",
        "Portugal": "+351", "Qatar": "+974", "Romania": "+40",
        "Russia": "+7", "Saudi Arabia": "+966", "Singapore": "+65",
        "South Africa": "+27", "South Korea": "+82", "Spain": "+34",
        "Sri Lanka": "+94", "Sudan": "+249", "Sweden": "+46",
        "Switzerland": "+41", "Syria": "+963", "Taiwan": "+886",
        "Thailand": "+66", "Tunisia": "+216", "Turkey": "+90",
        "UAE": "+971", "Uganda": "+256", "UK": "+44",
        "Ukraine": "+380", "USA": "+1", "Venezuela": "+58",
        "Vietnam": "+84", "Yemen": "+967", "Zimbabwe": "+263"
    ]
}
