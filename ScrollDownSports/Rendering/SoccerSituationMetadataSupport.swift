import Foundation

func soccerValue(for key: String, in metadata: [String: JSONValue]) -> JSONValue? {
    if let value = metadata[key] { return value }
    let normalizedKey = soccerNormalized(key)
    return metadata.first { soccerNormalized($0.key) == normalizedKey }?.value
}

func soccerObject(_ keys: [String], in metadata: [String: JSONValue]) -> [String: JSONValue]? {
    for key in keys {
        if case .object(let value)? = soccerValue(for: key, in: metadata) {
            return value
        }
    }
    return nil
}

func soccerText(_ keys: [String], in metadata: [String: JSONValue]) -> String? {
    for key in keys {
        if let value = soccerValue(for: key, in: metadata)?.textValue?.nilIfBlank {
            return value
        }
    }
    return nil
}

func soccerNumber(_ keys: [String], in metadata: [String: JSONValue]) -> Double? {
    for key in keys {
        guard let value = soccerValue(for: key, in: metadata) else { continue }
        switch value {
        case .number(let number):
            return number
        case .string(let text):
            if let number = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return number
            }
        default:
            continue
        }
    }
    return nil
}

func soccerInteger(_ keys: [String], in metadata: [String: JSONValue]) -> Int? {
    for key in keys {
        guard let value = soccerValue(for: key, in: metadata) else { continue }
        switch value {
        case .number(let number) where number.rounded() == number:
            return Int(number)
        case .string(let text):
            if let integer = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return integer
            }
        default:
            continue
        }
    }
    return nil
}

func soccerBool(_ keys: [String], in metadata: [String: JSONValue]) -> Bool? {
    for key in keys {
        guard let value = soccerValue(for: key, in: metadata) else { continue }
        switch value {
        case .bool(let bool):
            return bool
        case .string(let text):
            switch soccerNormalized(text) {
            case "true", "yes":
                return true
            case "false", "no":
                return false
            default:
                continue
            }
        default:
            continue
        }
    }
    return nil
}

func soccerNormalizedCoordinate(_ keys: [String], in metadata: [String: JSONValue], coordinateSystem: String?) -> Double? {
    guard let value = soccerNumber(keys, in: metadata) else { return nil }
    switch soccerNormalized(coordinateSystem) {
    case "normalized_zero_to_hundred", "normalizedzerotohundred", "zero_to_hundred":
        return min(max(value / 100, 0), 1)
    case "normalized_zero_to_one", "normalizedzerotoone", "zero_to_one", "":
        return min(max(value, 0), 1)
    default:
        return nil
    }
}

func soccerNormalized(_ value: String?) -> String {
    value?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "_")) ?? ""
}
