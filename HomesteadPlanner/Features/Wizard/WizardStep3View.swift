import SwiftUI

struct WizardStep3View: View {
    @Environment(\.appState) var appState
    @Environment(\.navigationPath) var path

    var body: some View {
        List {
            Section("Your plan") {
                NavigationLink("Production table") { ProductionTableView() }
                NavigationLink("Planting calendar") { PlantingCalendarView() }
                NavigationLink("Fruit plan") { FruitPlanView() }
                NavigationLink("Animal plan") { AnimalPlanView() }
            }
            Section("Harvests") {
                NavigationLink("My harvests") { HarvestLogView() }
                NavigationLink("Plan vs harvests") { PlanHarvestCompareView() }
            }
            Section {
                Button("Next: Share") {
                    path?.wrappedValue.append(Route.step4)
                }
            }
        }
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}
