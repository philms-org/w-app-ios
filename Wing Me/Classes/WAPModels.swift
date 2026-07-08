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
    var lat: Double?
    var lng: Double?
    var geofenceRadiusMeters: Int?
    var isEvent: Bool?
    var eventDate: String?
    var bannerImage: String?

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, lat, lng
        case geofenceRadiusMeters = "geofence_radius_meters"
        case isEvent = "is_event"
        case eventDate = "event_date"
        case bannerImage = "banner_image"
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
    let locationId: String
    let userId: String
    var mode: String
    var checkedInAt: String?
    var checkedOutAt: String?
    var profile: WAPProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case locationId  = "location_id"
        case userId      = "user_id"
        case mode
        case checkedInAt  = "checked_in_at"
        case checkedOutAt = "checked_out_at"
        case profile      = "profiles"
    }
}

struct WAPContactMethod: Codable, Identifiable {
    let id: String
    let userId: String
    var slotOrder: Int
    var type: String
    var value: String?
    var isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case slotOrder = "slot_order"
        case type
        case value
        case isEnabled = "is_enabled"
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
