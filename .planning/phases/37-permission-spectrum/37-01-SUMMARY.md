---
phase: 37-permission-spectrum
plan: "01"
subsystem: permission-preset-backend
tags: [permissions, settings, sprites, classification, tests]
dependency_graph:
  requires: []
  provides: [PermissionPreset, PermissionPresetWriter, AskUserQuestion-classification, rabbit-sprite]
  affects: [ClaudeMonitor, HookInstaller, ScreenView]
tech_stack:
  added: []
  patterns: [atomic-write-tmp-rename, replicated-type-tests]
key_files:
  created:
    - Sources/Monitor/PermissionPresetWriter.swift
    - Tests/CC-BeeperTests/PermissionPresetWriterTests.swift
  modified:
    - Sources/Monitor/ClaudeMonitor.swift
    - Sources/Monitor/HookInstaller.swift
    - Sources/Widget/ScreenView.swift
decisions:
  - "PermissionPreset enum drives all permission mode I/O — replaces raw PermissionMode string matching"
  - "AskUserQuestion in PermissionRequest routes to NEEDS INPUT, not APPROVE? (D-04)"
  - ".sortedKeys removed from both HookInstaller install() and uninstall() to prevent key reordering (D-03)"
  - "uninstall() made atomic (tmp + rename) to match install() pattern"
  - "Rabbit sprite is 14x12 static, not animated — Plan 02 wires it to PixelCharacterView"
metrics:
  duration_seconds: 477
  completed_date: "2026-03-30"
  tasks_completed: 3
  tasks_total: 3
  files_changed: 5
---

# Phase 37 Plan 01: Permission Preset Backend Summary

**One-liner:** 4-tier PermissionPreset enum with atomic settings.json writer, AskUserQuestion classification fix, and YOLO rabbit sprite.

## What Was Built

### Task 1: PermissionPreset enum + PermissionPresetWriter + HookInstaller fix

Created `Sources/Monitor/PermissionPresetWriter.swift`:
- `PermissionPreset` enum with 4 cases: `.cautious`, `.relaxed`, `.trusted`, `.yolo`
- Each case maps to the correct `permission_mode` string and `allowedTools` array per D-01
- `PermissionPresetWriter.readCurrentPreset()` infers the current preset by examining settings.json fields
- `PermissionPresetWriter.isSettingsMalformed()` detects invalid JSON without crashing
- `PermissionPresetWriter.applyPreset(_:)` modifies only `permission_mode` and `allowedTools`, writes atomically via tmp+rename

Fixed `Sources/Monitor/HookInstaller.swift`:
- Removed `.sortedKeys` from `install()` (D-03 bug fix)
- Removed `.sortedKeys` from `uninstall()` (D-03 bug fix)
- Made `uninstall()` write atomically (tmp+rename), matching `install()` pattern

### Task 2: AskUserQuestion classification + rabbit sprite

Updated `Sources/Monitor/ClaudeMonitor.swift`:
- Added `case "PermissionRequest":` branch to `handleHookPayload` switch
- `AskUserQuestion` in a PermissionRequest routes to `needs_input` (NEEDS INPUT on LCD) — always surfaces regardless of mode
- All other PermissionRequest tools route to `permission_prompt` with YOLO suppression check

Updated `Sources/Widget/ScreenView.swift`:
- Added `Sprites.rabbit` — 14x12 static pixel art sprite with long ears and round face
- Plan 02 will wire this to `PixelCharacterView` when `isYolo == true`

### Task 3: Tests

Created `Tests/CC-BeeperTests/PermissionPresetWriterTests.swift` with 12 XCTest tests:
- Preset enum shape (4 cases)
- Each preset writes correct `permission_mode` and `allowedTools`
- Atomic write preserves all other settings.json fields
- Malformed JSON detection (positive and negative)
- Preset reading from various settings.json states
- AskUserQuestion classification logic

All 53 tests pass (12 new + 41 pre-existing).

## Commits

| Hash | Message |
|------|---------|
| `4170aa6` | feat(37-01): add PermissionPreset enum and PermissionPresetWriter, fix HookInstaller sortedKeys bug |
| `762a6b1` | feat(37-01): fix AskUserQuestion classification and add YOLO rabbit sprite |
| `266758f` | test(37-01): add PermissionPresetWriterTests with 12 tests |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Made uninstall() atomic**
- **Found during:** Task 1
- **Issue:** Plan specified fixing the prettyPrinted+sortedKeys bug in uninstall(), but the plan also noted uninstall() needed atomic writing. The existing code used `try writeData.write(to:)` directly without tmp+rename.
- **Fix:** Added tmp+rename pattern to uninstall() to match install() behavior — consistent atomicity throughout
- **Files modified:** Sources/Monitor/HookInstaller.swift
- **Commit:** 4170aa6

None other — plan executed as written.

## Known Stubs

- `Sprites.rabbit` is defined but not yet wired to `PixelCharacterView.spritesForState()` — the wiring happens in Plan 02 via the `isYolo` flag. The sprite itself is complete and tested implicitly via the 14x12 dimension verification.

## Self-Check: PASSED

- [x] Sources/Monitor/PermissionPresetWriter.swift — FOUND
- [x] Tests/CC-BeeperTests/PermissionPresetWriterTests.swift — FOUND
- [x] Commits 4170aa6, 762a6b1, 266758f — all in git log
- [x] swift build — Build complete
- [x] swift test — 53 tests, 0 failures
