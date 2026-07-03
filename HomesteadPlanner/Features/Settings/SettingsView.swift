import SwiftUI

struct SettingsView: View {
    @Environment(\.appState) var appState
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirm = false

    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Text("Clear all local data")
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Clear all data?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) {
                appState?.clearAllData()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your plan and harvests.")
        }
    }
}
