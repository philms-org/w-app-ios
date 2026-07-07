import Foundation

struct WAPProfile: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String?
    var phone: String?
    var avatarURL: String?
    var affiliation: [String]?
    var industry: [String]?
    var role: [String]?
    var city: String?
    var faveDrink: String?
    var fridayNight: String?
    var profession: String?
    var isVerified: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName   = "display_name"
        case email
        case phone
        case avatarURL     = "avatar_url"
        case affiliation
        case industry
        case role
        case city
        case faveDrink     = "fave_drink"
        case fridayNight   = "friday_night"
        case profession
        case isVerified    = "is_verified"
    }
}

struct WAPVenue: Codable, Identifiable {
    let id: String
    var name: String
    var address: String?
    var city: String?
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
    var bannerURL: String?
    var welcomeText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case city
        case latitude
        case longitude
        case radius
        case bannerURL    = "banner_url"
        case welcomeText  = "welcome_text"
    }
}

struct WAPFeedItem: Codable, Identifiable {
    let id: String
    let venueId: String
    let userId: String
    var text: String
    var createdAt: String
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId   = "venue_id"
        case userId    = "user_id"
        case text
        case createdAt = "created_at"
        case profile   = "profiles"
    }
}

struct WAPPresence: Codable, Identifiable {
    let id: String
    let venueId: String
    let userId: String
    var checkedInAt: String?
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId     = "venue_id"
        case userId      = "user_id"
        case checkedInAt = "checked_in_at"
        case profile     = "profiles"
    }
}

struct WAPSocialLink: Codable, Identifiable {
    let id: String
    let userId: String
    var platform: String
    var url: String
    var isVisible: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case platform
        case url
        case isVisible = "is_visible"
    }
}

struct WAPReward: Codable, Identifiable {
    let id: String
    let venueId: String?
    var type: String
    var title: String
    var description: String?
    var verificationInstructions: String?
    var tier: String

    enum CodingKeys: String, CodingKey {
        case id
        case venueId                  = "venue_id"
        case type
        case title
        case description
        case verificationInstructions = "verification_instructions"
        case tier
    }
}
