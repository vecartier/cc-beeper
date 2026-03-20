---
phase: 03-ux-enhancements
plan: 02
subsystem: ui
tags: [hotkeys, accessibility, NSEvent, AXIsProcessTrusted, ApplicationServices]

# Dependency graph
requires:
  - phase: 03-01
    provides: pendingPermission published property, respondToPermission() method
provides:
  - Global key event monitor (NSEvent.addGlobalMonitorForEvents) for system-wide Option+A/D
  - Local key event monitor (NSEvent.addLocalMonitorForEvents) for companion window focus
  - Accessibility permission gate (AXIsProcessTrusted) with lazy re-install on permission events
  - "Enable Global Hotkeys..." menu item when Accessibility not yet granted
affects: []

# Tech tracking
tech-stack:
  added: [ApplicationServices framework]
  patterns:
    - Global + local monitor pair for full keyboard coverage (any foreground app + own window)
    - pendingPermission != nil guard makes hotkeys inert when no permission pending
    - globalKeyMonitor == nil guard prevents double-install across repeated permission events
    - Lazy monitor install: setupGlobalHotkeys called from init AND both permission branches

key-files:
  created: []
  modified:
    - Sources/ClaudeMonitor.swift
    - Sources/ClaumagotchiApp.swift

key-decisions:
  - "Global + local monitor pair ensures hotkeys fire whether companion window is focused or not"
  - "pendingPermission != nil gate makes Option+A/D completely inert outside permission prompts — avoids terminal Meta key conflicts"
  - "Only .option modifier accepted (not Cmd+Option, Ctrl+Option) — flags == .option strict equality"
  - "setupGlobalHotkeys called on each permission event for lazy install after Accessibility granted post-launch"
  - "DispatchQueue.main.async in handleHotKey — global monitor callback may not arrive on main thread"

patterns-established:
  - "Lazy accessibility install: call setupGlobalHotkeys() from permission events so granting permission mid-session activates hotkeys on next event"

requirements-completed: [UX-04]

# Metrics
duration: 3min
completed: 2026-03-20
---

# Phase 03 Plan 02: Global Hotkeys Summary

**System-wide Option+A / Option+D permission shortcuts via NSEvent global+local monitor pair gated on AXIsProcessTrusted**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-20T13:52:56Z
- **Completed:** 2026-03-20T13:55:57Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Global key monitor fires when any other app is frontmost — user can approve/deny without leaving terminal or editor
- Local key monitor fires when companion window has focus — consistent behavior regardless of focus state
- Accessibility permission gate silently skips monitor install until user grants access
- "Enable Global Hotkeys..." menu item appears only when Accessibility not granted, clicking opens System Preferences
- Monitors cleaned up in deinit — no leaks on app termination

## Task Commits

Each task was committed atomically:

1. **Task 1: Add global and local hotkey monitors with accessibility gate** - `271305b` (feat)

**Plan metadata:** (to be added after docs commit)

## Files Created/Modified

- `Sources/ClaudeMonitor.swift` - Added ApplicationServices import, globalKeyMonitor/localKeyMonitor properties, setupGlobalHotkeys(), handleHotKey(), deinit cleanup, and setupGlobalHotkeys() calls from init + both permission branches
- `Sources/ClaumagotchiApp.swift` - Added ApplicationServices import and "Enable Global Hotkeys..." conditional menu item

## Decisions Made

- Global + local monitor pair: global fires for other apps, local fires when companion window is focused — both needed for complete coverage
- `flags == .option` strict equality rejects Cmd+Option, Ctrl+Option, Shift+Option — prevents conflicts with common terminal shortcuts
- `pendingPermission != nil` guard is the key safety mechanism: hotkeys do nothing outside active permission prompts
- Lazy monitor install via calling `setupGlobalHotkeys()` from permission event branches handles the common case where users grant Accessibility after first launch

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

Accessibility permission required for global hotkeys. The "Enable Global Hotkeys..." menu item guides users to System Preferences > Privacy & Security > Accessibility. Once granted, the next permission event will automatically install the monitors.

## Next Phase Readiness

- Phase 03 complete — both plans executed
- Phase 04 (notifications) can begin; no dependencies on this plan's internals
- All UX-04 requirements satisfied

---
*Phase: 03-ux-enhancements*
*Completed: 2026-03-20*
