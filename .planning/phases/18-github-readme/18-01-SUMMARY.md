---
phase: 18-github-readme
plan: "01"
subsystem: ui
tags: [readme, docs, markdown, github, landing-page]

# Dependency graph
requires:
  - phase: 17-distribution
    provides: DMG release workflow and GitHub Releases URL
  - phase: 16-visual-polish
    provides: CC-Beeper brand, 10 color shell themes, IPC path /tmp/cc-beeper/
  - phase: 13-onboarding
    provides: onboarding wizard (replaced setup.py / Terminal commands)
provides:
  - Landing-page README.md replacing outdated Claumagotchi developer README
  - All 5 GH requirements covered (GH-01 through GH-05)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Centered GitHub README hero section using HTML <p align='center'> tags"
    - "HTML table for 4-column feature grid in GitHub Markdown"
    - "shields.io static badges for macOS version, Swift version, license"

key-files:
  created: []
  modified:
    - README.md

key-decisions:
  - "All 5 GH sections written in a single task — disclaimer, contributing, and license included in initial write rather than appended separately"
  - "Claumagotchi repo URL retained as-is (product name is CC-Beeper; repo rename is out of scope)"

patterns-established:
  - "GH-01: Hero section with docs/demo.gif placeholder and docs/cover.png cover image"
  - "GH-02: HTML table for scannable 4-pillar feature grid"
  - "GH-03: DMG download (recommended) + make install (from source) in Install section"
  - "GH-04: docs/cover.png reference for 10-shell theme showcase"
  - "GH-05: Contributing guide (fork/branch/PR + hooks docs link) + MIT License section"

requirements-completed: [GH-01, GH-02, GH-03, GH-04, GH-05]

# Metrics
duration: 2min
completed: 2026-03-25
---

# Phase 18 Plan 01: GitHub README Summary

**Landing-page README replacing the Claumagotchi developer README with a product storefront — hero section, 4-pillar feature grid, LCD states table, install paths, shell theme showcase, and full OSS boilerplate.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-25T12:58:03Z
- **Completed:** 2026-03-25T12:59:24Z
- **Tasks:** 2 (Tasks 1-2 auto; Task 3 is a human-verify checkpoint)
- **Files modified:** 1

## Accomplishments

- Replaced a 150-line developer README referencing Claumagotchi, setup.py, and the old egg UI with a 137-line landing page focused on CC-Beeper
- Hero section with demo.gif placeholder, CC-Beeper H1, shields.io badges, and prominent DMG download link
- 4-pillar HTML table feature grid (Monitor, Voice, Permissions, Themes) plus bullet list of secondary features
- LCD states table (THINKING / DONE / NEEDS YOU), ASCII IPC diagram, cover.png placeholder for shell themes
- Contributing guide with hooks docs link, updated YOLO mode disclaimer, MIT license section

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the landing-page README body** - `aff3829` (feat)
2. **Task 2: Add contributing guide, disclaimer, and license sections** - `aff3829` (included in Task 1 commit — all content written in single pass)

## Files Created/Modified

- `/Users/vcartier/Desktop/Claumagotchi/README.md` - Completely rewritten as product landing page

## Decisions Made

- All 5 GH sections (hero, features, install, contributing, license) written in a single pass during Task 1 rather than appending in Task 2 — Task 2 verified the final state rather than making separate edits. No content was missing; the commit captures both tasks.
- "Claumagotchi" only appears in GitHub repo URLs (https://github.com/vecartier/Claumagotchi and `cd Claumagotchi`) — this is correct, as the repo name has not been renamed. Product name "CC-Beeper" is used everywhere in prose.

## Deviations from Plan

None - plan executed exactly as written. All acceptance criteria met in the initial write.

## Issues Encountered

None.

## User Setup Required

Two image placeholders require manual action before the README is fully rendered on GitHub:
- Drop your cover image at `docs/cover.png` — shows all 10 color shells, will render in the Shell Themes section
- Record a screen capture and drop it at `docs/demo.gif` — hero image placeholder, renders at top of README

No code changes needed — just drop the files and they appear automatically.

## Next Phase Readiness

Phase 18 is the final phase of v3.0 Public Launch. After Task 3 (human-verify checkpoint) is approved, the README is ready for public launch.

- Cover image (`docs/cover.png`) must be dropped in for the Shell Themes section to render
- Demo GIF (`docs/demo.gif`) can be added later — placeholder comment explains this to viewers

---
*Phase: 18-github-readme*
*Completed: 2026-03-25*

## Self-Check: PASSED

- README.md: FOUND at /Users/vcartier/Desktop/Claumagotchi/README.md
- 18-01-SUMMARY.md: FOUND at .planning/phases/18-github-readme/18-01-SUMMARY.md
- Commit aff3829: FOUND — feat(18-01): write landing-page README for CC-Beeper
