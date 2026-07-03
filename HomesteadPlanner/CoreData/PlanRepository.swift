import Foundation
import CoreData

@MainActor
final class PlanRepository: ObservableObject {
    private let context: NSManagedObjectContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    struct LoadedPlan {
        var zipCode: String
        var availableSqFt: Double?
        var zoneInfo: ZoneInfo?
        var animalSplit: AnimalSplit
        var fruitPreference: FruitPreference
        var nutritionNeeds: NutritionNeeds?
        var cropPlanOverrides: CropPlanOverrides
        var fruitPlanOverrides: FruitPlanOverrides
        var animalPlanOverrides: AnimalPlanOverrides
        var family: [FamilyMember]
        var harvests: [HarvestEntry]
    }

    func loadPlan() -> LoadedPlan {
        let settingsReq = NSFetchRequest<NSManagedObject>(entityName: "PlanSettings")
        let familyReq = NSFetchRequest<NSManagedObject>(entityName: "FamilyMemberEntity")
        familyReq.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        let harvestReq = NSFetchRequest<NSManagedObject>(entityName: "HarvestEntryEntity")
        harvestReq.sortDescriptors = [NSSortDescriptor(key: "harvestDate", ascending: false)]

        var settings = PlanSettingsData()
        var family: [FamilyMember] = []
        var harvests: [HarvestEntry] = []

        if let results = try? context.fetch(settingsReq), let first = results.first {
            settings = dataFromPlanSettings(first)
        }
        if let results = try? context.fetch(familyReq) {
            family = results.compactMap { memberFromEntity($0) }
        }
        if let results = try? context.fetch(harvestReq) {
            harvests = results.compactMap { harvestFromEntity($0) }
        }
        return LoadedPlan(
            zipCode: settings.zipCode, availableSqFt: settings.availableSqFt, zoneInfo: settings.zoneInfo,
            animalSplit: settings.animalSplit, fruitPreference: settings.fruitPreference, nutritionNeeds: settings.nutritionNeeds,
            cropPlanOverrides: settings.cropPlanOverrides, fruitPlanOverrides: settings.fruitPlanOverrides, animalPlanOverrides: settings.animalPlanOverrides,
            family: family, harvests: harvests
        )
    }

    func savePlan(zipCode: String, availableSqFt: Double?, zoneInfo: ZoneInfo?, animalSplit: AnimalSplit, fruitPreference: FruitPreference, nutritionNeeds: NutritionNeeds?, cropPlanOverrides: CropPlanOverrides, fruitPlanOverrides: FruitPlanOverrides, animalPlanOverrides: AnimalPlanOverrides, family: [FamilyMember], harvests: [HarvestEntry]) {
        let settings = PlanSettingsData(zipCode: zipCode, availableSqFt: availableSqFt, zoneInfo: zoneInfo, animalSplit: animalSplit, fruitPreference: fruitPreference, nutritionNeeds: nutritionNeeds, cropPlanOverrides: cropPlanOverrides, fruitPlanOverrides: fruitPlanOverrides, animalPlanOverrides: animalPlanOverrides)
        // Delete existing
        for entityName in ["PlanSettings", "FamilyMemberEntity", "HarvestEntryEntity"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? context.execute(deleteReq)
        }

        // PlanSettings (singleton)
        let settingsEntity = NSEntityDescription.insertNewObject(forEntityName: "PlanSettings", into: context)
        applySettings(settings, to: settingsEntity)

        // Family
        for (i, fm) in family.enumerated() {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "FamilyMemberEntity", into: context)
            entity.setValue(fm.id, forKey: "id")
            entity.setValue(Int16(fm.age), forKey: "age")
            entity.setValue(fm.sex.rawValue, forKey: "sex")
            entity.setValue(fm.activityLevel.rawValue, forKey: "activityLevel")
            entity.setValue(fm.heightCm, forKey: "heightCm")
            entity.setValue(fm.weightKg, forKey: "weightKg")
            entity.setValue(fm.unitSystem.rawValue, forKey: "unitSystem")
            entity.setValue(fm.isPregnant ?? false, forKey: "isPregnant")
            entity.setValue(fm.isLactating ?? false, forKey: "isLactating")
            entity.setValue(Int16(i), forKey: "sortOrder")
        }

        // Harvests
        for h in harvests {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "HarvestEntryEntity", into: context)
            entity.setValue(h.id, forKey: "id")
            entity.setValue(h.cropId, forKey: "cropId")
            entity.setValue(h.fruitId, forKey: "fruitId")
            entity.setValue(h.lbs, forKey: "lbs")
            entity.setValue(h.harvestDate, forKey: "harvestDate")
            entity.setValue(h.calories, forKey: "calories")
            entity.setValue(h.notes, forKey: "notes")
            entity.setValue(ISO8601DateFormatter().date(from: h.createdAt ?? ""), forKey: "createdAt")
        }

        _ = try? context.save()
    }

    func clearAll() {
        for entityName in ["PlanSettings", "FamilyMemberEntity", "HarvestEntryEntity"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteReq = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? context.execute(deleteReq)
        }
        _ = try? context.save()
    }

    private struct PlanSettingsData {
        var zipCode: String
        var availableSqFt: Double?
        var zoneInfo: ZoneInfo?
        var animalSplit: AnimalSplit
        var fruitPreference: FruitPreference
        var nutritionNeeds: NutritionNeeds?
        var cropPlanOverrides: CropPlanOverrides
        var fruitPlanOverrides: FruitPlanOverrides
        var animalPlanOverrides: AnimalPlanOverrides
        init(zipCode: String = "", availableSqFt: Double? = nil, zoneInfo: ZoneInfo? = nil, animalSplit: AnimalSplit = AnimalSplit(eggs: 0.4, meat: 0.4, milk: 0.2), fruitPreference: FruitPreference = .variety, nutritionNeeds: NutritionNeeds? = nil, cropPlanOverrides: CropPlanOverrides = CropPlanOverrides(removedCropIds: [], addedItems: [], quantityOverrides: nil), fruitPlanOverrides: FruitPlanOverrides = FruitPlanOverrides(removedFruitIds: [], addedItems: [], quantityOverrides: nil), animalPlanOverrides: AnimalPlanOverrides = AnimalPlanOverrides(removedAnimalIds: [], addedItems: [], quantityOverrides: nil)) {
            self.zipCode = zipCode
            self.availableSqFt = availableSqFt
            self.zoneInfo = zoneInfo
            self.animalSplit = animalSplit
            self.fruitPreference = fruitPreference
            self.nutritionNeeds = nutritionNeeds
            self.cropPlanOverrides = cropPlanOverrides
            self.fruitPlanOverrides = fruitPlanOverrides
            self.animalPlanOverrides = animalPlanOverrides
        }
    }

    private func dataFromPlanSettings(_ entity: NSManagedObject) -> PlanSettingsData {
        var d = PlanSettingsData()
        d.zipCode = entity.value(forKey: "zipCode") as? String ?? ""
        let av = entity.value(forKey: "availableSqFt") as? Double ?? 0
        d.availableSqFt = av > 0 ? av : nil
        if let data = entity.value(forKey: "zoneInfoData") as? Data { d.zoneInfo = try? decoder.decode(ZoneInfo.self, from: data) }
        if let data = entity.value(forKey: "animalSplitData") as? Data { d.animalSplit = (try? decoder.decode(AnimalSplit.self, from: data)) ?? d.animalSplit }
        d.fruitPreference = FruitPreference(rawValue: entity.value(forKey: "fruitPreference") as? String ?? "variety") ?? .variety
        if let data = entity.value(forKey: "nutritionNeedsData") as? Data { d.nutritionNeeds = try? decoder.decode(NutritionNeeds.self, from: data) }
        if let data = entity.value(forKey: "cropPlanOverridesData") as? Data { d.cropPlanOverrides = (try? decoder.decode(CropPlanOverrides.self, from: data)) ?? d.cropPlanOverrides }
        if let data = entity.value(forKey: "fruitPlanOverridesData") as? Data { d.fruitPlanOverrides = (try? decoder.decode(FruitPlanOverrides.self, from: data)) ?? d.fruitPlanOverrides }
        if let data = entity.value(forKey: "animalPlanOverridesData") as? Data { d.animalPlanOverrides = (try? decoder.decode(AnimalPlanOverrides.self, from: data)) ?? d.animalPlanOverrides }
        return d
    }

    private func applySettings(_ d: PlanSettingsData, to entity: NSManagedObject) {
        entity.setValue(d.zipCode, forKey: "zipCode")
        entity.setValue(d.availableSqFt ?? 0, forKey: "availableSqFt")
        entity.setValue(d.zoneInfo.flatMap { try? encoder.encode($0) }, forKey: "zoneInfoData")
        entity.setValue(try? encoder.encode(d.animalSplit), forKey: "animalSplitData")
        entity.setValue(d.fruitPreference.rawValue, forKey: "fruitPreference")
        entity.setValue(d.nutritionNeeds.flatMap { try? encoder.encode($0) }, forKey: "nutritionNeedsData")
        entity.setValue(try? encoder.encode(d.cropPlanOverrides), forKey: "cropPlanOverridesData")
        entity.setValue(try? encoder.encode(d.fruitPlanOverrides), forKey: "fruitPlanOverridesData")
        entity.setValue(try? encoder.encode(d.animalPlanOverrides), forKey: "animalPlanOverridesData")
    }

    private func memberFromEntity(_ e: NSManagedObject) -> FamilyMember? {
        guard let id = e.value(forKey: "id") as? String, let sex = Sex(rawValue: e.value(forKey: "sex") as? String ?? "female"), let activity = ActivityLevel(rawValue: e.value(forKey: "activityLevel") as? String ?? "moderate"), let unit = UnitSystem(rawValue: e.value(forKey: "unitSystem") as? String ?? "imperial") else { return nil }
        return FamilyMember(id: id, age: Int(e.value(forKey: "age") as? Int16 ?? 0), sex: sex, activityLevel: activity, heightCm: e.value(forKey: "heightCm") as? Double ?? 0, weightKg: e.value(forKey: "weightKg") as? Double ?? 0, unitSystem: unit, isPregnant: (e.value(forKey: "isPregnant") as? Bool) == true ? true : nil, isLactating: (e.value(forKey: "isLactating") as? Bool) == true ? true : nil)
    }

    private func harvestFromEntity(_ e: NSManagedObject) -> HarvestEntry? {
        guard let id = e.value(forKey: "id") as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        let createdAt = (e.value(forKey: "createdAt") as? Date).flatMap { formatter.string(from: $0) }
        return HarvestEntry(id: id, cropId: e.value(forKey: "cropId") as? String, fruitId: e.value(forKey: "fruitId") as? String, lbs: e.value(forKey: "lbs") as? Double ?? 0, harvestDate: e.value(forKey: "harvestDate") as? String ?? "", calories: e.value(forKey: "calories") as? Double ?? 0, notes: e.value(forKey: "notes") as? String, createdAt: createdAt)
    }
}
