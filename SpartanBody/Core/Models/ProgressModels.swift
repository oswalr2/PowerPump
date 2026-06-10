import Foundation

struct WeightEntry: Identifiable, Codable {
    var id       = UUID()
    var date:    Date
    var weightKg: Double
}
