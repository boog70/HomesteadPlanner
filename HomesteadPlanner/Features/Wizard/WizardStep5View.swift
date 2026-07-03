import SwiftUI

struct WizardStep5View: View {
    @Environment(\.appState) var appState
    @Environment(\.navigationPath) var path

    private let sources: [(String, [String])] = [
        ("Calorie & nutrition basis", [
            "Garden planned to meet family calorie needs: 85% from plants, 15% from animals",
            "Staple-weighted: 70% staples, 30% variety crops",
            "IOM/DRI EER equations and protein RDA (g/kg)",
        ]),
        ("Planting amounts", ["HarvestSavvy", "Virginia Cooperative Extension 426-331", "UC Master Gardener"]),
        ("Planting dates & frost", ["Virginia Extension 426-331 by USDA zone", "Frost dates: American Gardener, Virginia Cooperative Extension"]),
        ("Succession planting", ["Johnny's Seeds intervals"]),
        ("Fruit trees", ["PSU Extension", "Stark Bros yields"]),
        ("Zone lookup", ["phzmapi.org – USDA Plant Hardiness Zone by ZIP"]),
        ("Animal production", ["Extension guides: chicken eggs, rabbit, goat milk"]),
    ]

    var body: some View {
        List {
            Section {
                Text("Data sources and references used for nutrition, planting, and production calculations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(sources, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1, id: \.self) { item in
                        Text(item)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("References")
    }
}
