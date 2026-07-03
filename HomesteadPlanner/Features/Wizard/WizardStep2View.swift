import SwiftUI

struct WizardStep2View: View {
    @Environment(\.appState) var appState
    @Environment(\.navigationPath) var path
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Step 2: Where do you live?")
                    .font(.title2.bold())
                Text("Enter your ZIP code or select your growing zone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let state = appState {
                    HStack {
                        TextField("ZIP code", text: Binding(get: { state.zipCode }, set: { state.setZipCode($0) }))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Button(loading ? "Looking up…" : "Look up zone") {
                            Task {
                                await lookupZip(state: state)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(loading)
                    }

                    if let err = error {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Text("Or select zone manually:")
                        .font(.subheadline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 8) {
                        ForEach(["5a", "5b", "6a", "6b", "7a", "7b", "8a", "8b", "9a", "9b", "10a", "10b"], id: \.self) { z in
                            Button(z) {
                                if let info = ZoneService.getZoneInfo(z) {
                                    state.setZoneInfo(info)
                                    error = nil
                                }
                            }
                            .buttonStyle(state.zoneInfo?.zone == z ? .borderedProminent : .bordered)
                            .tint(.green)
                        }
                    }

                    if let zi = state.zoneInfo {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zone \(zi.zone) (\(zi.temperatureRange))")
                                .font(.headline)
                            Text("Last spring frost: \(zi.lastSpringFrost) · First fall frost: \(zi.firstFallFrost)")
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                HStack {
                    Button("Back") { path?.wrappedValue.removeLast() }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    Spacer()
                    Button("Next: Your plan") {
                        path?.wrappedValue.append(Route.step3)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(appState?.zoneInfo == nil)
                }
                .padding(.top)
            }
            .padding(24)
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lookupZip(state: AppState) async {
        loading = true
        error = nil
        let zip = state.zipCode.filter { $0.isNumber }
        if zip.count != 5 {
            error = "Enter a valid 5-digit ZIP code."
            loading = false
            return
        }
        if let zone = await ZoneService.fetchZoneByZip(zip),
           let info = ZoneService.getZoneInfo(zone) {
            state.setZoneInfo(info)
        } else {
            error = "ZIP not found. Try manual zone selection."
        }
        loading = false
    }
}
