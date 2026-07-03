import SwiftUI

struct PlanHarvestCompareView: View {
    @Environment(\.appState) var appState

    var body: some View {
        Text("Plan vs harvests comparison")
            .navigationTitle("Compare")
    }
}
