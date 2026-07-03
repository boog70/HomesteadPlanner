import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var family: [FamilyMember] = []
    var zipCode: String = ""
    var zoneInfo: ZoneInfo? = nil
    var availableSqFt: Double? = nil
    var nutritionNeeds: NutritionNeeds? = nil
    var animalSplit: AnimalSplit = AnimalSplit(eggs: 0.4, meat: 0.4, milk: 0.2)
    var fruitPreference: FruitPreference = .variety
    var cropPlanOverrides: CropPlanOverrides = CropPlanOverrides(removedCropIds: [], addedItems: [], quantityOverrides: nil)
    var fruitPlanOverrides: FruitPlanOverrides = FruitPlanOverrides(removedFruitIds: [], addedItems: [], quantityOverrides: nil)
    var animalPlanOverrides: AnimalPlanOverrides = AnimalPlanOverrides(removedAnimalIds: [], addedItems: [], quantityOverrides: nil)
    var harvests: [HarvestEntry] = []

    private let repository: PlanRepository
    private var memberIdCounter = 0
    private var saveTask: Task<Void, Never>?
    private let saveDebounceMs = 500

    init(repository: PlanRepository) {
        self.repository = repository
        loadFromStore()
    }

    func loadFromStore() {
        let loaded = repository.loadPlan()
        family = loaded.family
        zipCode = loaded.zipCode
        zoneInfo = loaded.zoneInfo
        availableSqFt = loaded.availableSqFt
        nutritionNeeds = loaded.nutritionNeeds
        animalSplit = loaded.animalSplit
        fruitPreference = loaded.fruitPreference
        cropPlanOverrides = loaded.cropPlanOverrides
        fruitPlanOverrides = loaded.fruitPlanOverrides
        animalPlanOverrides = loaded.animalPlanOverrides
        harvests = loaded.harvests
        memberIdCounter = family.count
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(saveDebounceMs) * 1_000_000)
            guard !Task.isCancelled else { return }
            persist()
        }
    }

    func persist() {
        repository.savePlan(
            zipCode: zipCode, availableSqFt: availableSqFt, zoneInfo: zoneInfo,
            animalSplit: animalSplit, fruitPreference: fruitPreference, nutritionNeeds: nutritionNeeds,
            cropPlanOverrides: cropPlanOverrides, fruitPlanOverrides: fruitPlanOverrides, animalPlanOverrides: animalPlanOverrides,
            family: family, harvests: harvests
        )
    }

    func clearAllData() {
        family = []
        zipCode = ""
        zoneInfo = nil
        availableSqFt = nil
        nutritionNeeds = nil
        animalSplit = AnimalSplit(eggs: 0.4, meat: 0.4, milk: 0.2)
        fruitPreference = .variety
        cropPlanOverrides = CropPlanOverrides(removedCropIds: [], addedItems: [], quantityOverrides: nil)
        fruitPlanOverrides = FruitPlanOverrides(removedFruitIds: [], addedItems: [], quantityOverrides: nil)
        animalPlanOverrides = AnimalPlanOverrides(removedAnimalIds: [], addedItems: [], quantityOverrides: nil)
        harvests = []
        repository.clearAll()
    }

    // Family
    func addFamilyMember(age: Int = 35, sex: Sex = .female, activityLevel: ActivityLevel = .moderate, heightCm: Double = 165, weightKg: Double = 68, unitSystem: UnitSystem = .imperial) {
        memberIdCounter += 1
        family.append(FamilyMember(id: "m-\(memberIdCounter)", age: age, sex: sex, activityLevel: activityLevel, heightCm: heightCm, weightKg: weightKg, unitSystem: unitSystem, isPregnant: nil, isLactating: nil))
        recalcNutrition()
        scheduleSave()
    }

    func removeFamilyMember(id: String) {
        family.removeAll { $0.id == id }
        recalcNutrition()
        scheduleSave()
    }

    func updateFamilyMember(id: String, _ updates: (inout FamilyMember) -> Void) {
        guard let idx = family.firstIndex(where: { $0.id == id }) else { return }
        updates(&family[idx])
        if family[idx].sex != .female || family[idx].age < 19 {
            family[idx].isPregnant = false
            family[idx].isLactating = false
        }
        recalcNutrition()
        scheduleSave()
    }

    private func recalcNutrition() {
        if family.isEmpty { nutritionNeeds = nil; return }
        let members = family.map { m in (age: m.age, sex: m.sex, activityLevel: m.activityLevel, heightCm: m.heightCm, weightKg: m.weightKg, isPregnant: m.isPregnant ?? false, isLactating: m.isLactating ?? false) }
        nutritionNeeds = NutritionService.getNutritionForFamily(members: members)
    }

    func setZipCode(_ s: String) { zipCode = s; scheduleSave() }
    func setZoneInfo(_ z: ZoneInfo?) { zoneInfo = z; scheduleSave() }
    func setAvailableSqFt(_ sq: Double?) { availableSqFt = sq; scheduleSave() }
    func setAnimalSplit(_ s: AnimalSplit) { animalSplit = s; scheduleSave() }
    func setFruitPreference(_ p: FruitPreference) { fruitPreference = p; scheduleSave() }
    func setCropPlanOverrides(_ o: CropPlanOverrides) { cropPlanOverrides = o; scheduleSave() }
    func setFruitPlanOverrides(_ o: FruitPlanOverrides) { fruitPlanOverrides = o; scheduleSave() }
    func setAnimalPlanOverrides(_ o: AnimalPlanOverrides) { animalPlanOverrides = o; scheduleSave() }

    func addHarvest(_ h: HarvestEntry) {
        harvests.insert(h, at: 0)
        scheduleSave()
    }

    func removeHarvest(id: String) {
        harvests.removeAll { $0.id == id }
        scheduleSave()
    }
}
