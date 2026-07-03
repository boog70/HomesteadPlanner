import SwiftUI

struct AnimalPlanView: View {
    @Environment(\.appState) var appState

    var body: some View {
        Group {
            if let state = appState, let needs = state.nutritionNeeds {
                let animalPlan = ProductionService.getEffectiveAnimalPlan(annualCalories: needs.annualCalories, annualProtein: needs.annualProtein, overrides: state.animalPlanOverrides)
                List(animalPlan, id: \.animal.id) { item in
                    VStack(alignment: .leading) {
                        Text(item.animal.name).font(.headline)
                        Text("\(item.count) · \(item.annualYield, specifier: "%.1f") \(item.product.unit)/yr")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Animal plan")
            } else {
                ContentUnavailableView("Complete step 1", systemImage: "hare.fill")
            }
        }
    }
}
