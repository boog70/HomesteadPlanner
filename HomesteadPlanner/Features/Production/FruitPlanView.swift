import SwiftUI

struct FruitPlanView: View {
    @Environment(\.appState) var appState

    var body: some View {
        Group {
            if let state = appState, let needs = state.nutritionNeeds, let zone = state.zoneInfo?.zone {
                let fruitPlan = ProductionService.getEffectiveFruitPlan(annualCalories: needs.annualCalories, zone: zone, fruitPreference: state.fruitPreference, overrides: state.fruitPlanOverrides)
                List(fruitPlan, id: \.fruit.id) { item in
                    Text("\(item.fruit.name): \(item.treesNeeded) tree(s)")
                }
                .navigationTitle("Fruit plan")
            } else {
                ContentUnavailableView("Complete steps 1 and 2", systemImage: "apple.logo")
            }
        }
    }
}
