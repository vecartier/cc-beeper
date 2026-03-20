---
phase: 02-reliability-performance
plan: 02
subsystem: ui
tags: [swiftui, nsimage, timer, canvas, color, hex-parsing, performance]

# Dependency graph
requires:
  - phase: 01-hardening
    provides: stable core event handling and state machine
provides:
  - Visibility-aware sprite animation (no CPU waste when window hidden)
  - Cached noise texture NSImage (one-time render, reused every frame)
  - Unified Color.hexComponents() for all hex parsing
affects: [03-ux-lift, any future theme or animation changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NSWindow.didChangeOcclusionStateNotification to gate animation increments"
    - "static let cached NSImage in SwiftUI View for deterministic one-time render"
    - "Color.hexComponents() shared helper to prevent duplicate parsing"

key-files:
  created: []
  modified:
    - Sources/ScreenView.swift
    - Sources/ContentView.swift
    - Sources/ThemeManager.swift
    - Sources/ClaudeMonitor.swift

key-decisions:
  - "Gate animFrame increment (not timer) — timer tick is negligible, Canvas re-render is not"
  - "Use NSWindow.didChangeOcclusionStateNotification for occlusion detection (handles minimize + hidden)"
  - "NSImage.lockFocus approach for NSImage render — matches existing SeededRNG pixel logic exactly"
  - "Color.hexComponents() returns (r, g, b) tuple — darken() applies factor, no code duplication"

patterns-established:
  - "Visibility gating: check state bool in timer callback, not connect/disconnect timer"
  - "Deterministic textures: render once to NSImage via static let, not Canvas per-frame"
  - "Shared color primitives: Color.hexComponents() as single source of truth for hex parsing"

requirements-completed: [REL-02, PERF-01, PERF-03]

# Metrics
duration: 6min
completed: 2026-03-20
---

# Phase 02 Plan 02: View-Layer Performance Summary

**Visibility-aware sprite timer, one-time cached NSImage noise texture, and unified Color.hexComponents() hex parser replacing two divergent implementations**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-03-20T11:02:19Z
- **Completed:** 2026-03-20T11:08:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Sprite animFrame no longer increments when window is occluded or hidden — Canvas re-renders stop entirely
- Noise texture rendered once at app startup via static NSImage, reused every frame (eliminates per-frame pixel loop)
- Single `Color.hexComponents()` method serves both `Color(hex:)` init and `ThemeManager.darken()` — no divergence possible

## Task Commits

Each task was committed atomically:

1. **Task 1: Pause sprite animation when hidden, cache noise texture** - `2ea4d4d` (feat)
2. **Task 2: Unify hex color parsing into single Color.hexComponents()** - `c85389e` (feat)

**Plan metadata:** committed with docs commit below

## Files Created/Modified
- `Sources/ScreenView.swift` - Added `isWindowVisible` state + `didChangeOcclusionStateNotification` observer to gate `animFrame` increments
- `Sources/ContentView.swift` - Replaced Canvas-based NoiseView with static NSImage cached at startup; added `Color.hexComponents()` static helper
- `Sources/ThemeManager.swift` - Rewrote `darken()` to delegate to `Color.hexComponents()` — no more Scanner/bit-shifting
- `Sources/ClaudeMonitor.swift` - Auto-fixed incomplete Timer-to-DispatchWorkItem refactor in `startIdleTimer()`

## Decisions Made
- Gating the `animFrame` increment rather than connecting/disconnecting the timer: the timer tick itself is negligible CPU; what's expensive is the Canvas re-render triggered by state change. The simpler gate approach achieves the performance goal with minimal structural change.
- NSImage.lockFocus for noise caching: matches the existing SeededRNG pixel loop exactly, just moves it from per-frame Canvas to a one-time static initializer.
- `Color.hexComponents()` returns a named tuple `(r:g:b:)` so `darken()` can apply a factor to each component without unpacking through Color.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed incomplete idleTimer-to-DispatchWorkItem refactor in ClaudeMonitor**
- **Found during:** Task 2 (build verification after hex parsing changes)
- **Issue:** `ClaudeMonitor.startIdleTimer()` still referenced `idleTimer` (removed property) after a partial rename to `idleWork: DispatchWorkItem?`. Build was broken with "cannot find 'idleTimer' in scope".
- **Fix:** Rewrote `startIdleTimer()` to cancel any existing `idleWork`, create a new `DispatchWorkItem`, store it in `idleWork`, and schedule via `DispatchQueue.main.asyncAfter`.
- **Files modified:** `Sources/ClaudeMonitor.swift`
- **Verification:** `swift build` succeeds with no errors
- **Committed in:** `c85389e` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — pre-existing bug exposed by build)
**Impact on plan:** Auto-fix required for build to succeed. No scope creep — fix completes an already-started refactor.

## Issues Encountered
- The partial Timer-to-DispatchWorkItem refactor in ClaudeMonitor was invisible until Task 2 triggered a full rebuild including that file. Task 1 only recompiled the two view files so the error was not surfaced.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- View layer performance hardened: animation, texture, and color parsing all optimized
- REL-02, PERF-01, PERF-03 requirements satisfied
- Phase 03 (UX lift) can proceed with stable, performant rendering foundation

---
*Phase: 02-reliability-performance*
*Completed: 2026-03-20*
