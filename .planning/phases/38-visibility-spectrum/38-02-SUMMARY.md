---
phase: 38-visibility-spectrum
plan: 02
subsystem: ui
tags: [swift, swiftui, macos, compact-view, window-resize, visibility-spectrum]

# Dependency graph
requires:
  - phase: 38-visibility-spectrum/38-01
    provides: smallShellImageName, 10 beeper-small-{color}.png assets, WidgetSize enum
  - phase: 37-permission-spectrum
    provides: PermissionPreset enum, widgetSize @Published property on ClaudeMonitor
provides:
  - CompactView.swift — small shell + LCD only widget (no buttons/LEDs/speaker)
  - 3-mode view routing in CCBeeperApp — Full/Compact/Menu
  - resizeMainWindow(to:) static helper with top-left anchoring
affects:
  - visual verification checkpoint (Task 2)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CompactView mirrors ContentView shell loading pattern using loadShellImage helper"
    - "Window routing via Group + if/else on monitor.widgetSize — both branches have WindowConfigurator"
    - "NSWindow top-left anchor: frame.origin.y += frame.height - size.height before setFrame"
    - "resizeMainWindow calls constrainToScreen after resize to prevent off-screen drift"

key-files:
  created:
    - Sources/Widget/CompactView.swift
  modified:
    - Sources/App/CCBeeperApp.swift

key-decisions:
  - "CompactView uses same ScreenView() as ContentView (per D-06) — identical LCD content in both modes"
  - "Both CompactView and ContentView branches include .background(WindowConfigurator()) to maintain floating/transparent window properties across view rebuilds"
  - "resizeMainWindow uses setFrame animate:true for smooth transitions per D-08"
  - "Window dimensions: Full=440x240 (360+80 padding x 160+80), Compact=300x193 (220+80 x 113+80)"

patterns-established:
  - "3-mode visibility: Full renders ContentView, Compact renders CompactView, Menu hides window"
  - "Size transitions: show/hide via existing helpers, resize via resizeMainWindow(to:)"

requirements-completed: [D-01, D-02, D-03, D-06, D-07, D-08, D-09, D-10]

# Metrics
duration: ~10min
completed: 2026-03-31
---

# Phase 38 Plan 02: Visibility Spectrum — CompactView and Window Routing Summary

**CompactView with small shell + LCD-only rendering, 3-mode view routing in CCBeeperApp, and top-left-anchored window resize for smooth Full/Compact/Menu transitions**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-31T07:55:00Z
- **Completed:** 2026-03-31T08:12:18Z
- **Tasks:** 1 auto + 1 checkpoint (pending visual verification)
- **Files modified:** 2

## Accomplishments
- Created CompactView.swift: 220x113pt small shell PNG with proportionally-placed 175x45pt LCD area, no buttons/LEDs/speaker grille
- Wired 3-mode view routing in CCBeeperApp — Group with if/else on monitor.widgetSize routes to CompactView vs ContentView, both with WindowConfigurator
- Added resizeMainWindow(to:) static helper: anchors top-left by adjusting frame.origin.y, calls constrainToScreen after resize
- Updated Size menu actions to call resizeMainWindow(440x240 for Full, 300x193 for Compact)
- Updated Sleep/Wake button to resize correctly to current mode on wake

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CompactView and wire 3-mode view routing with window resize** - `9a80dcb` (feat)

**Plan metadata:** pending (docs commit)

## Files Created/Modified
- `Sources/Widget/CompactView.swift` - Compact mode view: small shell PNG background, ScreenView LCD, no buttons/LEDs/speaker. Uses themeManager.smallShellImageName for theme-matched shell.
- `Sources/App/CCBeeperApp.swift` - 3-mode view routing (Group + conditional), resizeMainWindow static helper, updated Size menu and Sleep/Wake button

## Decisions Made
- CompactView uses the same `ScreenView()` as ContentView per D-06 — LCD content is identical in both modes; no code duplication
- Both branches in the Group conditional include `.background(WindowConfigurator())` to ensure floating/transparent window behavior persists across view switches (per RESEARCH.md anti-pattern note)
- Window dimensions derived from shell + 40pt padding on each side: Full = 360+80 x 160+80 = 440x240, Compact = 220+80 x 113+80 = 300x193
- `resizeMainWindow` uses `animate: true` for smooth transitions per D-08

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Cherry-picked Plan 01 source commits from parallel worktree**
- **Found during:** Task 1 setup
- **Issue:** Worktree branch `worktree-agent-a362329f` was at commit `7b0b648` (pre-Plan-01 state). Commits `8d54748` and `37f1ff5` (small shell assets + ThemeManager.smallShellImageName) existed on branch `worktree-agent-ae32d523` but had not been merged to main or this worktree. Plan 02 requires smallShellImageName.
- **Fix:** Cherry-picked both commits into this worktree branch before implementing Plan 02.
- **Files modified:** Sources/shells/beeper-small-*.png (10 files), Sources/Theme/ThemeManager.swift, Sources/Monitor/ClaudeMonitor.swift, Sources/Monitor/HTTPHookServer.swift
- **Verification:** `grep smallShellImageName Sources/Theme/ThemeManager.swift` confirmed present.
- **Committed in:** 93d2da6, 0fc19ad (cherry-picked Plan 01 commits)

---

**Total deviations:** 1 auto-fixed (1 blocking — missing dependency from parallel worktree)
**Impact on plan:** Cherry-pick was necessary prerequisite. No scope creep.

## Issues Encountered
- Parallel worktree branch for Plan 01 (`worktree-agent-ae32d523`) had not been merged to main. The `docs(38-01)` commit on main only included planning docs, not the source code changes. Cherry-picked the two feat/fix commits from Plan 01 to unblock Plan 02.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CompactView is built and wired; visual verification checkpoint (Task 2) is pending user review
- LCD alignment (x:24, y:23 offset) is the main calibration point — user should check if LCD content aligns with the screen cutout in the small shell PNG
- If LCD is misaligned, the offset in CompactView.swift line with `.offset(x: 24, y: 23)` needs adjustment

## Known Stubs
None - all data flows from existing ClaudeMonitor/ThemeManager state; no hardcoded placeholder values.

---
*Phase: 38-visibility-spectrum*
*Completed: 2026-03-31 (pending visual verification)*
