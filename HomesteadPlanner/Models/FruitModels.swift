import Foundation

struct Fruit: Codable, Identifiable {
    var id: String
    var name: String
    var yieldPerTreeLbs: Double
    var caloriesPerLb: Double
    var proteinPerLb: Double?
    var yearsToMaturity: Int
    var zones: [String]
    var sqFtPerTree: Double?
}

struct AddedFruitPlanItem: Codable {
    var fruitId: String
    var treesNeeded: Int?
}

struct FruitQuantityOverride: Codable {
    var treesNeeded: Int?
}

struct FruitPlanOverrides: Codable {
    var removedFruitIds: [String]
    var addedItems: [AddedFruitPlanItem]
    var quantityOverrides: [String: FruitQuantityOverride]?
}
