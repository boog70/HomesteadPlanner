import Foundation

private let defaultVegFruitPct = 0.6
private let defaultLegumeGrainPct = 0.25
private let defaultAnimalPct = 0.15
private let stapleCalPct = 0.7
private let varietyCalPct = 0.3
private let defaultAnimalSplit = AnimalSplit(eggs: 0.4, meat: 0.4, milk: 0.2)
private let fruitCalPct = 0.05

enum ProductionService {
    private static func getPlantingZone(_ zone: String) -> String {
        let zoneMap: [String: String] = [
            "3a": "5a", "3b": "5a", "4a": "5a", "4b": "5a", "5a": "5a",
            "5b": "6a", "6a": "6a", "6b": "6b", "7a": "7a", "7b": "7b", "8a": "8a", "8b": "8b",
            "9a": "9a", "9b": "9b", "10a": "10a", "10b": "10a", "11a": "10a", "11b": "10a"
        ]
        return zoneMap[zone.replacingOccurrences(of: " ", with: "")] ?? "7a"
    }

    private static func parseSpacingToFeet(_ spacing: String) -> Double {
        let normalized = spacing.lowercased().trimmingCharacters(in: .whitespaces)
        let pattern = #"[\d.]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) != nil else {
            return 3
        }
        var values: [Double] = []
        let nsRange = NSRange(normalized.startIndex..., in: normalized)
        regex.enumerateMatches(in: normalized, range: nsRange) { m, _, _ in
            if let r = m?.range, let range = Range(r, in: normalized) {
                if let v = Double(normalized[range]) { values.append(v) }
            }
        }
        guard !values.isEmpty else { return 3 }
        let value = values.count > 1 ? (values[0] + values[1]) / 2 : values[0]
        return normalized.contains("in") ? value / 12 : value
    }

    private static func parseSeedQuantity(_ seedQty: String, mult: Double) -> String {
        let normalized = seedQty.trimmingCharacters(in: .whitespaces).lowercased()
        var amount: Double = 0
        if let slashIdx = normalized.firstIndex(of: "/") {
            let before = String(normalized[..<slashIdx].trimmingCharacters(in: .whitespaces))
            let after = String(normalized[normalized.index(after: slashIdx)...].trimmingCharacters(in: .whitespaces))
            if let a = Double(before), let b = Double(after), b != 0 { amount = a / b }
        }
        if amount == 0 {
            let scanner = Scanner(string: normalized)
            if let v = scanner.scanDouble() { amount = v }
        }
        guard amount > 0 else { return seedQty }
        let scaled = amount * mult
        let rounded = (scaled * 100).rounded() / 100
        return String(rounded)
    }

    private static func zoneNum(_ zone: String) -> Double {
        let trimmed = zone.trimmingCharacters(in: .whitespaces).lowercased()
        let digits = trimmed.filter { $0.isNumber }
        guard let n = Int(digits) else { return 7 }
        var num = Double(n)
        if trimmed.hasSuffix("b") { num += 0.5 }
        return num
    }

    private static func fruitGrowsInZone(_ fruitZones: [String], userZoneNum: Double) -> Bool {
        let nums = fruitZones.compactMap { Int($0) }
        guard !nums.isEmpty else { return false }
        let minZ = Double(nums.min() ?? 0)
        let maxZ = Double(nums.max() ?? 0) + 0.99
        return userZoneNum >= minZ && userZoneNum <= maxZ
    }

    private static func normalizeSplit(_ split: AnimalSplit) -> AnimalSplit {
        let total = split.eggs + split.meat + split.milk
        guard total > 0 else { return defaultAnimalSplit }
        return AnimalSplit(eggs: split.eggs / total, meat: split.meat / total, milk: split.milk / total)
    }

    // MARK: - Crop plan

    static func computeCropPlan(annualCalories: Double, _ annualProtein: Double, zone: String, vegPct: Double? = nil, legumePct: Double? = nil, animalPct: Double? = nil) -> [CropPlanItem] {
        let veg = vegPct ?? defaultVegFruitPct
        let legume = legumePct ?? defaultLegumeGrainPct
        let plantZone = getPlantingZone(zone)
        let plantCalories = annualCalories * (veg + legume)
        let stapleCalTarget = plantCalories * stapleCalPct
        let varietyCalTarget = plantCalories * varietyCalPct

        let crops = DataLoader.crops
        let eligibleCrops = crops.filter { c in
            let w = c.plantingWindows[plantZone]
            return w != nil && (w?.spring != nil || w?.fall != nil)
        }
        let stapleCrops = eligibleCrops.filter { $0.allocationTier == .staple }
        let varietyCrops = eligibleCrops.filter { $0.allocationTier != .staple }
        let stapleCount = max(1, stapleCrops.count)
        let varietyCount = max(1, varietyCrops.count)

        var results: [CropPlanItem] = []
        for crop in crops {
            guard let windows = crop.plantingWindows[plantZone], windows.spring != nil || windows.fall != nil else { continue }
            let isStaple = crop.allocationTier == .staple
            let calShare = isStaple ? stapleCalTarget / Double(stapleCount) : varietyCalTarget / Double(varietyCount)
            let lbsNeeded = max(0, crop.caloriesPerLb > 0 ? calShare / crop.caloriesPerLb : 0)
            guard lbsNeeded >= 1 else { continue }

            let yieldPerFt = crop.yieldPer10FtRow / 10
            let successionFactor = Double(crop.successionPlantings ?? 1)
            let rowFeetNeeded = (lbsNeeded / yieldPerFt) * (1 / min(successionFactor, 3))
            let rowWidthFt = parseSpacingToFeet(crop.spacing.betweenRows)
            let sqFtNeeded = rowFeetNeeded * rowWidthFt

            let plantingDates = PlantingDates(
                spring: windows.spring.map { "\($0.start) – \($0.end)" },
                fall: windows.fall.map { "\($0.start) – \($0.end)" }
            )
            let seedQty = crop.seedPer10Ft ?? "varies"
            let seedMult = ceil(rowFeetNeeded / 10)
            let seedQuantity = parseSeedQuantity(seedQty, mult: seedMult)

            results.append(CropPlanItem(
                crop: crop,
                lbsNeededAnnual: (lbsNeeded * 10).rounded() / 10,
                rowFeetNeeded: Int(rowFeetNeeded.rounded()),
                sqFtNeeded: Int(sqFtNeeded.rounded()),
                successionPlantings: Int(successionFactor),
                seedQuantity: seedQuantity,
                plantingDates: plantingDates
            ))
        }
        return results.sorted { $0.lbsNeededAnnual > $1.lbsNeededAnnual }
    }

    static func getCropById(_ id: String) -> Crop? { DataLoader.crops.first { $0.id == id } }

    static func getCropsForZone(_ zone: String) -> [Crop] {
        let plantZone = getPlantingZone(zone)
        return DataLoader.crops.filter { c in
            let w = c.plantingWindows[plantZone]
            return w != nil && (w?.spring != nil || w?.fall != nil)
        }
    }

    static func getTargetPlantCalories(annualCalories: Double, vegPct: Double? = nil, legumePct: Double? = nil) -> Double {
        let veg = vegPct ?? defaultVegFruitPct
        let legume = legumePct ?? defaultLegumeGrainPct
        return annualCalories * (veg + legume)
    }

    private static func buildCropPlanItemFromAmounts(crop: Crop, zone: String, rowFeetNeeded: Int? = nil, lbsNeededAnnual: Double? = nil) -> CropPlanItem? {
        let plantZone = getPlantingZone(zone)
        guard let windows = crop.plantingWindows[plantZone], windows.spring != nil || windows.fall != nil else { return nil }
        let yieldPerFt = crop.yieldPer10FtRow / 10
        let successionFactor = Double(crop.successionPlantings ?? 1)
        var rowFt: Double
        var lbs: Double
        if let lbsVal = lbsNeededAnnual, lbsVal > 0 {
            rowFt = (lbsVal / yieldPerFt) * (1 / min(successionFactor, 3))
            lbs = lbsVal
        } else if let rf = rowFeetNeeded, rf > 0 {
            rowFt = Double(rf)
            lbs = rowFt * yieldPerFt * min(successionFactor, 3)
        } else { return nil }
        let rowWidthFt = parseSpacingToFeet(crop.spacing.betweenRows)
        let sqFtNeeded = rowFt * rowWidthFt
        let plantingDates = PlantingDates(
            spring: windows.spring.map { "\($0.start) – \($0.end)" },
            fall: windows.fall.map { "\($0.start) – \($0.end)" }
        )
        let seedQty = crop.seedPer10Ft ?? "varies"
        let seedMult = ceil(rowFt / 10)
        let seedQuantity = parseSeedQuantity(seedQty, mult: seedMult)
        return CropPlanItem(
            crop: crop, lbsNeededAnnual: (lbs * 10).rounded() / 10,
            rowFeetNeeded: Int(rowFt.rounded()), sqFtNeeded: Int(sqFtNeeded.rounded()),
            successionPlantings: Int(successionFactor), seedQuantity: seedQuantity, plantingDates: plantingDates
        )
    }

    static func computeCropPlanItemForAdd(_ crop: Crop, zone: String, annualCalories: Double, vegPct: Double? = nil, legumePct: Double? = nil) -> CropPlanItem? {
        let veg = vegPct ?? defaultVegFruitPct
        let legume = legumePct ?? defaultLegumeGrainPct
        let plantZone = getPlantingZone(zone)
        guard let windows = crop.plantingWindows[plantZone], windows.spring != nil || windows.fall != nil else { return nil }
        let plantCalories = annualCalories * (veg + legume)
        let stapleCalTarget = plantCalories * stapleCalPct
        let varietyCalTarget = plantCalories * varietyCalPct
        let eligibleCrops = DataLoader.crops.filter { c in
            let w = c.plantingWindows[plantZone]
            return w != nil && (w?.spring != nil || w?.fall != nil)
        }
        let stapleCrops = eligibleCrops.filter { $0.allocationTier == .staple }
        let varietyCrops = eligibleCrops.filter { $0.allocationTier != .staple }
        let stapleCount = max(1, stapleCrops.count)
        let varietyCount = max(1, varietyCrops.count)
        let isStaple = crop.allocationTier == .staple
        let calShare = isStaple ? stapleCalTarget / Double(stapleCount) : varietyCalTarget / Double(varietyCount)
        let lbsNeeded = max(0, crop.caloriesPerLb > 0 ? calShare / crop.caloriesPerLb : 0)
        guard lbsNeeded >= 1 else { return nil }
        return buildCropPlanItemFromAmounts(crop: crop, zone: zone, lbsNeededAnnual: lbsNeeded)
    }

    static func getEffectiveCropPlan(annualCalories: Double, annualProtein: Double, zone: String, overrides: CropPlanOverrides, vegPct: Double? = nil, legumePct: Double? = nil) -> [CropPlanItem] {
        var base = computeCropPlan(annualCalories: annualCalories, annualProtein, zone: zone, vegPct: vegPct, legumePct: legumePct)
        let removedSet = Set(overrides.removedCropIds)
        base.removeAll { removedSet.contains($0.crop.id) }
        var added: [CropPlanItem] = []
        for item in overrides.addedItems {
            guard let crop = getCropById(item.cropId) else { continue }
            let planItem: CropPlanItem?
            if item.rowFeetNeeded != nil || item.lbsNeededAnnual != nil {
                planItem = buildCropPlanItemFromAmounts(crop: crop, zone: zone, rowFeetNeeded: item.rowFeetNeeded, lbsNeededAnnual: item.lbsNeededAnnual)
            } else {
                planItem = computeCropPlanItemForAdd(crop, zone: zone, annualCalories: annualCalories, vegPct: vegPct, legumePct: legumePct)
            }
            if let p = planItem { added.append(p) }
        }
        var combined = base + added
        if let qo = overrides.quantityOverrides, !qo.isEmpty {
            combined = combined.map { p in
                guard let ov = qo[p.crop.id], ov.lbsNeededAnnual != nil || ov.rowFeetNeeded != nil else { return p }
                return buildCropPlanItemFromAmounts(crop: p.crop, zone: zone, rowFeetNeeded: ov.rowFeetNeeded, lbsNeededAnnual: ov.lbsNeededAnnual) ?? p
            }
        }
        return combined.sorted { $0.lbsNeededAnnual > $1.lbsNeededAnnual }
    }

    static func getPlanCalories(_ plan: [CropPlanItem]) -> Double {
        plan.reduce(0) { $0 + $1.lbsNeededAnnual * $1.crop.caloriesPerLb }
    }

    static func getFruitPlanCalories(_ fruitPlan: [(fruit: Fruit, treesNeeded: Int)]) -> Double {
        fruitPlan.reduce(0) { $0 + Double($1.treesNeeded) * $1.fruit.yieldPerTreeLbs * $1.fruit.caloriesPerLb }
    }

    static func getPlanCalorieBalance(effectivePlan: [CropPlanItem], annualCalories: Double, vegPct: Double? = nil, legumePct: Double? = nil, fruitPlanCalories: Double = 0) -> PlanCalorieBalance {
        let target = getTargetPlantCalories(annualCalories: annualCalories, vegPct: vegPct, legumePct: legumePct)
        let cropCal = getPlanCalories(effectivePlan)
        let actual = cropCal + fruitPlanCalories
        return PlanCalorieBalance(
            targetPlantCalories: target,
            actualPlanCalories: actual,
            shortfall: max(0, target - actual),
            surplus: max(0, actual - target)
        )
    }

    static func getCaloriesPerSqFt(_ crop: Crop) -> Double {
        let yieldPerFt = crop.yieldPer10FtRow / 10
        let successionFactor = min(Double(crop.successionPlantings ?? 1), 3)
        let rowWidthFt = parseSpacingToFeet(crop.spacing.betweenRows)
        guard rowWidthFt > 0 else { return 0 }
        return (yieldPerFt * crop.caloriesPerLb * successionFactor) / rowWidthFt
    }

    static func landNeededToCloseShortfall(shortfallCalories: Double, zone: String) -> LandNeededToCloseShortfall {
        guard shortfallCalories > 0 else { return LandNeededToCloseShortfall(shortfallCalories: 0, sqFtNeeded: 0, suggestedCrop: nil, estimatedCalories: 0) }
        let eligible = getCropsForZone(zone)
        var best: (crop: Crop, calPerSqFt: Double)? = nil
        for crop in eligible {
            let cps = getCaloriesPerSqFt(crop)
            if cps > 0 && (best == nil || cps > best!.calPerSqFt) { best = (crop, cps) }
        }
        guard let b = best else { return LandNeededToCloseShortfall(shortfallCalories: shortfallCalories, sqFtNeeded: 0, suggestedCrop: nil, estimatedCalories: 0) }
        let sqFtNeeded = Int(ceil(shortfallCalories / b.calPerSqFt))
        return LandNeededToCloseShortfall(shortfallCalories: shortfallCalories, sqFtNeeded: sqFtNeeded, suggestedCrop: b.crop, estimatedCalories: (Double(sqFtNeeded) * b.calPerSqFt).rounded())
    }

    static func getFruitPlanSqFt(_ fruitPlan: [(fruit: Fruit, treesNeeded: Int)]) -> Double {
        let defaultSqFt = 100.0
        return fruitPlan.reduce(0) { $0 + Double($1.treesNeeded) * ($1.fruit.sqFtPerTree ?? defaultSqFt) }
    }

    static func getAnimalPlanSqFt(_ animalPlan: [AnimalPlanItem]) -> Double {
        let defaultSqFt = 50.0
        return animalPlan.reduce(0) { $0 + Double($1.count) * ($1.animal.sqFtPerAnimal ?? defaultSqFt) }
    }

    // MARK: - Animal plan

    static func computeAnimalPlan(annualCalories: Double, annualProtein: Double, animalPct: Double? = nil, split: AnimalSplit? = nil) -> [AnimalPlanItem] {
        let pct = animalPct ?? defaultAnimalPct
        let s = normalizeSplit(split ?? defaultAnimalSplit)
        let animalCalTarget = annualCalories * pct
        let animalProteinTarget = annualProtein * pct
        var productEntries: [(animal: Animal, prod: AnimalProduct)] = []
        for animal in DataLoader.animals {
            for prod in animal.products { productEntries.append((animal, prod)) }
        }
        let eggsEntries = productEntries.filter { $0.prod.product == .eggs }
        let meatEntries = productEntries.filter { $0.prod.product == .meat }
        let milkEntries = productEntries.filter { $0.prod.product == .milk }
        var results: [AnimalPlanItem] = []
        for (entries, key) in [(eggsEntries, AnimalProductType.eggs), (meatEntries, AnimalProductType.meat), (milkEntries, AnimalProductType.milk)] {
            guard !entries.isEmpty else { continue }
            let frac = key == .eggs ? s.eggs : (key == .meat ? s.meat : s.milk)
            let calTargetPerProduct = (animalCalTarget * frac) / Double(entries.count)
            let proteinTargetPerProduct = (animalProteinTarget * frac) / Double(entries.count)
            for (animal, prod) in entries {
                let calPerUnit = prod.caloriesPerUnit
                let proteinPerUnit = prod.proteinPerUnit ?? 0
                let yieldPerAnimal = prod.annualYield
                let unitsByCal = calPerUnit > 0 ? calTargetPerProduct / calPerUnit : 0
                let unitsByProtein = proteinPerUnit > 0 ? proteinTargetPerProduct / proteinPerUnit : 0
                let unitsNeeded = max(unitsByCal, unitsByProtein)
                let countExact = yieldPerAnimal > 0 ? unitsNeeded / yieldPerAnimal : 0
                let count = Int(ceil(countExact))
                guard count >= 1 else { continue }
                let totalYield = Double(count) * yieldPerAnimal
                let totalCal = totalYield * calPerUnit
                results.append(AnimalPlanItem(animal: animal, product: prod, count: count, countExact: (countExact * 100).rounded() / 100, annualYield: (totalYield * 10).rounded() / 10, annualCalories: totalCal.rounded()))
            }
        }
        return results
    }

    static func getAnimalById(_ id: String) -> Animal? { DataLoader.animals.first { $0.id == id } }

    private static func computeAnimalPlanItemForAdd(_ animal: Animal, annualCalories: Double, annualProtein: Double, animalPct: Double? = nil, split: AnimalSplit? = nil) -> AnimalPlanItem? {
        let pct = animalPct ?? defaultAnimalPct
        let s = normalizeSplit(split ?? defaultAnimalSplit)
        guard let product = animal.products.first else { return nil }
        let frac = product.product == .eggs ? s.eggs : (product.product == .meat ? s.meat : s.milk)
        let animalCalTarget = annualCalories * pct
        let animalProteinTarget = annualProtein * pct
        let calTarget = animalCalTarget * frac
        let proteinTarget = animalProteinTarget * frac
        let calPerUnit = product.caloriesPerUnit
        let proteinPerUnit = product.proteinPerUnit ?? 0
        let yieldPerAnimal = product.annualYield
        let unitsByCal = calPerUnit > 0 ? calTarget / calPerUnit : 0
        let unitsByProtein = proteinPerUnit > 0 ? proteinTarget / proteinPerUnit : 0
        let unitsNeeded = max(unitsByCal, unitsByProtein)
        let countExact = yieldPerAnimal > 0 ? unitsNeeded / yieldPerAnimal : 0
        let count = Int(ceil(countExact))
        guard count >= 1 else { return nil }
        let totalYield = Double(count) * yieldPerAnimal
        return AnimalPlanItem(animal: animal, product: product, count: count, countExact: (countExact * 100).rounded() / 100, annualYield: (totalYield * 10).rounded() / 10, annualCalories: (totalYield * calPerUnit).rounded())
    }

    private static func buildAnimalPlanItemFromCount(_ animal: Animal, count: Int) -> AnimalPlanItem? {
        guard let product = animal.products.first, count >= 1 else { return nil }
        let totalYield = Double(count) * product.annualYield
        return AnimalPlanItem(animal: animal, product: product, count: Int(ceil(Double(count))), countExact: Double(count), annualYield: (totalYield * 10).rounded() / 10, annualCalories: (totalYield * product.caloriesPerUnit).rounded())
    }

    static func getEffectiveAnimalPlan(annualCalories: Double, annualProtein: Double, overrides: AnimalPlanOverrides, animalPct: Double? = nil, split: AnimalSplit? = nil) -> [AnimalPlanItem] {
        var base = computeAnimalPlan(annualCalories: annualCalories, annualProtein: annualProtein, animalPct: animalPct, split: split)
        let removedSet = Set(overrides.removedAnimalIds)
        base.removeAll { removedSet.contains($0.animal.id) }
        var added: [AnimalPlanItem] = []
        for item in overrides.addedItems {
            guard let animal = getAnimalById(item.animalId) else { continue }
            var planItem: AnimalPlanItem?
            if let c = item.count, c >= 1 {
                planItem = buildAnimalPlanItemFromCount(animal, count: c)
            } else {
                planItem = computeAnimalPlanItemForAdd(animal, annualCalories: annualCalories, annualProtein: annualProtein, animalPct: animalPct, split: split)
            }
            if planItem == nil { planItem = buildAnimalPlanItemFromCount(animal, count: 1) }
            if let p = planItem { added.append(p) }
        }
        var combined = base + added
        if let qo = overrides.quantityOverrides, !qo.isEmpty {
            combined = combined.map { p in
                guard let ov = qo[p.animal.id], let c = ov.count, c >= 1 else { return p }
                return buildAnimalPlanItemFromCount(p.animal, count: c) ?? p
            }
        }
        return combined
    }

    // MARK: - Fruit plan

    static func getFruitById(_ id: String) -> Fruit? { DataLoader.fruits.first { $0.id == id } }

    static func getFruitsForZone(_ zone: String) -> [Fruit] {
        let userZoneNum = zoneNum(zone)
        return DataLoader.fruits.filter { fruitGrowsInZone($0.zones, userZoneNum: userZoneNum) }
    }

    static func computeFruitPlanItemForAdd(_ fruit: Fruit, zone: String, annualCalories: Double, preference: FruitPreference = .variety) -> (fruit: Fruit, treesNeeded: Int)? {
        let userZoneNum = zoneNum(zone)
        guard fruitGrowsInZone(fruit.zones, userZoneNum: userZoneNum) else { return nil }
        let fruitCalTarget = annualCalories * fruitCalPct
        let eligible = DataLoader.fruits.filter { fruitGrowsInZone($0.zones, userZoneNum: userZoneNum) }
        let count = max(1, eligible.count)
        let calTargetPerFruit = fruitCalTarget / Double(count)
        let calPerTree = fruit.yieldPerTreeLbs * fruit.caloriesPerLb
        let treesNeeded = calPerTree > 0 ? calTargetPerFruit / calPerTree : 0
        guard treesNeeded >= 0.5 else { return nil }
        return (fruit, Int(ceil(treesNeeded)))
    }

    static func computeFruitPlan(annualCalories: Double, zone: String, preference: FruitPreference = .variety) -> [(fruit: Fruit, treesNeeded: Int)] {
        let fruitCalTarget = annualCalories * fruitCalPct
        let userZoneNum = zoneNum(zone)
        let eligible = DataLoader.fruits.filter { fruitGrowsInZone($0.zones, userZoneNum: userZoneNum) }
        let selected: [Fruit] = preference == .calorie
            ? Array(eligible.sorted { ($1.yieldPerTreeLbs * $1.caloriesPerLb) > ($0.yieldPerTreeLbs * $0.caloriesPerLb) }.prefix(6))
            : eligible
        let count = max(1, selected.count)
        let calTargetPerFruit = fruitCalTarget / Double(count)
        var results: [(Fruit, Int)] = []
        for fruit in selected {
            let calPerTree = fruit.yieldPerTreeLbs * fruit.caloriesPerLb
            let treesNeeded = calPerTree > 0 ? calTargetPerFruit / calPerTree : 0
            if treesNeeded >= 0.5 { results.append((fruit, Int(ceil(treesNeeded)))) }
        }
        return results
    }

    static func getEffectiveFruitPlan(annualCalories: Double, zone: String, fruitPreference: FruitPreference, overrides: FruitPlanOverrides) -> [(fruit: Fruit, treesNeeded: Int)] {
        var base = computeFruitPlan(annualCalories: annualCalories, zone: zone, preference: fruitPreference)
        let removedSet = Set(overrides.removedFruitIds)
        base.removeAll { removedSet.contains($0.fruit.id) }
        var added: [(Fruit, Int)] = []
        for item in overrides.addedItems {
            guard let fruit = getFruitById(item.fruitId) else { continue }
            var planItem: (Fruit, Int)?
            if let t = item.treesNeeded, t >= 1 {
                planItem = (fruit, Int(ceil(Double(t))))
            } else {
                planItem = computeFruitPlanItemForAdd(fruit, zone: zone, annualCalories: annualCalories, preference: fruitPreference)
            }
            if planItem == nil { planItem = (fruit, 1) }
            if let p = planItem { added.append(p) }
        }
        var combined = base + added
        if let qo = overrides.quantityOverrides, !qo.isEmpty {
            combined = combined.map { p in
                guard let ov = qo[p.fruit.id], let t = ov.treesNeeded, t >= 1 else { return p }
                return (p.fruit, Int(ceil(Double(t))))
            }
        }
        return combined.sorted { (Double($1.treesNeeded) * $1.fruit.yieldPerTreeLbs * $1.fruit.caloriesPerLb) > (Double($0.treesNeeded) * $0.fruit.yieldPerTreeLbs * $0.fruit.caloriesPerLb) }
    }
}
