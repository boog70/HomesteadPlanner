import SwiftUI

struct HarvestLogView: View {
    @Environment(\.appState) var appState

    var body: some View {
        Group {
            if let state = appState {
                List(state.harvests, id: \.id) { h in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(h.harvestDate)
                            Text("\(h.lbs, specifier: "%.1f") lbs · \(Int(h.calories)) cal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) { state.removeHarvest(id: h.id) } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                .navigationTitle("My harvests")
            } else {
                ContentUnavailableView("Loading", systemImage: "tray")
            }
        }
    }
}
