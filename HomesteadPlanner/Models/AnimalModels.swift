import Foundation

enum AnimalProductType: String, Codable {
    case eggs, meat, milk
}

struct AnimalProduct: Codable {
    var product: AnimalProductType
    var annualYield: Double
    var unit: String
    var caloriesPerUnit: Double
    var proteinPerUnit: Double?
}

struct Animal: Codable, Identifiable {
    var id: String
    var name: String
    var products: [AnimalProduct]
    var sqFtPerAnimal: Double?
    var notes: String?
}

struct AnimalSplit: Codable {
    var eggs: Double
    var meat: Double
    var milk: Double
}

struct AnimalPlanItem: Codable {
    var animal: Animal
    var product: AnimalProduct
    var count: Int
    var countExact: Double
    var annualYield: Double
    var annualCalories: Double
}

struct AddedAnimalPlanItem: Codable {
    var animalId: String
    var count: Int?
}

struct AnimalQuantityOverride: Codable {
    var count: Int?
}

struct AnimalPlanOverrides: Codable {
    var removedAnimalIds: [String]
    var addedItems: [AddedAnimalPlanItem]
    var quantityOverrides: [String: AnimalQuantityOverride]?
}
