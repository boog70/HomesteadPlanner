import Foundation

enum CalendarEventType: String, Codable {
    case plant, harvest
}

struct CalendarEvent: Codable {
    var cropId: String
    var cropName: String
    var eventType: CalendarEventType
    var startDate: String
    var endDate: String
    var notes: String?
}
