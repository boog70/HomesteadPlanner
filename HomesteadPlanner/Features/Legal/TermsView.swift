import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service")
                .font(.title)
            Text("Homestead Planner is provided as-is. Use at your own discretion.")
                .padding()
        }
        .navigationTitle("Terms")
    }
}
