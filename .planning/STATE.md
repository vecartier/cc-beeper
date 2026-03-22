---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Voice Loop
status: phase-complete
stopped_at: Completed 09-03-PLAN.md
last_updated: "2026-03-22T13:56:29.643Z"
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-21)

**Core value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow
**Current focus:** Phase 09 — ui-controls

## Current Position

Phase: 09 (ui-controls) — COMPLETE (3/3 plans)
Next: Phase 10 — Voice Input + Injection

## Accumulated Context

### Decisions

- v1.1 complete: All 4 phases shipped (hardening, reliability, UX, notifications)
- v2.0 previously attempted (phases 5-8) and reverted — voice/settings/summary unreliable
- VoiceLoop prototype validates: voice input, auto-speak, hook-based summary, CGEvent injection
- Lessons: use regular window (not NSPanel), nil audio format, Apple Dev signing, nil CGEvent source
- Extracted types to separate files following SwiftUI Pro one-type-per-file rule
- isActive initialized in init body after setupFileWatcher so didSet only fires on external mutation
- Hotkey guard pendingPermission moved into A/D cases only — S and G work without pending permission
- thinkingStartTime only resets when transitioning INTO thinking (session state was not .thinking)
- [Phase 09-ui-controls]: 4 buttons always visible in fixed layout — YOLO mode only affects screen text, not button visibility
- [Phase 09-ui-controls]: ScreenContentView drives state-specific status text; ScreenView is a thin passthrough wrapper
- [Phase 09-ui-controls]: Show/Hide Widget and Power Off are independent controls — Show/Hide preserves isActive, Power Off sets it false
- [Phase 09-ui-controls]: Menu bar icon greyed only when powered off (EggIconState.hidden) — not when widget is merely hidden

### Pending Todos

None yet.

### Blockers/Concerns

- Audio engine corruption from rapid start/stop — mitigated by recreating AVAudioEngine each session
- Accessibility permission requires Apple Development signing to persist across rebuilds
- Apple Intelligence availability varies — need graceful fallback when unavailable

## Session Continuity

Last session: 2026-03-22T13:56:29.633Z
Stopped at: Completed 09-03-PLAN.md
Resume file: None
