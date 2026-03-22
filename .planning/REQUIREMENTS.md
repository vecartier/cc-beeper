# Requirements: Claumagotchi

**Defined:** 2026-03-22
**Core Value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow

## v2.0 Requirements

Requirements for the Voice Loop milestone. Each maps to roadmap phases.

### UI

- [x] **UI-01**: Screen shows state-specific content: THINKING (tool + elapsed), DONE (1-line summary), NEEDS YOU (tool + file + risk label), IDLE (character)
- [x] **UI-02**: Four buttons below the screen: Deny (left), Accept (left-center), Speak (right-center), Go to terminal (right) — same egg shell, same size
- [x] **UI-03**: Mic button shows clear recording state (color change, pulse) when voice input is active

### Voice

- [x] **VOICE-01**: User can toggle voice recording (tap to start, tap to stop) via Speak button or hotkey
- [x] **VOICE-02**: Transcribed voice text is injected into the terminal and submitted (Enter), then the previous app is refocused — user never sees the terminal switch
- [x] **VOICE-03**: When Claude finishes and auto-speak is enabled, the last response is summarized via Apple Intelligence and spoken aloud using Ava Premium TTS
- [x] **VOICE-04**: User can stop TTS mid-sentence by pressing Speak (which also starts recording) or via hotkey

### Controls

- [x] **CTRL-01**: User can accept a pending permission via Accept button or hotkey
- [x] **CTRL-02**: User can deny a pending permission via Deny button or hotkey
- [x] **CTRL-03**: User can toggle YOLO mode (auto-accept all permissions) from the menu bar
- [x] **CTRL-04**: User can power off the companion (visible but dormant — no monitoring, no sounds, no permissions) and power back on, from the menu bar
- [x] **CTRL-05**: User can hide the widget to the menu bar and restore it from the menu — hidden mode still monitors and speaks if enabled

### Infrastructure

- [x] **INFRA-01**: A Python hook fires on Claude Code stop events, extracts the last assistant text from the session JSONL, and writes it to `~/.claude/claumagotchi/last_summary.txt`
- [x] **INFRA-02**: Every button action has a keyboard shortcut (hotkey)
- [x] **INFRA-03**: Menu bar provides toggles for: show/hide widget, sound effects, auto-speak, YOLO mode, and power on/off
- [x] **INFRA-04**: All features work across all projects and Claude Code sessions on the same machine

## Future Requirements

### Quality of Life

- **QOL-01**: Custom TTS voice selection (beyond Ava Premium)
- **QOL-02**: Per-project settings (different YOLO/voice preferences per project)
- **QOL-03**: Conversation history panel (past summaries)
- **QOL-04**: Hotkey remapping from menu bar

### Distribution

- **DIST-01**: Automated test suite
- **DIST-02**: App Store distribution

## Out of Scope

| Feature | Reason |
|---------|--------|
| Game Boy Color form factor | Keeping the egg shell — familiar, compact |
| Larger screen | Current size is enough with 2-line state content |
| Settings window | Controls live on widget + menu bar |
| Activity feed UI | Summaries replace raw activity log |
| Hotkey remapping | Ship with fixed hotkeys, remap later |
| BYOK API keys | Apple Intelligence is free and on-device |
| External TTS | Ava Premium is free and adequate |
| iOS/iPad companion | macOS only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| UI-01 | Phase 9 | Complete |
| UI-02 | Phase 9 | Complete |
| UI-03 | Phase 9 | Complete |
| VOICE-01 | Phase 10 | Complete |
| VOICE-02 | Phase 10 | Complete |
| VOICE-03 | Phase 11 | Complete |
| VOICE-04 | Phase 11 | Complete |
| CTRL-01 | Phase 9 | Complete (09-01) |
| CTRL-02 | Phase 9 | Complete (09-01) |
| CTRL-03 | Phase 9 | Complete |
| CTRL-04 | Phase 9 | Complete (09-01) |
| CTRL-05 | Phase 9 | Complete (09-01) |
| INFRA-01 | Phase 11 | Complete |
| INFRA-02 | Phase 9 | Complete (09-01) |
| INFRA-03 | Phase 9 | Complete |
| INFRA-04 | Phase 10 | Complete |

**Coverage:**
- v2.0 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-22*
