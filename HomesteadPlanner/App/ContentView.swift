import SwiftUI

struct ContentView: View {
    @Environment(\.appState) var appState
    @State private var path = NavigationPath()

    var body: some View {
        Group {
            if appState != nil {
                NavigationStack(path: $path) {
                    SplashView(path: $path)
                        .navigationDestination(for: Route.self) { route in
                            route.destination(path: $path)
                        }
                }
                .environment(\.appState, appState)
                .environment(\.navigationPath, $path)
            } else {
                ProgressView("Loading…")
            }
        }
    }
}

private struct NavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath>? = nil
}
extension EnvironmentValues {
    var navigationPath: Binding<NavigationPath>? {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }
}

enum Route: Hashable {
    case step1, step2, step3, step4, step5
    case production, calendar, animals
    case harvests, harvestCompare
    case terms, privacy, settings

    @ViewBuilder
    func destination(path: Binding<NavigationPath>) -> some View {
        switch self {
        case .step1: WizardStep1View()
        case .step2: WizardStep2View()
        case .step3: WizardStep3View()
        case .step4: WizardStep4View()
        case .step5: WizardStep5View()
        case .production: ProductionTableView()
        case .calendar: PlantingCalendarView()
        case .animals: AnimalPlanView()
        case .harvests: HarvestLogView()
        case .harvestCompare: PlanHarvestCompareView()
        case .terms: TermsView()
        case .privacy: PrivacyView()
        case .settings: SettingsView()
        }
    }
}
