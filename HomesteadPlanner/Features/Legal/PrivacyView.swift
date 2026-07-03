import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy")
                .font(.title)
            Text("All data is stored locally on your device. Nothing is sent to any server.")
                .padding()
        }
        .navigationTitle("Privacy")
    }
}
