import XCTest
@testable import HomesteadPlanner

final class NutritionTests: XCTestCase {
    func testNutritionForPerson() {
        let p = NutritionService.getNutritionForPerson(age: 35, sex: .female, activityLevel: .moderate, heightCm: 165, weightKg: 68)
        XCTAssertGreaterThan(p.dailyCalories, 1500)
        XCTAssertLessThan(p.dailyCalories, 3000)
    }

    func testNutritionParity_AdultFemale() {
        let p = NutritionService.getNutritionForPerson(age: 35, sex: .female, activityLevel: .moderate, heightCm: 165, weightKg: 68)
        XCTAssertEqual(p.dailyCalories, 2442, accuracy: 5)
        XCTAssertEqual(p.dailyProtein, 54, accuracy: 2)
    }

    func testNutritionForFamily() {
        let members: [(age: Int, sex: Sex, activityLevel: ActivityLevel, heightCm: Double, weightKg: Double, isPregnant: Bool, isLactating: Bool)] = [
            (35, .female, .moderate, 165, 68, false, false),
            (40, .male, .active, 180, 82, false, false),
        ]
        let needs = NutritionService.getNutritionForFamily(members: members)
        XCTAssertGreaterThan(needs.annualCalories, 500_000)
        XCTAssertEqual(needs.monthlyCalories, needs.dailyCalories * 30, accuracy: 1)
        XCTAssertEqual(needs.annualCalories, needs.dailyCalories * 365, accuracy: 1)
    }
}

final class ZoneServiceTests: XCTestCase {
    func testZoneInfo() {
        let info = ZoneService.getZoneInfo("7a")
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.zone, "7a")
    }

    func testZoneInfo_10b() {
        let info = ZoneService.getZoneInfo("10b")
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.zone, "10b")
    }

    func testZoneInfo_growingSeasonDays() {
        let info = ZoneService.getZoneInfo("7a")
        XCTAssertNotNil(info)
        XCTAssertGreaterThan(info!.growingSeasonDays, 150)
    }
}

final class ProductionServiceTests: XCTestCase {
    func testComputeCropPlan_returnsNonEmpty() {
        let plan = ProductionService.computeCropPlan(annualCalories: 50_000, 1000, zone: "7a")
        XCTAssertFalse(plan.isEmpty)
        XCTAssertTrue(plan.contains { $0.crop.name.lowercased().contains("potato") || $0.crop.name.lowercased().contains("bean") })
    }

    func testComputeCropPlan_caloriesInRange() {
        let plan = ProductionService.computeCropPlan(annualCalories: 50_000, 1000, zone: "7a")
        let planCal = ProductionService.getPlanCalories(plan)
        let target = ProductionService.getTargetPlantCalories(annualCalories: 50_000)
        XCTAssertGreaterThan(planCal, target * 0.5)
        XCTAssertLessThan(planCal, target * 1.5)
    }

    func testComputeAnimalPlan_returnsNonEmpty() {
        let plan = ProductionService.computeAnimalPlan(annualCalories: 50_000, annualProtein: 1000)
        XCTAssertFalse(plan.isEmpty)
    }

    func testComputeAnimalPlan_caloriesRoughly15Percent() {
        // Use higher annual protein so calories drive the plan (avoids whole-animal rounding overshoot)
        let plan = ProductionService.computeAnimalPlan(annualCalories: 500_000, annualProtein: 30_000)
        let totalCal = plan.reduce(0) { $0 + $1.annualCalories }
        let expected = 500_000 * 0.15
        XCTAssertGreaterThan(Double(totalCal), expected * 0.5)
        XCTAssertLessThan(Double(totalCal), expected * 2)
    }

    func testGetCropById() {
        let crop = ProductionService.getCropById("potato")
        XCTAssertNotNil(crop)
        XCTAssertEqual(crop?.name, "Potato")
    }

    func testGetFruitById() {
        let fruit = ProductionService.getFruitById("apple")
        XCTAssertNotNil(fruit)
        XCTAssertEqual(fruit?.name, "Apple")
    }
}

final class DataLoaderTests: XCTestCase {
    func testCropsLoad() {
        let crops = DataLoader.crops
        XCTAssertFalse(crops.isEmpty)
        XCTAssertTrue(crops.contains { $0.id == "potato" })
    }

    func testFruitsLoad() {
        let fruits = DataLoader.fruits
        XCTAssertFalse(fruits.isEmpty)
    }

    func testAnimalsLoad() {
        let animals = DataLoader.animals
        XCTAssertFalse(animals.isEmpty)
    }
}
