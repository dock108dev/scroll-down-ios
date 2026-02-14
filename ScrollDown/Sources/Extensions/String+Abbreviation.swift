import Foundation

extension String {
    /// Abbreviate a full name to first initial + last name.
    /// "Jayson Tatum" → "J. Tatum", "LeBron James Jr." → "L. James Jr."
    var abbreviatedPlayerName: String {
        let parts = split(separator: " ")
        guard parts.count >= 2 else { return self }
        let firstInitial = parts[0].prefix(1)
        let lastName = parts.dropFirst().joined(separator: " ")
        return "\(firstInitial). \(lastName)"
    }
}
