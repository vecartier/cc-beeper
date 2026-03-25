---
phase: 16-visual-polish
plan: 02
subsystem: ui
tags: [animation, vibration, polish, vfx, swiftui, macos]

# Dependency graph
requires: ["16-01"]
provides:
  - "Pixel character bounce animation on state change (VFX-01): bounceOffset state + onChange(of: monitor.state)"
  - "Dark mode rendering verified across all 10 shell variants (VFX-02): pixel grid 0.25/0.12 opacity correct"
  - "Cancellable vibration with cancelVibration() and isVibrating flag (VFX-03)"
  - "Click-to-stop vibration via onTapGesture in ContentView"
  - "Drag-aware shaking: shake frames skipped when left mouse button held"
  - "All buttons verified using ImageButtonStyle PNG-swap with matching pressed PNGs"
affects: [17-distribution]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DispatchWorkItem array for cancellable async shake loops"
    - "NSEvent.pressedMouseButtons & 1 to detect drag during shake"
    - "bounceOffset CGFloat state + onChange two-phase animation (easeOut up, easeIn back)"

key-files:
  created: []
  modified:
    - Sources/ScreenContentView.swift
    - Sources/BuzzService.swift
    - Sources/ContentView.swift

key-decisions:
  - "Text swap remains instant (no animation on Text views) — only PixelCharacterView bounces"
  - "cancelVibration() does NOT invalidate reminderTimer — 15s future reminders continue per CONTEXT.md"
  - "Reset after shake uses current window position (not captured origin) to preserve drag position"
  - "Dark mode inner shadow opacity (0.15) kept as-is — acceptable for LCD retro feel"
  - "ActionButton.swift verified correct as-is — all pressed PNGs present in Sources/buttons/"

patterns-established:
  - "DispatchWorkItem cancellation pattern: store items in array, cancel all on interrupt"
  - "Drag-during-shake detection: NSEvent.pressedMouseButtons bit 0 check inside each shake frame"

requirements-completed: [VFX-01, VFX-02, VFX-03]

# Metrics
duration: 2min
completed: 2026-03-25
---

# Phase 16 Plan 02: Visual Polish — Bounce, Vibration Fixes, Button Feedback Summary

**Pixel character bounces on state change (VFX-01), vibration is click-stoppable and drag-aware (VFX-03), dark mode verified across all 10 shells (VFX-02)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-25T09:43:30Z
- **Completed:** 2026-03-25T09:45:21Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `bounceOffset` state to ScreenContentView; `.onChange(of: monitor.state)` triggers a -4pt easeOut bounce then easeIn return in 250ms total
- Applied `.offset(y: bounceOffset)` to PixelCharacterView only — text swaps remain instant
- Verified dark mode pixel grid opacity (0.25 dark / 0.12 light) and vignette (0.25) already correct — no code changes for VFX-02
- Rewrote BuzzService shake loop to use `[DispatchWorkItem]` for full cancellability
- Added `isVibrating` flag and `cancelVibration()` public method to BuzzService
- Drag-aware: each shake frame checks `NSEvent.pressedMouseButtons & 1 == 0` before moving window
- Reset uses `window.frame.origin` at completion time (not captured origin) — correct after user drag
- Added `.onTapGesture` in ContentView calling `buzzService.cancelVibration()` when vibrating
- Verified all button pressed PNGs exist: pill-check-pressed, pill-cross-pressed, record-pressed, record-recording-pressed, terminal-pressed, sound-pressed, mute-pressed

## Task Commits

Each task was committed atomically:

1. **Task 1: Pixel character bounce + dark mode verification** — `9778433` (feat)
2. **Task 2: Cancellable vibration, drag-aware shaking, click-to-stop** — `7d1f536` (feat)

## Files Created/Modified

- `Sources/ScreenContentView.swift` — Added `bounceOffset` state, `.offset(y: bounceOffset)` on PixelCharacterView, `.onChange(of: monitor.state)` bounce trigger
- `Sources/BuzzService.swift` — Rewritten shake loop with DispatchWorkItem array, `isVibrating` property, `cancelVibration()` method, drag detection via NSEvent.pressedMouseButtons
- `Sources/ContentView.swift` — Added `.onTapGesture` to stop vibration on click

## Decisions Made

- Text swap instant (no animation on Text views) — only PixelCharacterView bounces per CONTEXT.md decision
- cancelVibration() does NOT stop reminderTimer — click cancels current buzz only, 15s reminders continue per CONTEXT.md
- Reset after shake uses current frame.origin (not captured) — preserves drag-during-shake window position
- Dark mode inner shadow opacity (0.15) correct as-is for retro LCD feel
- ActionButton.swift already fully correct: all buttons use ImageButtonStyle PNG-swap, all 7 pressed PNGs verified present

## Deviations from Plan

None — plan executed exactly as written.

Both VFX-01 and VFX-03 had clear implementations specified; VFX-02 was verification-only with no code changes needed.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- All 3 VFX requirements complete (VFX-01, VFX-02, VFX-03)
- Phase 16 Plan 03 (Settings sidebar) is the final plan in this phase
- Build clean, no warnings added

---
*Phase: 16-visual-polish*
*Completed: 2026-03-25*

## Self-Check: PASSED

- Sources/ScreenContentView.swift: FOUND
- Sources/BuzzService.swift: FOUND
- Sources/ContentView.swift: FOUND
- .planning/phases/16-visual-polish/16-02-SUMMARY.md: FOUND
- Commit 9778433: FOUND
- Commit 7d1f536: FOUND
- bounceOffset in ScreenContentView: FOUND
- cancelVibration in BuzzService: FOUND
- cancelVibration in ContentView: FOUND
