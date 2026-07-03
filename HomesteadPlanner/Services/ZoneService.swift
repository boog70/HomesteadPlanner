import Foundation

struct FrostDataEntry: Codable {
    var lastSpringFrost: String
    var firstFallFrost: String
    var lastSpringFrostDayOfYear: Int
    var firstFallFrostDayOfYear: Int
}

private let zoneOrder = ["3a", "3b", "4a", "4b", "5a", "5b", "6a", "6b", "7a", "7b", "8a", "8b", "9a", "9b", "10a", "10b", "11a", "11b"]

private let tempRanges: [String: String] = [
    "3a": "-40 to -35°F", "3b": "-35 to -30°F", "4a": "-30 to -25°F", "4b": "-25 to -20°F",
    "5a": "-20 to -15°F", "5b": "-15 to -10°F", "6a": "-10 to -5°F", "6b": "-5 to 0°F",
    "7a": "0 to 5°F", "7b": "5 to 10°F", "8a": "10 to 15°F", "8b": "15 to 20°F",
    "9a": "20 to 25°F", "9b": "25 to 30°F", "10a": "30 to 35°F", "10b": "35 to 40°F",
    "11a": "40 to 45°F", "11b": "45 to 50°F"
]

enum ZoneService {
    private static var frostData: [String: FrostDataEntry] = {
        guard let url = Bundle.main.url(forResource: "frostDates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: FrostDataEntry].self, from: data) else {
            return [:]
        }
        return decoded
    }()

    private static func parseZoneNum(_ zone: String) -> Double {
        let trimmed = zone.trimmingCharacters(in: .whitespaces).lowercased()
        let digits = trimmed.filter { $0.isNumber }
        guard let n = Int(digits) else { return 6 }
        var num = Double(n)
        if trimmed.hasSuffix("b") { num += 0.5 }
        return num
    }

    private static func getClosestZone(_ zone: String) -> String {
        if frostData[zone] != nil { return zone }
        let num = parseZoneNum(zone)
        var closest = "7a"
        var minDiff = 99.0
        for z in zoneOrder {
            guard frostData[z] != nil else { continue }
            let diff = abs(parseZoneNum(z) - num)
            if diff < minDiff { minDiff = diff; closest = z }
        }
        return closest
    }

    static func getZoneInfo(_ zone: String) -> ZoneInfo? {
        let key = getClosestZone(zone)
        guard let data = frostData[key] else { return nil }
        let growingDays = data.firstFallFrostDayOfYear - data.lastSpringFrostDayOfYear
        return ZoneInfo(
            zone: key,
            temperatureRange: tempRanges[key] ?? "varies",
            lastSpringFrost: data.lastSpringFrost,
            firstFallFrost: data.firstFallFrost,
            lastSpringFrostDayOfYear: data.lastSpringFrostDayOfYear,
            firstFallFrostDayOfYear: data.firstFallFrostDayOfYear,
            growingSeasonDays: max(0, growingDays)
        )
    }

    static func fetchZoneByZip(_ zip: String) async -> String? {
        let cleaned = zip.filter { $0.isNumber }.prefix(5)
        guard cleaned.count == 5 else { return nil }
        let urlStr = "https://phzmapi.org/\(cleaned).json"
        guard let url = URL(string: urlStr) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let zone = json["zone"] as? String {
                return zone
            }
        } catch {}
        return nil
    }

    static func getClosestZoneForCalendar(_ zone: String) -> String {
        let key = getClosestZone(zone)
        let num = parseZoneNum(key)
        if num <= 5.5 { return "5a" }
        if num <= 6.5 { return num <= 6 ? "6a" : "6b" }
        if num <= 7.5 { return num <= 7 ? "7a" : "7b" }
        if num <= 8.5 { return num <= 8 ? "8a" : "8b" }
        if num <= 9.5 { return num <= 9 ? "9a" : "9b" }
        return "10a"
    }
}
