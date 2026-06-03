# Maintenance Notes

This file records current maintenance constraints that are useful to contributors and verifiable from the repository.

## Generated And Local-Only Files

Do not edit generated artifacts as source of truth:

- `ScrollDownSports.xcodeproj` is generated from `project.yml`.
- `.build/`, `build/`, `DerivedData/`, `xcuserdata/`, and `.aidlc/` are ignored local or generated state.
- `Config/Local.xcconfig` is ignored and may contain private machine-specific backend or signing values.

Repository scripts and CI use `Scripts/local_gate.sh`; it regenerates the Xcode project before build and test gates.

## Source File Size

No maintained production Swift source files are currently over 500 lines after
the source-only split pass. Tests and shell scripts are intentionally excluded
from that source-size target.

Large tests and `Scripts/local_gate.sh` can remain large when they share
fixtures, destinations, and result-bundle handling. Split those only when a
test or script change creates a clear ownership boundary.

## Documentation Policy

Root documentation is intentionally limited to `README.md`. Supporting documentation belongs under `docs/`.

Documentation should describe current, code-verifiable behavior. Product ideas, speculative designs, old audit trails, and generated working notes should not be kept as project docs unless they are clearly tied to current code or active contributor workflow.

## Validation Commands

Useful documentation-maintenance checks:

```sh
git ls-files '*.md'
find ScrollDownSports -type f -name '*.swift' -print0 | xargs -0 wc -l | awk '$1 > 500 {print}'
find ScrollDownSportsTests ScrollDownSportsUITests Scripts -type f \( -name '*.swift' -o -name '*.sh' \) -print0 | xargs -0 wc -l | sort -nr | head -40
rg -n "README\\.md|docs/.*\\.md" project.yml Scripts Config .github ScrollDownSports ScrollDownSportsTests ScrollDownSportsUITests
```
