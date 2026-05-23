import Foundation

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

extension Array where Element == String? {
    var firstNonBlank: String? {
        for value in self {
            if let trimmed = value?.nilIfBlank {
                return trimmed
            }
        }
        return nil
    }
}
