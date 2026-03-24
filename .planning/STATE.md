---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Public Launch
status: unknown
stopped_at: Completed 14-01-PLAN.md
last_updated: "2026-03-24T20:24:39.790Z"
progress:
  total_phases: 7
  completed_phases: 2
  total_plans: 8
  completed_plans: 7
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-24)

**Core value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow
**Current focus:** Phase 14 — Menu Bar Popover

## Current Position

Phase: 14 (Menu Bar Popover) — EXECUTING
Plan: 1 of 2

## Performance Metrics

**Velocity:**

- Total plans completed (v3.0): 0
- Prior milestone (v2.0 Voice Loop): 6 plans across phases 9-11

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

*Updated after each plan completion*
| Phase 12-code-quality P01 | 10 | 2 tasks | 13 files |
| Phase 12-code-quality P02 | 3 | 2 tasks | 5 files |
| Phase 13-onboarding P00 | 2 | 1 tasks | 4 files |
| Phase 13-onboarding P01 | 3 | 2 tasks | 8 files |
| Phase 13-onboarding P02 | 3 | 2 tasks | 9 files |
| Phase 13-onboarding P03 | 25 | 2 tasks | 1 files |
| Phase 14-menu-bar-popover P01 | 2 | 2 tasks | 6 files |

## Accumulated Context

### Decisions

- v3.0-pre: Code Beeper UI redesign done in manual session (horizontal pager, PNG buttons, 8 shells, LEDs, vibration, marquee text)
- Window-based vibration prevents sub-pixel blur on retina (not view offset)
- LED pulse uses Timer toggle (not SwiftUI animation) to avoid compositing bleed
- Voice recording switching to Groq Whisper (SFSpeechRecognizer flaky on macOS)
- DMG + GitHub Releases chosen over App Store (no overhead, broadest reach)
- [Phase 12-code-quality]: Bundle.main.resourcePath-only image loading — no fallback to developer source paths
- [Phase 12-code-quality]: Delete legacy shell-*.png (9 files) — replaced by beeper-*.png in v3 redesign
- [Phase 12-code-quality]: Package.swift exclude: shells, buttons, shell.svg — suppress 36 unhandled files warning
- [Phase 12-code-quality]: BuzzService takes vibrationEnabled/soundEnabled as parameters — no direct ClaudeMonitor reference, one-directional dependency
- [Phase 12-code-quality]: AppDelegate colocated with @main ClaumagotchiApp — acceptable exception to one-type-per-file rule
- [Phase 13-onboarding]: testTarget has no dependencies on executable target — @testable import not supported for .executableTarget; stubs use XCTest only
- [Phase 13-onboarding]: Hook script copied into Sources/ (not ../hooks/ path) — SPM resource path must be within target's path: directory
- [Phase 13-onboarding]: AppMover uses fm.copyItem as primary operation — fm.moveItem fails cross-volume from DMG
- [Phase 13-onboarding]: ClaudeDetector scans ~/.nvm/versions/node/ with contentsOfDirectory sorted newest-first — PATH in macOS app is minimal
- [Phase 13-onboarding]: NotificationManager removed in coordinated sweep: deleted file + removed 4 call sites + notificationsEnabled + Toggle from menu
- [Phase 13-onboarding]: Deep links live in OnboardingViewModel methods; step views call viewModel.open*Settings() — correct encapsulation
- [Phase 13-onboarding]: Color.accentColor (not .accent) for foregroundStyle — ShapeStyle has no .accent member on macOS 26
- [Phase 13-onboarding]: @Environment(\.openWindow) must live in App struct not AppDelegate — AppDelegate is not in the SwiftUI environment
- [Phase 14-menu-bar-popover]: MenuBarExtra uses .window style (not .menu) to render SwiftUI popover instead of native dropdown
- [Phase 14-menu-bar-popover]: Settings window scene added alongside existing main/onboarding windows with id: settings

### Pending Todos

None yet.

### Blockers/Concerns

- Notarization requires Apple Developer Program ($99/yr) — may need alternative if not enrolled
- VOICE-06 (Groq API key onboarding prompt) bridges Phase 13 and 15 — Phase 13 UI wires to Phase 15 Keychain service; plan Phase 15 before finalizing Phase 13 onboarding steps

## Session Continuity

Last session: 2026-03-24T20:24:39.786Z
Stopped at: Completed 14-01-PLAN.md
Resume file: None
