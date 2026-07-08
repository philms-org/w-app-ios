import XCTest
@testable import The_W_App

final class WAPModelsTests: XCTestCase {
    func testWAPVenueDecodesRealLocationsColumns() throws {
        let json = """
        {"id":"loc-1","name":"Hallowell House","address":"123 Main St","city":"Austin",
         "lat":30.27,"lng":-97.74,"geofence_radius_meters":100,
         "is_event":false,"event_date":null,"banner_image":"https://x/banner.jpg"}
        """.data(using: .utf8)!
        let venue = try JSONDecoder().decode(WAPVenue.self, from: json)
        XCTAssertEqual(venue.name, "Hallowell House")
        XCTAssertEqual(venue.geofenceRadiusMeters, 100)
        XCTAssertEqual(venue.bannerImage, "https://x/banner.jpg")
        XCTAssertEqual(venue.isEvent, false)
    }
}
