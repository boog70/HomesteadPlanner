import Foundation

enum CropCategory: String, Codable {
    case vegetable, fruit, legume, grain
}

enum AllocationTier: String, Codable {
    case staple, variety
}

struct PlantingWindow: Codable {
    var spring: DateRange?
    var fall: DateRange?
}

struct DateRange: Codable {
    var start: String
    var end: String
}

struct Crop: Codable, Identifiable {
    var id: String
    var name: String
    var category: CropCategory
    var allocationTier: AllocationTier?
    var yieldPer10FtRow: Double
    var caloriesPerLb: Double
    var proteinPerLb: Double?
    var daysToMaturity: Int
    var plantingWindows: [String: PlantingWindow]
    var spacing: CropSpacing
    var successionPlantings: Int?
    var seedPer10Ft: String?
}

struct CropSpacing: Codable {
    var plantInRow: String
    var betweenRows: String
}

struct CropPlanItem: Codable {
    var crop: Crop
    var lbsNeededAnnual: Double
    var rowFeetNeeded: Int
    var sqFtNeeded: Int
    var successionPlantings: Int
    var seedQuantity: String
    var plantingDates: PlantingDates
}

struct PlantingDates: Codable {
    var spring: String?
    var fall: String?
}

struct AddedCropPlanItem: Codable {
    var cropId: String
    var rowFeetNeeded: Int?
    var lbsNeededAnnual: Double?
}

struct QuantityOverride: Codable {
    var lbsNeededAnnual: Double?
    var rowFeetNeeded: Int?
}

struct CropPlanOverrides: Codable {
    var removedCropIds: [String]
    var addedItems: [AddedCropPlanItem]
    var quantityOverrides: [String: QuantityOverride]?
}
