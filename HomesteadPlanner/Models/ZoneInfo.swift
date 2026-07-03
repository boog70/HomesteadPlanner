import Foundation

struct ZoneInfo: Codable {
    var zone: String
    var temperatureRange: String
    var lastSpringFrost: String
    var firstFallFrost: String
    var lastSpringFrostDayOfYear: Int
    var firstFallFrostDayOfYear: Int
    var growingSeasonDays: Int
}
