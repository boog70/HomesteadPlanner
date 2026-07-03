import SwiftUI

@main
struct HomesteadPlannerApp: App {
    let persistence = PersistenceController.shared
    @State private var appState: AppState?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .onAppear {
                    appState = AppState(repository: PlanRepository(context: persistence.viewContext))
                }
                .environment(\.appState, appState)
        }
    }
}

private struct AppStateKey: EnvironmentKey {
    static let defaultValue: AppState? = nil
}

extension EnvironmentValues {
    var appState: AppState? {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
