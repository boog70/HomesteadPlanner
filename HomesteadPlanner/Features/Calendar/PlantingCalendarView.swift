import SwiftUI

struct PlantingCalendarView: View {
    @Environment(\.appState) var appState

    var body: some View {
        Group {
            if let state = appState, let zone = state.zoneInfo?.zone {
                let cropIds = ProductionService.getEffectiveCropPlan(annualCalories: state.nutritionNeeds?.annualCalories ?? 0, annualProtein: state.nutritionNeeds?.annualProtein ?? 0, zone: zone, overrides: state.cropPlanOverrides).map { $0.crop.id }
                let events = CalendarService.getCalendarEvents(cropIds: cropIds, zone: zone)
                let byMonth = CalendarService.getEventsByMonth(events)
                List(1..<13, id: \.self) { m in
                    if let monthEvents = byMonth[m], !monthEvents.isEmpty {
                        Section(monthName(m)) {
                            ForEach(Array(monthEvents.enumerated()), id: \.offset) { _, e in
                                Text("\(e.cropName): \(e.eventType.rawValue) \(e.startDate)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .navigationTitle("Planting calendar")
            } else {
                ContentUnavailableView("Complete step 2", systemImage: "calendar")
            }
        }
    }

    private func monthName(_ m: Int) -> String {
        let names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return names.indices.contains(m) ? names[m] : ""
    }
}
