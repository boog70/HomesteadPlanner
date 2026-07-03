import SwiftUI

struct ProductionTableView: View {
    @Environment(\.appState) var appState

    var body: some View {
        Group {
            if let state = appState, let needs = state.nutritionNeeds, let zone = state.zoneInfo?.zone {
                let cropPlan = ProductionService.getEffectiveCropPlan(annualCalories: needs.annualCalories, annualProtein: needs.annualProtein, zone: zone, overrides: state.cropPlanOverrides)
                List(cropPlan, id: \.crop.id) { item in
                    VStack(alignment: .leading) {
                        Text(item.crop.name).font(.headline)
                        Text("\(Int(item.rowFeetNeeded)) row ft · \(item.lbsNeededAnnual, specifier: "%.1f") lbs/yr")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Production")
            } else {
                ContentUnavailableView("Complete steps 1 and 2", systemImage: "leaf.fill")
            }
        }
    }
}
