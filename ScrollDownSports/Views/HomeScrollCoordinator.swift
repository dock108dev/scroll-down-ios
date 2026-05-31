import Foundation

enum HomeProgrammaticScrollAnchor: Equatable {
    case center
    case top
    case bottom
}

struct HomeScrollRequest: Equatable {
    let anchorID: String
    let position: HomeProgrammaticScrollAnchor
    let validationKey: String
    let generation: Int
    let completedFilterSignature: String?
}

struct HomeScrollCoordinator {
    private(set) var generation = 0
    private(set) var pendingFilterSignature: String?
    private var lastAppliedInitialAnchorID: String?
    private var lastAppliedInitialKey: String?
    private var lastAppliedFilterKey: String?

    mutating func initialRequest(
        anchorID: String?,
        visibleCount: Int,
        filterSignature: String
    ) -> HomeScrollRequest? {
        guard let anchorID,
              visibleCount > 0 else {
            return nil
        }
        guard anchorID != lastAppliedInitialAnchorID else { return nil }

        let key = validationKey(reason: "initial", anchorID: anchorID, visibleCount: visibleCount, filterSignature: filterSignature)
        guard key != lastAppliedInitialKey else { return nil }
        lastAppliedInitialKey = key
        lastAppliedInitialAnchorID = anchorID
        return nextRequest(anchorID: anchorID, position: .bottom, validationKey: key, completedFilterSignature: nil)
    }

    mutating func filterChanged(
        to filterSignature: String,
        anchorID: String?,
        visibleCount: Int
    ) -> HomeScrollRequest? {
        invalidatePendingScrolls()
        pendingFilterSignature = filterSignature
        return filterRequest(anchorID: anchorID, visibleCount: visibleCount, filterSignature: filterSignature)
    }

    mutating func visibleCountChanged(
        anchorID: String?,
        visibleCount: Int,
        filterSignature: String
    ) -> HomeScrollRequest? {
        invalidatePendingScrolls()
        guard pendingFilterSignature == filterSignature else { return nil }
        return filterRequest(anchorID: anchorID, visibleCount: visibleCount, filterSignature: filterSignature)
    }

    mutating func invalidatePendingScrolls() {
        generation += 1
    }

    mutating func complete(_ request: HomeScrollRequest) {
        if pendingFilterSignature == request.completedFilterSignature {
            pendingFilterSignature = nil
        }
    }

    func isCurrent(_ request: HomeScrollRequest, currentValidationKey: String) -> Bool {
        request.generation == generation && request.validationKey == currentValidationKey
    }

    func validationKey(
        reason: String,
        anchorID: String,
        visibleCount: Int,
        filterSignature: String
    ) -> String {
        [reason, anchorID, String(visibleCount), filterSignature].joined(separator: ":")
    }

    private mutating func filterRequest(
        anchorID: String?,
        visibleCount: Int,
        filterSignature: String
    ) -> HomeScrollRequest? {
        guard let anchorID, visibleCount > 0 else { return nil }
        let key = validationKey(reason: "filter", anchorID: anchorID, visibleCount: visibleCount, filterSignature: filterSignature)
        guard key != lastAppliedFilterKey else { return nil }
        lastAppliedFilterKey = key
        return nextRequest(
            anchorID: anchorID,
            position: .top,
            validationKey: key,
            completedFilterSignature: filterSignature
        )
    }

    private mutating func nextRequest(
        anchorID: String,
        position: HomeProgrammaticScrollAnchor,
        validationKey: String,
        completedFilterSignature: String?
    ) -> HomeScrollRequest {
        generation += 1
        return HomeScrollRequest(
            anchorID: anchorID,
            position: position,
            validationKey: validationKey,
            generation: generation,
            completedFilterSignature: completedFilterSignature
        )
    }
}
