# Suggested Commit Messages for Phase C

## Option 1: Single Commit

```
feat: Phase C - Timeline Usability Improvements

Transform the game timeline from a raw data dump into a readable,
explorable, and narrative experience.

Key improvements:
- Period/quarter grouping with collapsible sections
- Pagination for long PBP sequences (20 events per chunk)
- Moment summaries as narrative bridges between clusters
- Reveal-aware rendering (scores hidden by default)
- Context-aware empty states for partial/delayed PBP

Technical changes:
- Added PeriodGroup and MomentSummary structs
- Enhanced CompactMomentPbpViewModel with grouping and pagination
- Redesigned CompactMomentExpandedView with period sections
- Added comprehensive documentation in docs/PHASE_C.md

The timeline now feels like following a story, not reading a log file.

Closes: Phase C
See: docs/PHASE_C.md, PHASE_C_SUMMARY.md
```

---

## Option 2: Grouped Commits

### Commit 1: PBP Rendering
```
feat(timeline): add period grouping and pagination

- Group PBP events by period/quarter in CompactMomentPbpViewModel
- Add collapsible period sections with LIVE indicators
- Implement per-period pagination (20 events per chunk)
- Maintain stable chronological ordering from backend

Long games (100+ events) are now scannable without overwhelming UI.

Part of: Phase C (Timeline Usability)
```

### Commit 2: Moment Summaries
```
feat(timeline): add neutral moment summaries

- Generate narrative bridges between event clusters
- Insert summaries every ~15 events for sequences > 20
- Use neutral, observational language (no outcome spoilers)
- Add MomentSummaryCard component with distinct styling

Summaries provide context without revealing outcomes.
Timeline now reads like a story, not a log file.

Part of: Phase C (Timeline Usability)
```

### Commit 3: Reveal-Aware Rendering
```
feat(timeline): implement reveal-aware rendering

- Document reveal philosophy in PbpEvent model
- Scores present in model but not displayed by default
- Backend provides reveal-aware descriptions
- Prepare for future reveal toggles (Phase D)

Timeline is now spoiler-safe by default.

Part of: Phase C (Timeline Usability)
```

### Commit 4: Edge Cases & Documentation
```
docs: Phase C documentation and edge case handling

- Add comprehensive docs/PHASE_C.md
- Update CHANGELOG.md with Phase C changes
- Add context-aware empty states
- Handle partial/delayed PBP gracefully
- Add PHASE_C_SUMMARY.md

All Phase C objectives complete.

Closes: Phase C
```

---

## Recommended Approach

**Use Option 2 (Grouped Commits)** for better git history and easier code review.

Each commit is:
- Focused on a single concern
- Independently reviewable
- Properly documented
- Part of a clear narrative

---

## Git Commands

```bash
# Stage and commit PBP rendering changes
git add ScrollDown/Sources/ViewModels/CompactMomentPbpViewModel.swift
git add ScrollDown/Sources/Screens/Game/CompactMomentExpandedView.swift
git commit -m "feat(timeline): add period grouping and pagination

- Group PBP events by period/quarter in CompactMomentPbpViewModel
- Add collapsible period sections with LIVE indicators
- Implement per-period pagination (20 events per chunk)
- Maintain stable chronological ordering from backend

Long games (100+ events) are now scannable without overwhelming UI.

Part of: Phase C (Timeline Usability)"

# Stage and commit moment summaries
git add ScrollDown/Sources/ViewModels/CompactMomentPbpViewModel.swift
git add ScrollDown/Sources/Screens/Game/CompactMomentExpandedView.swift
git commit -m "feat(timeline): add neutral moment summaries

- Generate narrative bridges between event clusters
- Insert summaries every ~15 events for sequences > 20
- Use neutral, observational language (no outcome spoilers)
- Add MomentSummaryCard component with distinct styling

Summaries provide context without revealing outcomes.
Timeline now reads like a story, not a log file.

Part of: Phase C (Timeline Usability)"

# Stage and commit reveal-aware rendering
git add ScrollDown/Sources/Models/PbpEvent.swift
git add ScrollDown/Sources/ViewModels/CompactMomentPbpViewModel.swift
git add ScrollDown/Sources/Screens/Game/CompactMomentExpandedView.swift
git commit -m "feat(timeline): implement reveal-aware rendering

- Document reveal philosophy in PbpEvent model
- Scores present in model but not displayed by default
- Backend provides reveal-aware descriptions
- Prepare for future reveal toggles (Phase D)

Timeline is now spoiler-safe by default.

Part of: Phase C (Timeline Usability)"

# Stage and commit documentation
git add docs/PHASE_C.md
git add docs/CHANGELOG.md
git add docs/README.md
git add PHASE_C_SUMMARY.md
git add COMMIT_MESSAGE.md
git commit -m "docs: Phase C documentation and edge case handling

- Add comprehensive docs/PHASE_C.md
- Update CHANGELOG.md with Phase C changes
- Add context-aware empty states
- Handle partial/delayed PBP gracefully
- Add PHASE_C_SUMMARY.md

All Phase C objectives complete.

Closes: Phase C"
```

---

## Notes

- All commits follow Conventional Commits format
- Commit messages explain WHY, not just WHAT
- Each commit is atomic and independently reviewable
- Documentation commit includes all Phase C docs
- Ready for code review and merge

---

## After Committing

1. **Test in Xcode:**
   - Build and run on simulator
   - Test with long game (100+ events)
   - Test with short game (<20 events)
   - Test empty PBP state
   - Verify period grouping works
   - Verify pagination works
   - Verify moment summaries appear

2. **Code Review:**
   - Review inline comments
   - Verify reveal philosophy is clear
   - Check for any missed edge cases
   - Validate documentation completeness

3. **Merge:**
   - Merge to main/develop branch
   - Tag as `phase-c-complete`
   - Update project board/issues

4. **Next Steps:**
   - Begin Phase D planning
   - Gather beta feedback on timeline usability
   - Consider additional refinements based on testing
