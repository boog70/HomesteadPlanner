import Foundation

struct PlanCalorieBalance: Codable {
    var targetPlantCalories: Double
    var actualPlanCalories: Double
    var shortfall: Double
    var surplus: Double
}

struct ExpandSuggestion: Codable {
    var crop: Crop
    var currentRowFeet: Int
    var extraRowFeetSuggested: Int
    var extraCalories: Double
}

struct AddCropSuggestion: Codable {
    var crop: Crop
    var suggestedRowFeet: Int
    var estimatedCalories: Double
}

struct ShortfallSuggestions: Codable {
    var expand: [ExpandSuggestion]
    var add: [AddCropSuggestion]
}

struct LandNeededToCloseShortfall: Codable {
    var shortfallCalories: Double
    var sqFtNeeded: Int
    var suggestedCrop: Crop?
    var estimatedCalories: Double
}
