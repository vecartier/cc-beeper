# Requirements: Claumagotchi

**Defined:** 2026-03-20
**Core Value:** Users can see what Claude is doing and respond to permission requests without leaving their workflow

## Current Milestone: v2.0 — Voice & Intelligence

**Goal:** Transform Claumagotchi from a status monitor into an interactive companion — users can speak to Claude, see what it did, and manage everything from a proper settings experience.

## v2.0 Requirements

### Voice Input

- [ ] **VOICE-01**: User can hold a hotkey to record voice, which is transcribed on-device and typed into the focused terminal as simulated keystrokes
- [ ] **VOICE-02**: User can press a mic button on the Tamagotchi to start/stop voice recording (same behavior as hotkey)
- [ ] **VOICE-03**: Voice transcription uses on-device SFSpeechRecognizer (no API cost, no data leaves the Mac)
- [ ] **VOICE-04**: If no terminal is focused when voice input starts, the last-used terminal is activated first

### Activity Feed

- [x] **FEED-01**: User can see a per-session activity log of what Claude did (files edited, commands run, tools used)
- [x] **FEED-02**: Activity feed updates in real-time as events arrive from the hook
- [x] **FEED-03**: Activity data is derived from existing hook events (no new IPC protocol changes needed)

### AI Summary (BYOK)

- [x] **SUM-01**: User can enter their Anthropic or OpenAI API key in settings, stored securely in macOS Keychain
- [x] **SUM-02**: When an API key is configured, session activity is summarized into a readable recap on session end
- [ ] **SUM-03**: Without an API key, user sees the raw activity feed only (graceful degradation)
- [x] **SUM-04**: API calls go directly from the user's Mac to the provider — no intermediate servers

### Settings Window

- [x] **SET-01**: A proper native settings window replaces most menu bar toggles
- [x] **SET-02**: Settings include: API key entry, sound toggle, notification toggle, theme picker, hotkey config
- [x] **SET-03**: API key section shows clear privacy messaging ("Stored in Keychain. All data stays on your Mac.")
- [x] **SET-04**: Settings window accessible from menu bar ("Settings..." menu item)

### Layout Update

- [ ] **LAYOUT-01**: Tamagotchi button layout is updated to accommodate the mic button
- [ ] **LAYOUT-02**: Mic button shows recording state (visual feedback while voice is active)

## v1.1 Requirements (Completed)

### Bug Fixes
- [x] **BUG-01**: YOLO mode distinct menu bar icon
- [x] **BUG-02**: Stable window lookup via identifier
- [x] **BUG-03**: Default-deny on malformed response

### Security
- [x] **SEC-01–03**: Default-deny, event validation, response freshness

### Reliability
- [x] **REL-01–03**: File watcher recovery, timer pause, DispatchWorkItem

### Performance
- [x] **PERF-01–03**: Cached noise, throttled I/O, unified hex parser

### UX
- [x] **UX-01–04**: Session count, idle animation, full-path permissions, global hotkeys

### Notifications
- [x] **NOTIF-01–04**: Permission/done/error notifications with toggle

## Future Requirements

### Testing (v3)
- **TEST-01**: Unit tests for ClaudeState transitions
- **TEST-02**: Integration tests for IPC round-trip
- **TEST-03**: Python hook tests

### Multi-Session UI (v3)
- **MULTI-01**: Each session shown individually with state
- **MULTI-02**: Click-to-navigate to specific terminal

### Multi-Editor (v3+)
- **EDITOR-01**: VS Code extension for Copilot monitoring
- **EDITOR-02**: Unified cross-editor view

## Out of Scope

| Feature | Reason |
|---------|--------|
| VS Code extension | Separate product — defer to v3 |
| Multi-session navigation | Needs hook protocol changes — defer to v3 |
| Cloud sync / accounts | Local-only, no servers |
| Server-side processing | Everything on-device or direct-to-provider |
| iOS/iPad companion | macOS only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| VOICE-01 | Phase 8 | Pending |
| VOICE-02 | Phase 8 | Pending |
| VOICE-03 | Phase 8 | Pending |
| VOICE-04 | Phase 8 | Pending |
| FEED-01 | Phase 6 | Complete |
| FEED-02 | Phase 6 | Complete |
| FEED-03 | Phase 6 | Complete |
| SUM-01 | Phase 7 | Complete |
| SUM-02 | Phase 7 | Complete |
| SUM-03 | Phase 7 | Pending |
| SUM-04 | Phase 7 | Complete |
| SET-01 | Phase 5 | Complete |
| SET-02 | Phase 5 | Complete |
| SET-03 | Phase 5 | Complete |
| SET-04 | Phase 5 | Complete |
| LAYOUT-01 | Phase 8 | Pending |
| LAYOUT-02 | Phase 8 | Pending |

**Coverage:**
- v2.0 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0

---
*Requirements defined: 2026-03-20*
*Last updated: 2026-03-20 — v2.0 roadmap created, all 17 requirements mapped to phases 5-8*
