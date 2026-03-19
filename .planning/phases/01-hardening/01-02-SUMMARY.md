---
phase: 01-hardening
plan: 02
subsystem: security
tags: [python, ipc, permissions, hook, security]

# Dependency graph
requires: []
provides:
  - Default-deny permission response in claumagotchi-hook.py
  - Whitelist validation for decision values
  - Freshness check rejecting stale response.json files via mtime comparison
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fail-closed default: missing/invalid data in IPC response defaults to deny"
    - "Freshness guard: compare response file mtime against pending_ts with 2s tolerance"

key-files:
  created: []
  modified:
    - hooks/claumagotchi-hook.py

key-decisions:
  - "Default decision changed from allow to deny — hook fails closed on any ambiguous data (BUG-03/SEC-01)"
  - "Whitelist guard normalizes non-string or unexpected decision values to deny rather than passing them through"
  - "2-second mtime tolerance for freshness check to account for filesystem/clock drift without opening meaningful attack window"

patterns-established:
  - "Fail-closed IPC: any malformed or missing key in permission response results in deny"
  - "Stale response detection: file mtime < pending_ts - 2s triggers removal and continued polling"

requirements-completed: [BUG-03, SEC-01, SEC-03]

# Metrics
duration: 2min
completed: 2026-03-19
---

# Phase 1 Plan 02: IPC Hook Hardening Summary

**Default-deny permission response with whitelist validation and mtime-based freshness guard rejecting pre-written response.json files**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-19T14:43:36Z
- **Completed:** 2026-03-19T14:46:26Z
- **Tasks:** 2 of 2
- **Files modified:** 1

## Accomplishments

- Changed permission response default from "allow" to "deny" — the hook now fails closed when the decision key is missing from response.json
- Added whitelist guard normalizing unexpected decision values (True, 1, "yes", null) to deny
- Captured `pending_ts` as an explicit variable and used it in both the pending.json payload and the freshness comparison
- Added mtime-based freshness check: responses written more than 2 seconds before the pending request was issued are removed and ignored, defeating pre-written response attacks

## Task Commits

Each task was committed atomically:

1. **Task 1: Change default decision from allow to deny and add whitelist validation** - `a238bdc` (fix)
2. **Task 2: Add response freshness check using file mtime** - `9fbd34b` (fix)

**Plan metadata:** _(final docs commit hash will appear after state update)_

## Files Created/Modified

- `hooks/claumagotchi-hook.py` - Default-deny, whitelist guard, pending_ts capture, mtime freshness check

## Decisions Made

- Used `resp.get("decision", "deny")` as the primary change — simplest correct fix for BUG-03/SEC-01
- Whitelist guard placed immediately after the get() call so all code paths downstream see only "allow" or "deny"
- 2-second tolerance (`pending_ts - 2`) chosen as a practical allowance for filesystem timestamp resolution and minor clock skew; a pre-written attack file will have mtime many seconds earlier, making the tolerance inconsequential

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BUG-03, SEC-01, and SEC-03 are resolved; hook security posture hardened
- Phase 1 plan 2 of 2 complete — phase 01-hardening is now fully executed
- Phase 2 (reliability/performance) can begin: REL-01 file watcher fragility is the highest-priority item

---
*Phase: 01-hardening*
*Completed: 2026-03-19*
