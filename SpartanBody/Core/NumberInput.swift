import Foundation

extension String {
    /// Parses a number typed on the decimal keypad. In es/fr/it/pt the keypad
    /// types "," as the decimal separator, which `Double(_:)` rejects.
    /// Returns nil for empty, malformed or non-finite input.
    var localizedDouble: Double? {
        let normalized = trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }
}
