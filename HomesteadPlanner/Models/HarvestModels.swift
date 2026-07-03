import Foundation

struct HarvestEntry: Codable, Identifiable {
    var id: String
    var cropId: String?
    var fruitId: String?
    var lbs: Double
    var harvestDate: String
    var calories: Double
    var notes: String?
    var createdAt: String?
}
