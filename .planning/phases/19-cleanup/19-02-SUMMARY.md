---
phase: 19-cleanup
plan: 02
subsystem: cleanup
tags: [swift, python, keychain, macos, migration]

# Dependency graph
requires:
  - phase: 19-cleanup-01
    provides: Claumagotchi laptop-wide purge context (plan 01)
provides:
  - Zero Claumagotchi references in all Swift, Python, plist, and config files in repo
  - KeychainService with single query (no legacy migration fallback)
  - CCBeeperApp without IPC directory migration method
  - uninstall.py with no legacy path constants
  - Claumagotchi.app bundle removed from repo root
  - xcschememanagement.plist key renamed to CC-Beeper
affects: [19-cleanup, CLN-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Clean break pattern: migration code removed once old data confirmed migrated"

key-files:
  created: []
  modified:
    - Sources/KeychainService.swift
    - Sources/CCBeeperApp.swift
    - uninstall.py
    - .swiftpm/xcode/xcuserdata/vcartier.xcuserdatad/xcschemes/xcschememanagement.plist

key-decisions:
  - "CLN-02: Zero Claumagotchi matches in all production code; .planning/ historical docs left intact"
  - "xcschememanagement.plist is gitignored — fix applied on disk only, not committed to repo"

patterns-established:
  - "Migration code removed after sufficient deployment time (clean break over backward compat)"

requirements-completed: [CLN-02]

# Metrics
duration: 5min
completed: 2026-03-25
---

# Phase 19 Plan 02: Claumagotchi Purge (Repo Code) Summary

**Deleted legacy Claumagotchi.app bundle, stripped Keychain migration fallback, removed IPC migration method, cleaned uninstall.py legacy paths, renamed xcscheme key — zero Claumagotchi matches in all production files**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-25T16:37:00Z
- **Completed:** 2026-03-25T16:41:48Z
- **Tasks:** 2
- **Files modified:** 4 (+ 1 gitignored plist)

## Accomplishments
- Deleted Claumagotchi.app bundle (entire .app at repo root with Info.plist + binary)
- Stripped legacy Keychain migration from KeychainService.swift — load() now does one SecItemCopyMatching query against com.vecartier.cc-beeper.apikeys only
- Removed migrateIPCDirectoryIfNeeded() method and call from CCBeeperApp.swift
- Removed LEGACY_IPC_DIR, LEGACY_HOOK_SCRIPT constants and all legacy loops from uninstall.py
- Renamed xcschememanagement.plist key from Claumagotchi.xcscheme_^#shared#^_ to CC-Beeper.xcscheme_^#shared#^_ on disk
- Full repo content sweep: zero matches in *.swift, *.py, *.sh, *.json, *.yaml, *.plist outside .planning/
- swift build succeeds: Build complete!

## Task Commits

Each task was committed atomically:

1. **Task 1: Delete legacy .app bundle and remove Claumagotchi migration code** - `f147990` (fix)
2. **Task 2: Sweep entire repo, fix .swiftpm plist, clean .build, and verify build** - `e228970` (chore, empty — plist gitignored)

## Files Created/Modified
- `Sources/KeychainService.swift` - Removed legacyService constant and entire legacy Keychain migration block; load() now has single SecItemCopyMatching query
- `Sources/CCBeeperApp.swift` - Removed // MARK: - IPC Migration section including migrateIPCDirectoryIfNeeded() method and its call in applicationDidFinishLaunching
- `uninstall.py` - Removed LEGACY_IPC_DIR and LEGACY_HOOK_SCRIPT constants; simplified hook removal and IPC directory cleanup to single paths; removed claumagotchi-hook.py filter from hook cleaning logic
- `.swiftpm/.../xcschememanagement.plist` - Key renamed on disk (file is gitignored, not committed)

## Decisions Made
- xcschememanagement.plist is in .gitignore — fix was applied on disk. The key rename is effective for local Xcode usage but will not appear in git history. This is expected behavior.
- .planning/ docs retain ~962 historical Claumagotchi mentions by design — these are historical records, not production code.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- .swiftpm/ directory is gitignored, so the xcschememanagement.plist key rename could not be committed. Fix was applied on disk. Noted in task 2 commit message.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CLN-02 requirement satisfied: zero Claumagotchi matches in production code
- Phase 19 complete if plan 01 is also done
- Phase 20 (Fix TTS) can proceed

## Self-Check: PASSED

All files confirmed present. Both commits verified in git log.

---
*Phase: 19-cleanup*
*Completed: 2026-03-25*
