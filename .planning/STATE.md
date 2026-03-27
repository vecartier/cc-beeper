---
gsd_state_version: 1.0
milestone: v3.1
milestone_name: Polish & Fixes
status: executing
stopped_at: Completed 27-stt-reliability-01-PLAN.md
last_updated: "2026-03-27T15:54:12.355Z"
last_activity: 2026-03-27
progress:
  total_phases: 26
  completed_phases: 24
  total_plans: 52
  completed_plans: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow
**Current focus:** Phase 27 — STT Reliability

## Current Position

Phase: 27 (STT Reliability) — EXECUTING
Plan: 2 of 2
Status: Ready to execute
Last activity: 2026-03-27

## Performance Metrics

**Velocity (v3.0):**

- Total plans completed: 16
- v3.0 phases: 12-18 (all complete)

**By Phase (v3.0):**

| Phase | Plans | Notes |
|-------|-------|-------|
| 12. Code Quality | 2/2 | Complete |
| 13. Onboarding | 4/4 | Complete |
| 14. Menu Bar Popover | 2/2 | Complete |
| 15. Voice Fixes | 2/2 | Complete |
| 16. Visual Polish | 3/3 | Complete |
| 17. Distribution | 2/2 | Complete |
| 18. GitHub README | 1/1 | Complete |

*Updated after each plan completion*
| Phase 19-cleanup P01 | 5 | 2 tasks | 2 files |
| Phase 19-cleanup P02 | 5 | 2 tasks | 4 files |
| Phase 20-fix-auto-speak-tts P01 | 1 | 1 tasks | 2 files |
| Phase 20 P02 | 4 | 2 tasks | 3 files |
| Phase 21-github-branding P01 | 110 | 2 tasks | 4 files |
| Phase 21-github-branding P02 | 2 | 2 tasks | 2 files |
| Phase 24-offline-stt P01 | 204 | 2 tasks | 2 files |
| Phase 24-offline-stt P02 | 7 | 2 tasks | 5 files |
| Phase 25-offline-tts P01 | 4 | 2 tasks | 3 files |
| Phase 25-offline-tts P02 | 12 | 2 tasks | 3 files |
| Phase 26-cleanup P01 | 3 | 2 tasks | 8 files |
| Phase 27-stt-reliability P01 | 4 | 2 tasks | 1 files |

## Accumulated Context

### Decisions

- [Phase 16]: Deep rename to CC-Beeper complete — IPC, Keychain, bundle ID all migrated
- [Phase 17]: Ad-hoc signing default; notarization opt-in (Apple Developer Program required)
- [Phase 18]: README uses vecartier/Claumagotchi repo URL for DMG link — repo rename deferred
- [Phase 18]: Cover image at docs/cover.png — committed, renders on GitHub
- [v3.1 planning]: Phase 22 (Final Branding) blocked until user provides Figma app icon export
- [Phase 19-cleanup]: feedback_claumagotchi_applications.md renamed to feedback_cc_beeper_applications.md with updated CC-Beeper build path
- [Phase 19-cleanup]: CLN-02: Zero Claumagotchi matches in all production code; migration code removed after clean break
- [Phase 20-fix-auto-speak-tts]: D-01: Merged summary extraction into cc-beeper-hook.py Stop handler — hooks/summary-hook.py deleted, HookInstaller unchanged
- [Phase 20]: Provider passed as parameter through speakSummary() to speak() rather than injecting on TTSService — cleaner, no extra mutable state on service
- [Phase 20]: Groq voice hardcoded to Arista-PlayAI — voice selection deferred to POST-05 per D-05
- [Phase 21-github-branding]: Punched screen and buttons via NSGraphicsContext .copy + NSColor.clear — consistent with EggIcon technique
- [Phase 21-github-branding]: BeeperIcon uses isTemplate=true on .normal state for automatic light/dark menu bar adaptation
- [Phase 21-github-branding]: README rewritten with product-landing-page tone (Raycast/Arc style): punchy tagline, feature table, zero Claumagotchi mentions
- [Phase 21-github-branding]: GitHub repo metadata updated via gh CLI: description + 8 topics (claude-code, macos, desktop-widget, swift, swiftui, voice, tts, developer-tools)
- [v4.0 planning]: FluidAudio is one SPM package providing both Parakeet TDT (STT) and Kokoro-82M (TTS) — added once in Phase 23, consumed in both Phase 24 and Phase 25
- [v4.0 planning]: Phase 26 (Cleanup) deliberately ordered AFTER Phase 24 and Phase 25 — do not remove Groq/OpenAI paths until local replacements are confirmed working end-to-end
- [v4.0 planning]: LIC-01 and STT-01 combined into Phase 23 — both are fast, independent of each other, and foundational for the rest of the milestone
- [Phase 24-offline-stt]: configureCallbacks marked async — setPartialCallback/setEouCallback are actor-isolated and require await
- [Phase 24-offline-stt]: D-02 live terminal injection implemented via delta tracking: lastInjectedText tracks injected prefix, only new characters sent to terminal
- [Phase 24-offline-stt]: Groq path fully removed from VoiceService — GroqTranscriptionService.swift stays until Phase 26 per prior decision
- [Phase 24-offline-stt]: downloadParakeetModel() uses ParakeetService.shared singleton so VoiceService shares the initialized manager without re-initialization
- [Phase 24-offline-stt]: STT engine indicator in Settings is read-only — Parakeet always preferred when downloaded, no user selector per D-05
- [Phase 25-offline-tts]: KokoroService actor wraps KokoroTtsManager singleton — lazy init on first speakWithKokoro() call; default provider migrated from 'apple' to 'kokoro', legacy groq/openai migrated automatically
- [Phase 25-offline-tts]: downloadModels() continues to Kokoro even if Parakeet fails — partial success better than full abort
- [Phase 25-offline-tts]: Voice picker conditionally rendered only when ttsProvider == 'kokoro' to avoid UI clutter for Apple TTS users
- [Phase 26-cleanup]: CLN2-03: TTSPlaybackDelegate is the permanent name for AVAudioPlayerDelegate wrapper; migration block removed since default: branch handles legacy values safely
- [Phase 26-cleanup]: CLN2-01: Settings Voice tab fully removed — all voice controls live in SettingsAudioSection
- [Phase 26-cleanup]: CLN2-02: KeychainService deleted — offline-first app has zero API keys
- [v5.0 planning]: Phase 27 (STT) and Phase 28 (TTS + Rename) touch independent subsystems and can execute in parallel; both depend on Phase 26
- [v5.0 planning]: Phase 29 (Distribution) is fully independent of voice work — can start any time after Phase 26
- [v5.0 planning]: REN-01/REN-02 co-located with TTS fix in Phase 28 — "Auto-speak/VoiceOver" label lives in the same settings area as TTS controls
- [Phase 27-stt-reliability]: isRecording set synchronously before async Task in startRecording() — prevents rapid double-press race at source
- [Phase 27-stt-reliability]: NSRunningApplication.activate() replaces open -a Process in focusTerminal() — synchronous, no sleep needed
- [Phase 27-stt-reliability]: clearTerminalInput() uses Ctrl+U (kVK_ANSI_U + maskControl) — readline kill-line, works in bash/zsh/fish
- [Phase 27-stt-reliability]: finish() awaited before audioEngine = AVAudioEngine() in manual Parakeet stop — engine replaced only after finalization

### Pending Todos

- ~~Accept/deny buttons intermittently non-responsive~~ — FIXED. Two race conditions in ClaudeMonitor: (1) processEvent cleared pendingPermission on any pre_tool/post_tool event while awaiting user action; (2) updateAggregateState overrode .needsYou with .thinking. Fix checks pending.json existence before clearing, and preserves .needsYou while awaitingUserAction is true.

### Blockers/Concerns

- **Phase 22 gate**: BRD-02 (app icon) requires user to provide Figma export before Phase 22 can execute — Phase 22 can be skipped and picked up later; v5.0 phases do not depend on it
- **Phase 27/28 root causes unknown**: FIX2-01 through FIX2-04 are reliability regressions from the v4.0 offline model integration — root causes not yet diagnosed. Plan-phase will need investigation steps before fixes.

## Session Continuity

Last session: 2026-03-27T15:54:12.352Z
Stopped at: Completed 27-stt-reliability-01-PLAN.md
Resume file: None
