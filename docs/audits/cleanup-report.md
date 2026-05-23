# Cleanup Audit

This audit records the current cleanup diff that source comments may reference. It is an audit note, not product or operator documentation.

## Current Cleanup Diff

- `ScrollDownSports/Models/DisplayStringUtilities.swift`: Made `Array<String?>.firstNonBlank` the canonical optional-string display helper.
- `ScrollDownSports/Rendering/EventLabelResolver.swift`: Removed the local duplicate `firstNonBlank` helper and now uses the shared display utility.
- `ScrollDownSports/Rendering/SportPresentations.swift`: Removed the local duplicate `firstNonBlank` helper and now uses the shared display utility.
- `ScrollDownSports/Models/SDADomainMapper.swift`: Removed the local duplicate `firstNonBlank` helper and now uses the shared display utility.
- `ScrollDownSports/Views/GameDetailView.swift`: Moved pure scroll/read/visibility helpers out of the SwiftUI view body file.
- `ScrollDownSports/Views/GameDetailViewSupport.swift`: Added the extracted detail-screen helper types and pure scroll logic.
- `ScrollDownSports.xcodeproj/project.pbxproj`: Regenerated with XcodeGen so `GameDetailViewSupport.swift` is included in the app target.

## Dead code removed

- Removed three duplicate private `Array where Element == String?` extensions from `EventLabelResolver`, `SportPresentations`, and `SDADomainMapper`.

## Splits/consolidations

- Consolidated optional display-string selection into `DisplayStringUtilities.swift`.
- Split `GameDetailView` by moving non-view helper logic into `GameDetailViewSupport.swift` without changing view state ownership or public API signatures.

## Files still >500 LOC

- `ScrollDownSports/Views/GameDetailView.swift` remains 619 LOC after extraction. The remaining size is justified for this pass because its scroll proxy actions, `@State` fields, refresh hooks, and preference handlers share SwiftUI view-local state. A larger split would require a state-owner redesign; the code location has a one-line size note pointing back to this section.

## Consistency edits

- `ScrollDownSports/Models/DisplayStringUtilities.swift`: Co-located blank-string normalization and first-nonblank selection.
- `ScrollDownSports/Rendering/EventLabelResolver.swift`: Uses the shared first-nonblank helper.
- `ScrollDownSports/Rendering/SportPresentations.swift`: Uses the shared first-nonblank helper.
- `ScrollDownSports/Models/SDADomainMapper.swift`: Uses the shared first-nonblank helper.
- `ScrollDownSports/Views/GameDetailView.swift`: Keeps only view-owned state and imperative scroll actions.
- `ScrollDownSports/Views/GameDetailViewSupport.swift`: Holds detail-screen helper types and pure helper functions.

## Validation

- Current documentation-pass validation is recorded in `docs/audits/docs-consolidation.md`.

## Escalations

- None.
