# Roadmap: Claumagotchi

## Milestones

- ✅ **v1.1 Polish + Hardening** - Phases 1-4 (shipped 2026-03-20)
- ❌ **v2.0 Voice & Intelligence** - Phases 5-8 (reverted 2026-03-21)
- 🚧 **v2.0 Voice Loop** - Phases 9-11 (in progress)

## Overview

v1.1 hardened the foundation. The first v2.0 attempt was reverted due to reliability issues. v2.0 Voice Loop keeps the same egg shell but adds a 4th button (Speak), smarter screen content per state, voice input with invisible terminal injection, and auto-speak summaries via Apple Intelligence. Built on lessons from the VoiceLoop prototype.

## Phases

<details>
<summary>✅ v1.1 Polish + Hardening (Phases 1-4) - SHIPPED 2026-03-20</summary>

### Phase 1: Hardening
**Plans:** 2/2 complete

### Phase 2: Reliability + Performance
**Plans:** 2/2 complete

### Phase 3: UX Enhancements
**Plans:** 2/2 complete

### Phase 4: Notifications
**Plans:** 2/2 complete

</details>

### v2.0 Voice Loop (In Progress)

**Milestone Goal:** Add voice I/O and smarter screen content to the existing egg shell — users can speak to Claude, hear what it did, and manage everything from 4 buttons + menu bar. Never touch the terminal.

## Phase Details

### Phase 9: UI + Controls
**Goal**: The egg has 4 buttons (Deny/Accept/Speak/Terminal), smarter screen content per state, and all control toggles in the menu bar
**Depends on**: v1.1 (phases 1-4)
**Requirements**: UI-01, UI-02, UI-03, CTRL-01, CTRL-02, CTRL-03, CTRL-04, CTRL-05, INFRA-02, INFRA-03
**Plans:** 3 plans
Plans:
- [x] 09-01-PLAN.md -- Extract components + extend ClaudeMonitor with new properties and hotkeys
- [ ] 09-02-PLAN.md -- 4-button layout, state-specific screen content, skeuomorphic enhancements
- [ ] 09-03-PLAN.md -- Menu bar reorganization + power toggle
**Success Criteria** (what must be TRUE):
  1. Four buttons visible below the screen: Deny (left), Accept (left-center), Speak (right-center), Go to terminal (right)
  2. Screen shows state-specific content — THINKING: tool name + elapsed time; DONE: 1-line summary; NEEDS YOU: tool + file path + risk label (FILE WRITE / SHELL CMD); IDLE: character animation
  3. Speak button shows recording state (color change, pulse) — but recording logic is Phase 10
  4. Menu bar has toggles for: YOLO mode, power on/off, show/hide, sound effects, auto-speak
  5. Power off makes the widget visually dormant (dimmed) — no monitoring, no sounds, no permission handling
  6. Hide removes the widget from screen but monitoring continues; show restores it
  7. Every button has a hotkey (Accept, Deny, Speak, Terminal)
  8. Accept/Deny buttons work with existing permission flow (preserve v1.1 behavior)

### Phase 10: Voice Input + Injection
**Goal**: Users can speak to Claude from any app — voice is recorded, transcribed on-device, and injected into the terminal without the user seeing the switch
**Depends on**: Phase 9
**Requirements**: VOICE-01, VOICE-02, INFRA-04
**Success Criteria** (what must be TRUE):
  1. Pressing Speak button (or hotkey) starts recording; pressing again stops and submits
  2. Transcribed text is injected into the terminal via CGEvent HID and Enter is pressed
  3. After injection, the previous app is refocused within 500ms — user never sees the terminal
  4. Voice input works while the user is in any app (Figma, Chrome, etc.)
  5. Works across all projects and Claude Code sessions on the same machine
  6. Audio engine handles headphone changes and recovers from errors without crashing

### Phase 11: Auto-Speak + Summary Hook
**Goal**: When Claude finishes and auto-speak is on, the response is summarized and spoken aloud — completing the hands-free loop
**Depends on**: Phase 10
**Requirements**: VOICE-03, VOICE-04, INFRA-01
**Success Criteria** (what must be TRUE):
  1. Summary hook (Python) fires on Claude stop, extracts last assistant text from session JSONL, writes to `~/.claude/claumagotchi/last_summary.txt`
  2. App watches the summary file and auto-speaks when it changes (if auto-speak enabled)
  3. Summary is processed via Apple Intelligence to extract the key conclusion in 1-2 sentences
  4. When Apple Intelligence is unavailable, the last paragraph is spoken as fallback
  5. Pressing Speak while TTS is playing immediately cuts TTS and starts recording
  6. The spoken summary is also displayed on the screen as the DONE state content
  7. Auto-speak is off by default, toggled from menu bar
  8. Recording has absolute priority — incoming summaries never interrupt an active recording

## Progress

**Execution Order:** 9 -> 10 -> 11

| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 9. UI + Controls | v2.0 | 1/3 | In Progress |
| 10. Voice Input + Injection | v2.0 | 0/? | Pending |
| 11. Auto-Speak + Summary Hook | v2.0 | 0/? | Pending |
