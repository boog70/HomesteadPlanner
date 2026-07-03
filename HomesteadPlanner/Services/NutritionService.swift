import Foundation

struct NutritionProfile {
    var dailyCalories: Double
    var dailyProtein: Double
}

private let proteinGPerKg: [(minAge: Int, maxAge: Int, gramsPerKg: Double)] = [
    (1, 3, 1.05), (4, 8, 0.95), (9, 13, 0.95), (14, 18, 0.85), (19, 120, 0.8)
]

private let adultPA: [String: [String: Double]] = [
    "male": ["sedentary": 1.0, "light": 1.11, "moderate": 1.25, "active": 1.48, "very_active": 1.48],
    "female": ["sedentary": 1.0, "light": 1.12, "moderate": 1.27, "active": 1.45, "very_active": 1.45]
]

private let childPA: [String: [String: Double]] = [
    "male": ["sedentary": 1.0, "light": 1.13, "moderate": 1.26, "active": 1.42, "very_active": 1.42],
    "female": ["sedentary": 1.0, "light": 1.16, "moderate": 1.31, "active": 1.56, "very_active": 1.56]
]

enum NutritionService {
    private static func getClampedAge(_ age: Int) -> Int {
        min(120, max(1, age))
    }

    private static func getProteinRdaGrams(age: Int, weightKg: Double, isPregnant: Bool, isLactating: Bool) -> Int {
        let a = getClampedAge(age)
        var gramsPerKg = 0.8
        for entry in proteinGPerKg {
            if a >= entry.minAge && a <= entry.maxAge {
                gramsPerKg = entry.gramsPerKg
                break
            }
        }
        if isPregnant { gramsPerKg = max(gramsPerKg, 1.1) }
        if isLactating { gramsPerKg = max(gramsPerKg, 1.3) }
        return Int(round(weightKg * gramsPerKg))
    }

    private static func getPaFactor(age: Int, sex: String, activityLevel: String) -> Double {
        if age >= 19 { return adultPA[sex]?[activityLevel] ?? 1.0 }
        if age >= 3 { return childPA[sex]?[activityLevel] ?? 1.0 }
        return 1.0
    }

    private static func getEerCalories(age: Int, sex: String, activityLevel: String, heightCm: Double, weightKg: Double) -> Double {
        let a = getClampedAge(age)
        let heightM = heightCm / 100
        let pa = getPaFactor(age: a, sex: sex, activityLevel: activityLevel)
        if heightM <= 0 || weightKg <= 0 { return 0 }

        if a <= 2 { return 89 * weightKg - 100 + 20 }
        if a <= 18 {
            if sex == "male" {
                return 88.5 - 61.9 * Double(a) + pa * (26.7 * weightKg + 903 * heightM) + 20
            }
            return 135.3 - 30.8 * Double(a) + pa * (10.0 * weightKg + 934 * heightM) + 20
        }
        if sex == "male" {
            return 662 - 9.53 * Double(a) + pa * (15.91 * weightKg + 539.6 * heightM)
        }
        return 354 - 6.91 * Double(a) + pa * (9.36 * weightKg + 726 * heightM)
    }

    static func getNutritionForPerson(
        age: Int, sex: Sex, activityLevel: ActivityLevel,
        heightCm: Double, weightKg: Double,
        isPregnant: Bool = false, isLactating: Bool = false
    ) -> NutritionProfile {
        let eligibleForAddOns = sex == .female && age >= 19
        var dailyCalories = getEerCalories(age: age, sex: sex.rawValue, activityLevel: activityLevel.rawValue, heightCm: heightCm, weightKg: weightKg)
        if eligibleForAddOns && isPregnant { dailyCalories += 340 }
        if eligibleForAddOns && isLactating { dailyCalories += 450 }
        let dailyProtein = getProteinRdaGrams(age: age, weightKg: weightKg, isPregnant: eligibleForAddOns && isPregnant, isLactating: eligibleForAddOns && isLactating)
        return NutritionProfile(dailyCalories: max(0, dailyCalories), dailyProtein: max(0, Double(dailyProtein)))
    }

    static func getNutritionForFamily(
        members: [(age: Int, sex: Sex, activityLevel: ActivityLevel, heightCm: Double, weightKg: Double, isPregnant: Bool, isLactating: Bool)]
    ) -> NutritionNeeds {
        var dailyCalories: Double = 0
        var dailyProtein: Double = 0
        for m in members {
            let p = getNutritionForPerson(age: m.age, sex: m.sex, activityLevel: m.activityLevel, heightCm: m.heightCm, weightKg: m.weightKg, isPregnant: m.isPregnant, isLactating: m.isLactating)
            dailyCalories += p.dailyCalories
            dailyProtein += p.dailyProtein
        }
        return NutritionNeeds(
            dailyCalories: dailyCalories, dailyProtein: dailyProtein,
            monthlyCalories: dailyCalories * 30, monthlyProtein: dailyProtein * 30,
            annualCalories: dailyCalories * 365, annualProtein: dailyProtein * 365
        )
    }
}
