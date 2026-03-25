---
phase: 16-visual-polish
plan: 01
subsystem: infra
tags: [rename, ipc, keychain, migration, hooks, swift, python]

# Dependency graph
requires: []
provides:
  - "CC-Beeper brand applied across all source files: Package.swift, Swift sources, Python hooks, build scripts, tests"
  - "IPC directory migrated from ~/.claude/claumagotchi to ~/.claude/cc-beeper with backward-compatible migration logic"
  - "Keychain service migrated from com.claumagotchi.apikeys to com.vecartier.cc-beeper.apikeys with legacy fallback"
  - "Hook scripts renamed to cc-beeper-hook.py with updated IPC paths and pgrep targets"
  - "build.sh produces CC-Beeper.app with bundle ID com.vecartier.cc-beeper"
  - "Tests directory renamed to CC-BeeperTests, all test references updated"
affects: [17-distribution, any phase modifying hook scripts or IPC paths]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Migration-safe rename: legacy paths checked on first launch, contents copied to new paths, old paths deleted"
    - "Keychain migration: load() checks new service first, falls back to legacy service, migrates value, deletes legacy entry"

key-files:
  created:
    - Sources/CCBeeperApp.swift
    - Sources/cc-beeper-hook.py
    - hooks/cc-beeper-hook.py
  modified:
    - Package.swift
    - Sources/ClaudeMonitor.swift
    - Sources/HookInstaller.swift
    - Sources/KeychainService.swift
    - Sources/ContentView.swift
    - Sources/MenuBarPopoverView.swift
    - Sources/SettingsAboutSection.swift
    - Sources/TTSService.swift
    - Sources/VoiceService.swift
    - Sources/PixelTitle.swift
    - build.sh
    - setup.py
    - hooks/summary-hook.py
    - Tests/CC-BeeperTests/HookInstallerTests.swift
    - Tests/CC-BeeperTests/KeychainServiceTests.swift
    - Tests/CC-BeeperTests/AppMoverTests.swift

key-decisions:
  - "Pixel title on LCD screen updated from CLAUMAGOTCHI to CC-BEEPER with new pixel font glyphs for B, E, P, R, - characters"
  - "IPC migration runs in applicationDidFinishLaunching before PID check — ensures smooth handoff for existing users"
  - "Keychain migration uses lazy load-time migration (not startup sweep) — keys migrate on first use"
  - "Git repository directory name (Claumagotchi) retained as-is in fallback app paths — per CONTEXT.md decision"
  - "ClaudeMonitor.swift awaitingUserAction fix from orchestrator preserved — fix clears flag on pre_tool/post_tool/stop/session_end"

patterns-established:
  - "Migration pattern: check old path → copy to new → remove old (never destructive-first)"
  - "Test stubs embed full service implementation copy since @testable import unavailable for .executableTarget"

requirements-completed: [VFX-01, VFX-02, VFX-03]

# Metrics
duration: 7min
completed: 2026-03-25
---

# Phase 16 Plan 01: CC-Beeper Deep Rename Summary

**Complete Claumagotchi-to-CC-Beeper rename across all Swift sources, Python hooks, build scripts, and tests — with backward-compatible IPC directory and Keychain migration for existing users**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-25T09:32:45Z
- **Completed:** 2026-03-25T09:40:00Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments

- Renamed Package.swift (package + targets), ClaumagotchiApp.swift → CCBeeperApp.swift, and 8 other Swift source files
- Renamed both hook scripts (Sources/ and hooks/), updated build.sh, setup.py, summary-hook.py
- Renamed Tests/ClaumagotchiTests → Tests/CC-BeeperTests with all 3 test files updated
- Added IPC directory migration in AppDelegate.applicationDidFinishLaunching (claumagotchi → cc-beeper)
- Added Keychain migration in KeychainService.load() (com.claumagotchi.apikeys → com.vecartier.cc-beeper.apikeys)
- swift build succeeds; all 16 tests pass under CC-BeeperTests

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename Swift sources, Package.swift, add IPC migration** - `01d06a4` (feat)
2. **Task 2: Rename hook scripts, build scripts, tests; verify build** - `2fdcbf8` (feat)

## Files Created/Modified

- `Sources/CCBeeperApp.swift` - Renamed from ClaumagotchiApp.swift; struct CCBeeperApp; PID at cc-beeper path; IPC migration in applicationDidFinishLaunching
- `Package.swift` - Package name CC-Beeper, target CC-Beeper, test target CC-BeeperTests, resource cc-beeper-hook.py
- `Sources/ClaudeMonitor.swift` - ipcDir updated to ~/.claude/cc-beeper (awaitingUserAction fix preserved)
- `Sources/HookInstaller.swift` - ipcDir, hookScript, appPathFile, bundle resource name updated to cc-beeper paths
- `Sources/KeychainService.swift` - Service identifier updated with legacy migration in load()
- `Sources/ContentView.swift` - Quit menu item renamed
- `Sources/MenuBarPopoverView.swift` - ClaumagotchiApp → CCBeeperApp references
- `Sources/SettingsAboutSection.swift` - GitHub URL updated to cc-beeper repo
- `Sources/TTSService.swift` - Log path updated to /tmp/cc-beeper-tts.log
- `Sources/VoiceService.swift` - Log path updated to /tmp/cc-beeper-voice.log
- `Sources/PixelTitle.swift` - LCD title pixel art changed from CLAUMAGOTCHI to CC-BEEPER (added B, E, P, R, - glyphs)
- `Sources/cc-beeper-hook.py` - Full rename of claumagotchi-hook.py with all IPC/app references updated
- `hooks/cc-beeper-hook.py` - Same as Sources version
- `hooks/summary-hook.py` - SUMMARY_DIR updated to ~/.claude/cc-beeper
- `build.sh` - All app bundle references updated; CFBundleIdentifier com.vecartier.cc-beeper
- `setup.py` - All IPC/hook references updated to cc-beeper
- `Tests/CC-BeeperTests/HookInstallerTests.swift` - Hook filename references updated
- `Tests/CC-BeeperTests/KeychainServiceTests.swift` - Service identifier updated
- `Tests/CC-BeeperTests/AppMoverTests.swift` - App paths updated to CC-Beeper.app

## Decisions Made

- Pixel title on LCD updated from CLAUMAGOTCHI to CC-BEEPER: added new pixel font glyphs (B, E, P, R, dash) to PixelTitle.swift font dictionary
- IPC migration runs before PID check in applicationDidFinishLaunching to ensure existing users' events and sessions carry over
- Keychain migration is lazy (runs on first load() call per account), not an eagerly-swept startup migration
- Git repository directory name retained as "Claumagotchi" in fallback hook paths per CONTEXT.md ("Git repo stays as-is")
- ClaudeMonitor.swift awaitingUserAction fix from orchestrator preserved intact (clears flag on pre_tool/post_tool/stop/session_end events)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] Updated PixelTitle.swift LCD title from CLAUMAGOTCHI to CC-BEEPER**
- **Found during:** Task 1 (Swift source scan)
- **Issue:** PixelTitle.swift rendered "CLAUMAGOTCHI" pixel art on the LCD — not in the original task list but is a user-facing string
- **Fix:** Changed text to "CC-BEEPER" and added pixel font glyphs for B, E, P, R, - characters
- **Files modified:** Sources/PixelTitle.swift
- **Verification:** Build succeeds; new glyphs added to font dictionary
- **Committed in:** 01d06a4 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 - missing user-facing string update)
**Impact on plan:** Essential for brand consistency — LCD title was the most prominent user-facing Claumagotchi reference not covered by the task spec. No scope creep.

## Issues Encountered

None — plan executed smoothly. Build and tests both passed first try.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Complete CC-Beeper rename in place; all references updated
- Build system produces CC-Beeper binary under new Package.swift target name
- Existing users' IPC directories and Keychain entries will auto-migrate on first launch
- Ready for Phase 16 Plans 02 and 03 (remaining visual polish tasks)

---
*Phase: 16-visual-polish*
*Completed: 2026-03-25*
