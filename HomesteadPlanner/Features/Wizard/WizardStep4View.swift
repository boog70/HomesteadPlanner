import SwiftUI

struct WizardStep4View: View {
    @Environment(\.appState) var appState
    @Environment(\.navigationPath) var path

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Step 4: Share your plan")
                    .font(.title2.bold())
                Text("Data is stored locally on your device. There is no cloud sync or sharing in this app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Next: References") {
                    path?.wrappedValue.append(Route.step5)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(24)
        }
        .navigationTitle("Share")
    }
}
