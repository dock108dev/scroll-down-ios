import Foundation

func normalizedSituationMetadataKey(_ value: String?) -> String {
    value?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "_")) ?? ""
}

func situationMetadataValue(for key: String, in metadata: [String: JSONValue]) -> JSONValue? {
    if let value = metadata[key] { return value }
    let normalizedKey = normalizedSituationMetadataKey(key)
    return metadata.first { normalizedSituationMetadataKey($0.key) == normalizedKey }?.value
}

func situationMetadataObject(_ keys: [String], in metadata: [String: JSONValue]) -> [String: JSONValue]? {
    for key in keys {
        if case .object(let value)? = situationMetadataValue(for: key, in: metadata) {
            return value
        }
    }
    return nil
}

func situationMetadataObjectValue(_ keys: [String], in metadata: [String: JSONValue]) -> JSONValue? {
    keys.compactMap { situationMetadataValue(for: $0, in: metadata) }.first
}

func situationMetadataText(_ keys: [String], in metadata: [String: JSONValue]) -> String? {
    for key in keys {
        if let value = situationMetadataValue(for: key, in: metadata)?.textValue?.nilIfBlank {
            return value
        }
    }
    return nil
}

func situationMetadataNumber(_ keys: [String], in metadata: [String: JSONValue]) -> Double? {
    for key in keys {
        guard let value = situationMetadataValue(for: key, in: metadata) else { continue }
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

func situationMetadataInteger(_ keys: [String], in metadata: [String: JSONValue]) -> Int? {
    for key in keys {
        if let value = situationMetadataValue(for: key, in: metadata).flatMap(situationInteger(from:)) {
            return value
        }
    }
    return nil
}

func situationInteger(from value: JSONValue) -> Int? {
    switch value {
    case .number(let number) where number.rounded() == number:
        return Int(number)
    case .string(let text):
        return Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    default:
        return nil
    }
}

func situationMetadataBool(_ keys: [String], in metadata: [String: JSONValue]) -> Bool? {
    for key in keys {
        guard let value = situationMetadataValue(for: key, in: metadata) else { continue }
        switch value {
        case .bool(let bool):
            return bool
        case .number(0):
            return false
        case .number(1):
            return true
        default:
            continue
        }
    }
    return nil
}

func situationParticipantRole(from value: String) -> GameParticipantRole? {
    switch normalizedSituationMetadataKey(value) {
    case "home":
        return .home
    case "away", "visitor", "road":
        return .away
    default:
        return nil
    }
}
