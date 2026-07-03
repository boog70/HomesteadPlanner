import Foundation

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary, light, moderate, active, very_active
}

enum Sex: String, Codable, CaseIterable {
    case male, female
}

enum UnitSystem: String, Codable, CaseIterable {
    case imperial, metric
}

enum FruitPreference: String, Codable, CaseIterable {
    case variety, calorie
}

struct FamilyMember: Codable, Identifiable {
    var id: String
    var age: Int
    var sex: Sex
    var activityLevel: ActivityLevel
    var heightCm: Double
    var weightKg: Double
    var unitSystem: UnitSystem
    var isPregnant: Bool?
    var isLactating: Bool?
}

struct NutritionNeeds: Codable {
    var dailyCalories: Double
    var dailyProtein: Double
    var monthlyCalories: Double
    var monthlyProtein: Double
    var annualCalories: Double
    var annualProtein: Double
}
