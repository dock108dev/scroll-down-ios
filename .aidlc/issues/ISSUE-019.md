# ISSUE-019: Make navigation and filters opaque to prevent header ghosting

**Priority**: medium
**Labels**: visual, navigation, header
**Dependencies**: ISSUE-001
**Status**: implemented

## Description

Fix the broken-looking header/blur treatment as its own visual behavior issue. Discovery says the app currently relies on native SwiftUI navigation bars, `FilterHeader` scrolls inside content, and material backgrounds can allow ghosting. Use `.aidlc/research/sticky-header-nav-treatment.md`: keep `NavigationStack`, make native navigation bars explicitly opaque via toolbar background, move home filters into a `safeAreaInset` sticky header, and standardize top bar spacing/buttons.

## Acceptance Criteria

- [ ] Root and detail navigation bars use an explicit opaque or mostly opaque background and do not show scrolling content behind title/buttons.
- [ ] Home league/team filters are removed from the scrolling list body and placed in a reserved top `safeAreaInset` or equivalent non-ghosting header area.
- [ ] The sticky/filter header uses opaque surfaces, clear separator treatment, and stable spacing instead of translucent material over moving rows.
- [ ] Detail toolbar buttons use consistent sizing, labels/accessibility, and spacing after the persistent pin/live controls are separated.
- [ ] Scrolling home and detail content cannot visibly pass behind readable nav title or controls.

## Implementation Notes


Attempt 1: Made root/detail navigation bars opaque, moved Home filters into an opaque safeAreaInset sticky header, standardized refresh toolbar sizing/labels, and added navigation chrome invariant tests.