import SwiftUI

struct SplashView: View {
    @Environment(\.appState) var appState
    @Binding var path: NavigationPath

    init(path: Binding<NavigationPath>) {
        _path = path
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Homestead Planner")
                    .font(.largeTitle.bold())
                Text("Calorie-based garden, fruit, and livestock planning for real families.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Start planning") {
                    path.append(Route.step1)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 16)
            }
            .padding(32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Settings") { path.append(Route.settings) }
                    Button("Terms") { path.append(Route.terms) }
                    Button("Privacy") { path.append(Route.privacy) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
