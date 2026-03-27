---
phase: 27-stt-reliability
plan: 02
subsystem: hooks
tags: [python, hooks, permissions, claude-code, ipc]

# Dependency graph
requires:
  - phase: 27-stt-reliability
    provides: Research identifying permission_mode fast-path fix (FIX2-05)
provides:
  - permission_mode fast-path in cc-beeper-hook.py handle_permission()
  - Non-default permission modes (acceptEdits, bypassPermissions, auto, dontAsk, plan) return allow immediately
affects: [27-stt-reliability]

# Tech tracking
tech-stack:
  added: []
  patterns: [early-return guard for non-default permission modes before blocking IPC write]

key-files:
  created: []
  modified:
    - Sources/cc-beeper-hook.py
    - hooks/cc-beeper-hook.py

key-decisions:
  - "permission_mode fast-path inserted at very top of handle_permission() before all IPC writes — default mode blocking poll loop completely unchanged"

patterns-established:
  - "Pattern: Check permission_mode before any IPC side-effect — allows future modes to be handled defensively without updating multiple code paths"

requirements-completed: [FIX2-05]

# Metrics
duration: 1min
completed: 2026-03-27
---

# Phase 27 Plan 02: STT Reliability — Permission Mode Fast-Path Summary

**Eliminated false-positive "Needs you!" states by short-circuiting handle_permission() for non-default permission modes before any IPC write occurs.**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-27T15:48:45Z
- **Completed:** 2026-03-27T15:49:31Z
- **Tasks:** 1 completed
- **Files modified:** 2

## Accomplishments

- Added `permission_mode` fast-path at the very top of `handle_permission()` in `cc-beeper-hook.py`
- When Claude Code runs in `acceptEdits`, `bypassPermissions`, `auto`, `dontAsk`, or `plan` mode, the hook now returns `allow` immediately without writing `pending.json`, without appending a `permission` event to `events.jsonl`, and without entering the 55-second poll loop
- Default mode (`"default"`) continues to block and wait for user Allow/Deny response exactly as before
- Both `Sources/cc-beeper-hook.py` and `hooks/cc-beeper-hook.py` kept identical via `cp`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add permission_mode fast-path to handle_permission()** - `92c6d00` (fix)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `Sources/cc-beeper-hook.py` - Added 16-line fast-path block at top of handle_permission(); existing default-mode logic unchanged
- `hooks/cc-beeper-hook.py` - Identical copy of Sources/ hook (cp'd after edit)

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- `Sources/cc-beeper-hook.py` exists and contains fast-path: confirmed
- `hooks/cc-beeper-hook.py` exists and is identical: confirmed (diff produces no output)
- Python syntax valid: confirmed (ast.parse exits 0)
- `permission_mode` appears 3 times: confirmed
- `permission_mode != "default"` guard present: confirmed
- `Auto-approved` message present: confirmed
- Fast-path before `tool = data.get(...)`: confirmed (line 264 vs 278)
- `PERMISSION_TIMEOUT` still present: confirmed
- Commit `92c6d00` exists: confirmed
