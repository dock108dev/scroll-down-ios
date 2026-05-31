import Foundation

extension HomeViewModel {
    var homeFilterSignature: String {
        [
            league.rawValue,
            teamQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        ].joined(separator: "|")
    }

    var firstVisibleHomeAnchorID: String? {
        filteredHomeSections.firstRenderedAnchorID
    }

    func isRenderableHomeAnchorID(_ anchorID: String) -> Bool {
        filteredHomeSections.renderedAnchorIDs.contains(anchorID)
    }
}

extension Array where Element == HomeSection {
    var firstRenderedAnchorID: String? {
        for section in self {
            switch section {
            case .pinned(let pinned) where !pinned.games.isEmpty:
                return "pinned"
            case .timeline(let timeline):
                if let first = timeline.dateSections.first(where: { !$0.games.isEmpty }) {
                    return first.id
                }
            default:
                continue
            }
        }
        return nil
    }

    var renderedAnchorIDs: Set<String> {
        reduce(into: Set<String>()) { result, section in
            switch section {
            case .pinned(let pinned):
                if !pinned.games.isEmpty {
                    result.insert("pinned")
                }
            case .timeline(let timeline):
                if timeline.dateSections.contains(where: { !$0.games.isEmpty }) {
                    result.insert("timeline")
                }
                timeline.dateSections
                    .filter { !$0.games.isEmpty }
                    .forEach { result.insert($0.id) }
                timeline.dateSections
                    .flatMap(\.games)
                    .forEach { result.insert($0.homeAnchorID) }
            }
        }
    }
}
