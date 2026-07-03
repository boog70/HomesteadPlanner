import Foundation

enum DataLoader {
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    static var crops: [Crop] = {
        guard let url = Bundle.main.url(forResource: "crops", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode([Crop].self, from: data) else {
            return []
        }
        return decoded
    }()

    static var fruits: [Fruit] = {
        guard let url = Bundle.main.url(forResource: "fruits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode([Fruit].self, from: data) else {
            return []
        }
        return decoded
    }()

    static var animals: [Animal] = {
        guard let url = Bundle.main.url(forResource: "animals", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode([Animal].self, from: data) else {
            return []
        }
        return decoded
    }()
}
