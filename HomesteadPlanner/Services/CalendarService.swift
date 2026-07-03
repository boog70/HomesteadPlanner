import Foundation

private let monthNames: [String: Int] = [
    "January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6,
    "July": 7, "August": 8, "September": 9, "October": 10, "November": 11, "December": 12
]

private let shortMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

enum CalendarService {
    private static func getPlantingZone(_ zone: String) -> String {
        let zoneMap: [String: String] = [
            "3a": "5a", "3b": "5a", "4a": "5a", "4b": "5a", "5a": "5a",
            "5b": "6a", "6a": "6a", "6b": "6b", "7a": "7a", "7b": "7b", "8a": "8a", "8b": "8b",
            "9a": "9a", "9b": "9b", "10a": "10a", "10b": "10a", "11a": "10a", "11b": "10a"
        ]
        return zoneMap[zone.replacingOccurrences(of: " ", with: "")] ?? "7a"
    }

    private static func parseMonth(_ monthStr: String) -> Int {
        let first = monthStr.prefix(while: { $0.isLetter })
        return monthNames[String(first)] ?? 1
    }

    private static func parseDateRange(_ dateStr: String) -> (startMonth: Int, startDay: Int, endMonth: Int, endDay: Int) {
        let pattern = #"^(\w+)\s*(\d+)?\s*[-–]\s*(\w+)\s*(\d+)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let m = regex.firstMatch(in: dateStr, range: NSRange(dateStr.startIndex..., in: dateStr)) else {
            return (1, 1, 12, 31)
        }
        func at(_ i: Int) -> String? {
            guard m.numberOfRanges > i, let r = Range(m.range(at: i), in: dateStr) else { return nil }
            return String(dateStr[r])
        }
        return (
            parseMonth(at(1) ?? "January"),
            Int(at(2) ?? "1") ?? 1,
            parseMonth(at(3) ?? "December"),
            Int(at(4) ?? "28") ?? 28
        )
    }

    static func getCalendarEvents(cropIds: [String], zone: String, year: Int = Calendar.current.component(.year, from: Date())) -> [CalendarEvent] {
        let plantZone = getPlantingZone(zone)
        let crops = DataLoader.crops
        var events: [CalendarEvent] = []
        for crop in crops {
            if !cropIds.isEmpty && !cropIds.contains(crop.id) { continue }
            guard let windows = crop.plantingWindows[plantZone] else { continue }
            let successionCount = min(crop.successionPlantings ?? 1, 6)

            func addPlantingAndHarvest(startMonth: Int, startDay: Int, endMonth: Int, endDay: Int, season: String) {
                let startDate = DateComponents(year: year, month: startMonth, day: startDay)
                let endDate = DateComponents(year: year, month: endMonth, day: endDay)
                var cal = Calendar.current
                cal.timeZone = TimeZone.current
                guard let sd = cal.date(from: startDate), let ed = cal.date(from: endDate) else { return }
                let range = ed.timeIntervalSince(sd)
                for s in 0..<successionCount {
                    let frac = successionCount > 1 ? Double(s) / Double(successionCount - 1) : 0
                    let plantTime = sd.addingTimeInterval(frac * max(0, range))
                    let components = cal.dateComponents([.month, .day], from: plantTime)
                    let plantMonth = components.month ?? 1
                    let plantDay = components.day ?? 1
                    let plantStr = "\(shortMonthNames[plantMonth - 1]) \(plantDay), \(year)"
                    events.append(CalendarEvent(cropId: crop.id, cropName: crop.name, eventType: .plant, startDate: plantStr, endDate: plantStr, notes: successionCount > 1 ? "\(season) #\(s + 1)" : season))
                    if crop.daysToMaturity > 0 {
                        let harvestDate = cal.date(byAdding: .day, value: crop.daysToMaturity, to: plantTime) ?? plantTime
                        let hComp = cal.dateComponents([.month, .year], from: harvestDate)
                        let hm = shortMonthNames[(hComp.month ?? 1) - 1]
                        let hy = hComp.year ?? year
                        let lastDay = (cal.range(of: .day, in: .month, for: harvestDate)?.count) ?? 28
                        events.append(CalendarEvent(cropId: crop.id, cropName: crop.name, eventType: .harvest, startDate: "\(hm) 1, \(hy)", endDate: "\(hm) \(lastDay), \(hy)", notes: "~\(crop.daysToMaturity)d"))
                    }
                }
            }

            if let spring = windows.spring {
                let range = parseDateRange("\(spring.start) – \(spring.end)")
                addPlantingAndHarvest(startMonth: range.startMonth, startDay: range.startDay, endMonth: range.endMonth, endDay: range.endDay, season: "Spring")
            }
            if let fall = windows.fall {
                let range = parseDateRange("\(fall.start) – \(fall.end)")
                addPlantingAndHarvest(startMonth: range.startMonth, startDay: range.startDay, endMonth: range.endMonth, endDay: range.endDay, season: "Fall")
            }
        }
        return events
    }

    static func getEventsByMonth(_ events: [CalendarEvent]) -> [Int: [CalendarEvent]] {
        let monthNamesMap: [String: Int] = [
            "Jan": 1, "January": 1, "Feb": 2, "February": 2, "Mar": 3, "March": 3, "Apr": 4, "April": 4,
            "May": 5, "Jun": 6, "June": 6, "Jul": 7, "July": 7, "Aug": 8, "August": 8, "Sep": 9, "September": 9,
            "Oct": 10, "October": 10, "Nov": 11, "November": 11, "Dec": 12, "December": 12
        ]
        var byMonth: [Int: [CalendarEvent]] = [:]
        for m in 1...12 { byMonth[m] = [] }
        for e in events {
            let first = e.startDate.prefix(while: { $0.isLetter })
            let month = monthNamesMap[String(first)] ?? 1
            byMonth[month, default: []].append(e)
        }
        return byMonth
    }
}
