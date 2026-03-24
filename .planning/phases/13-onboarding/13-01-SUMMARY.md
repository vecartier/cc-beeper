---
phase: 13-onboarding
plan: "01"
subsystem: onboarding
tags: [swift, hook-installation, binary-detection, appmover, package-swift, resources]

# Dependency graph
requires:
  - phase: 13-00
    provides: "XCTest test target + 3 stub test files in Tests/ClaumagotchiTests/"
provides:
  - "ClaudeDetector struct: finds claude binary via 4 search paths including nvm glob"
  - "HookInstaller struct: Swift reimplementation of setup.py — no python3 subprocess"
  - "AppMover struct: prompts to copy app to /Applications with App Translocation detection"
  - "claumagotchi-hook.py bundled as app resource via Package.swift"
affects: [13-02, 13-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static service struct pattern: pure static methods/properties, import Foundation only"
    - "Bundle resource lookup: Bundle.main.path(forResource:ofType:) for hook script"
    - "Cross-volume copy: fm.copyItem + fm.removeItem instead of fm.moveItem for DMG-to-Applications"

key-files:
  created:
    - Sources/ClaudeDetector.swift
    - Sources/HookInstaller.swift
    - Sources/AppMover.swift
    - Sources/claumagotchi-hook.py
  modified:
    - Package.swift
    - Tests/ClaumagotchiTests/ClaudeDetectorTests.swift
    - Tests/ClaumagotchiTests/HookInstallerTests.swift
    - Tests/ClaumagotchiTests/AppMoverTests.swift

key-decisions:
  - "Hook script copied into Sources/ (not referenced from hooks/ via ../) — SPM resource path must be within the target's path: directory"
  - "AppMover uses fm.copyItem as primary operation — fm.moveItem fails cross-volume from DMG; copyItem + removeItem works everywhere"
  - "ClaudeDetector searches nvm paths by scanning ~/.nvm/versions/node/ with contentsOfDirectory (newest version first) — PATH in macOS app is minimal, cannot use which"

patterns-established:
  - "Service types import Foundation only (no AppKit/SwiftUI) for testability — AppMover is the exception (requires AppKit for NSAlert)"
  - "Hook detection uses string-contains check on command field in settings.json hooks dict"

requirements-completed: [ONBD-02, ONBD-06]

# Metrics
duration: 3min
completed: 2026-03-24
---

# Phase 13 Plan 01: Onboarding Service Types Summary

**ClaudeDetector + HookInstaller (Swift setup.py reimplementation) + AppMover with App Translocation detection, plus claumagotchi-hook.py bundled as Package.swift resource**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-24T18:18:41Z
- **Completed:** 2026-03-24T18:21:54Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- ClaudeDetector finds the claude binary across 4 path strategies: `~/.local/bin`, Homebrew (Silicon + Intel), and nvm glob
- HookInstaller replicates all of setup.py in Swift: directory creation, bundle resource copy, permissions, 8-event settings.json mutation — no python3 subprocess
- AppMover handles /Applications check, dev-build skip, App Translocation guidance, and cross-volume copy from DMG
- claumagotchi-hook.py bundled as app resource via `resources: [.copy("claumagotchi-hook.py")]` in Package.swift; confirmed present in build bundle
- Test stubs replaced with real assertions: 10 tests pass via `swift test --filter ClaumagotchiTests`

## Task Commits

Each task was committed atomically:

1. **Task 1: Create ClaudeDetector and HookInstaller service types** - `8ede6f3` (feat)
2. **Task 2: Create AppMover and add hook script to Package.swift resources** - `051d004` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `Sources/ClaudeDetector.swift` - Binary detection: ~/.local/bin, Homebrew paths, nvm glob; claudeDirExists soft fallback
- `Sources/HookInstaller.swift` - setup.py in Swift: dir setup, bundle copy, 8-event settings.json mutation; InstallError.hookScriptNotInBundle
- `Sources/AppMover.swift` - /Applications check, .build/ skip, AppTranslocation guidance, copyItem cross-volume move + NSApp.terminate
- `Sources/claumagotchi-hook.py` - Hook script copied from hooks/ into Sources/ for Package.swift resource declaration
- `Package.swift` - Added `resources: [.copy("claumagotchi-hook.py")]` to executableTarget; testTarget preserved
- `Tests/ClaumagotchiTests/ClaudeDetectorTests.swift` - Real assertions: filesystem consistency, binary path existence check
- `Tests/ClaumagotchiTests/HookInstallerTests.swift` - Real assertions: isInstalled false/true cases, all 8 events covered
- `Tests/ClaumagotchiTests/AppMoverTests.swift` - Real assertions: 5 path-guard conditions without invoking NSAlert

## Decisions Made
- Hook script goes in Sources/ (not `../hooks/` relative path) — SPM requires resource paths to be within the target's `path:` directory; the `../hooks/` form is not supported
- AppMover uses `fm.copyItem` as primary move operation: `moveItem` fails with cross-device link error when copying from a mounted DMG volume to /Applications; `copyItem + removeItem` works universally
- Sorted newest-to-oldest in nvm version scan to prefer the user's active Node version

## Deviations from Plan

None - plan executed exactly as written. The `../hooks/claumagotchi-hook.py` resource path noted in the plan as potentially problematic was handled by copying the file into Sources/ as the plan's fallback path explicitly specified.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All three service types compile and are tested — Plan 02 (OnboardingView UI) can call ClaudeDetector.isInstalled, HookInstaller.install(), and AppMover.moveToApplicationsIfNeeded() directly
- Hook script is bundled: Bundle.main.path(forResource: "claumagotchi-hook", ofType: "py") will return a valid path at runtime
- Plan 02 should call AppMover.moveToApplicationsIfNeeded() in AppDelegate.applicationDidFinishLaunching before showing the onboarding window

---
*Phase: 13-onboarding*
*Completed: 2026-03-24*
