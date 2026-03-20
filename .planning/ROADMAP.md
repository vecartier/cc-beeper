# Roadmap: Claumagotchi

## Milestones

- ✅ **v1.1 Polish + Hardening** - Phases 1-4 (shipped 2026-03-20)
- 🚧 **v2.0 Voice & Intelligence** - Phases 5-8 (in progress)

## Overview

v1.1 hardened the foundation across four phases: security fixes, reliability/performance, UX enhancements, and Notification Center integration. v2.0 transforms Claumagotchi from a status monitor into an interactive companion. Phase 5 gives users a proper Settings window — and the API key entry it creates is required before AI summaries can work. Phase 6 builds the activity feed, establishing the data layer that summaries consume. Phase 7 adds AI-powered session summaries using the feed data and stored API key. Phase 8 adds voice input — the largest feature — paired with the button layout update that accommodates the mic button in the same UI pass.

## Phases

<details>
<summary>✅ v1.1 Polish + Hardening (Phases 1-4) - SHIPPED 2026-03-20</summary>

### Phase 1: Hardening
**Goal**: Known bugs are fixed and the IPC permission flow fails closed, not open
**Depends on**: Nothing (first phase)
**Requirements**: BUG-01, BUG-02, BUG-03, SEC-01, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. YOLO mode shows a distinct visual indicator in the menu bar (not orange like normal needsYou — a separate state)
  2. The main window opens and closes reliably, regardless of its title string
  3. A malformed, empty, or missing-key response.json results in a deny decision — Claude Code never auto-allows due to bad data
  4. Events with unexpected schema are rejected before processing, not silently passed through
  5. A response.json written before the permission request was issued is ignored (stale timestamp check)
**Plans:** 2/2 plans complete
Plans:
- [x] 01-01-PLAN.md — Swift-side fixes: YOLO icon, window identifier lookup, event schema validation
- [x] 01-02-PLAN.md — Python-side fixes: default-deny with whitelist, response freshness check

### Phase 2: Reliability + Performance
**Goal**: The app runs stably for hours without degrading — watcher survives file rotation, timers pause when hidden, rendering is efficient
**Depends on**: Phase 1
**Requirements**: REL-01, REL-02, REL-03, PERF-01, PERF-02, PERF-03
**Success Criteria** (what must be TRUE):
  1. Deleting and recreating events.jsonl does not break session monitoring — no app restart required
  2. The sprite animation does not consume CPU cycles when the companion window is hidden or minimized
  3. Switching themes or triggering state changes does not cause noticeable frame drops or redundant disk reads
  4. Hex color parsing behaves consistently across all themes (single implementation, no divergence)
**Plans:** 2/2 plans complete
Plans:
- [x] 02-01-PLAN.md — Monitor resilience: file watcher recovery, throttled session pruning, DispatchWorkItem idle timer
- [x] 02-02-PLAN.md — View layer performance: visibility-aware sprite timer, cached noise texture, unified hex parser

### Phase 3: UX Enhancements
**Goal**: The companion window shows richer context and users can respond to permissions without touching the mouse
**Depends on**: Phase 1
**Requirements**: UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. The LCD screen displays the number of active Claude sessions at a glance
  2. When no session has been active for a defined period, the character plays a sleeping or idle animation
  3. The permission prompt shows the actual file path or command being requested, not just a tool category label
  4. Pressing Option+A allows and Option+D denies a pending permission from any app, without clicking the companion window
**Plans:** 2/2 plans complete
Plans:
- [x] 03-01-PLAN.md — Session count display, idle/sleeping animation, full-path permission info
- [x] 03-02-PLAN.md — Global hotkeys (Option+A allow, Option+D deny) with accessibility gate

### Phase 4: Notifications
**Goal**: Users receive macOS Notification Center alerts for permission requests, session completion, and errors — with a toggle to disable them
**Depends on**: Phase 1
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04
**Success Criteria** (what must be TRUE):
  1. A Notification Center alert appears when a permission request arrives, even if the companion window is behind other apps
  2. A notification fires when a Claude session completes
  3. A notification fires on tool errors or permission timeouts
  4. The menu bar includes a toggle that enables or disables all notifications, persisting across app restarts
**Plans:** 2/2 plans complete
Plans:
- [x] 04-01-PLAN.md — NotificationManager + ClaudeMonitor wiring + build.sh code signing (NOTIF-01, NOTIF-02, NOTIF-03)
- [x] 04-02-PLAN.md — Menu bar notifications toggle + end-to-end verification (NOTIF-04)

</details>

### v2.0 Voice & Intelligence (In Progress)

**Milestone Goal:** Transform Claumagotchi from a status monitor into an interactive companion — users can speak to Claude, see what it did, and manage everything from a proper settings experience.

## Phase Details

### Phase 5: Settings Window
**Goal**: Users can manage all app preferences and enter API keys from a single native window — replacing scattered menu toggles
**Depends on**: Phase 4
**Requirements**: SET-01, SET-02, SET-03, SET-04
**Success Criteria** (what must be TRUE):
  1. User can open a Settings window from the menu bar "Settings..." item
  2. User can enter and save an Anthropic or OpenAI API key, with visible confirmation it is stored in Keychain
  3. Settings window shows clear privacy messaging ("Stored in Keychain. All data stays on your Mac.")
  4. Sound toggle, notification toggle, theme picker, and hotkey config are all accessible from the Settings window
**Plans:** 2/2 plans complete
Plans:
- [x] 05-01-PLAN.md — KeychainHelper, APIKeyValidator, Window scene registration + openSettingsWindow helper (SET-01, SET-04)
- [x] 05-02-PLAN.md — SettingsView with 4 tabs (General/Appearance/AI/Privacy), menu bar cleanup (SET-01, SET-02, SET-03, SET-04)

### Phase 6: Activity Feed
**Goal**: Users can see a live log of what Claude did in each session — files edited, commands run, tools used
**Depends on**: Phase 5
**Requirements**: FEED-01, FEED-02, FEED-03
**Success Criteria** (what must be TRUE):
  1. User can see a per-session list of Claude's actions (files edited, commands run, tools used) in the companion window
  2. Activity feed entries appear in real-time as new hook events arrive — no manual refresh needed
  3. Feed data is derived from existing hook events without any changes to the IPC protocol
**Plans:** 2/2 plans complete
Plans:
- [x] 06-01-PLAN.md — ActivityEntry data model, hook summary enrichment, real-time storage in ClaudeMonitor (FEED-01, FEED-02, FEED-03)
- [x] 06-02-PLAN.md — ActivityFeedView UI, expandable panel in ContentView, human verification (FEED-01, FEED-02)

### Phase 7: AI Summary
**Goal**: When a session ends and an API key is configured, Claude's activity is summarized into a readable recap — gracefully degrading to raw feed when no key is set
**Depends on**: Phase 6
**Requirements**: SUM-01, SUM-02, SUM-03, SUM-04
**Success Criteria** (what must be TRUE):
  1. When an API key is stored, a readable summary of the session's activity appears after the session ends
  2. Without an API key, the raw activity feed is shown and no summary is attempted
  3. API calls go directly from the Mac to Anthropic or OpenAI — no intermediate servers involved
  4. User can configure which provider's API key to use (Anthropic or OpenAI)
**Plans:** 2/2 plans complete
Plans:
- [ ] 07-01-PLAN.md — SummaryService with Anthropic/OpenAI API calls, ClaudeMonitor session_end trigger (SUM-01, SUM-02, SUM-04)
- [ ] 07-02-PLAN.md — ActivityFeedView summary display with graceful degradation (SUM-02, SUM-03)

### Phase 8: Voice Input + Layout
**Goal**: Users can speak to Claude by holding a hotkey or pressing the mic button — and the Tamagotchi UI shows recording state clearly
**Depends on**: Phase 5
**Requirements**: VOICE-01, VOICE-02, VOICE-03, VOICE-04, LAYOUT-01, LAYOUT-02
**Success Criteria** (what must be TRUE):
  1. User can hold a hotkey to record voice; the transcription is typed into the focused terminal as keystrokes
  2. User can press the mic button on the Tamagotchi to start and stop voice recording
  3. The mic button shows a clear visual recording state while voice capture is active
  4. If no terminal is focused when recording starts, the last-used terminal is automatically activated first
  5. All transcription happens on-device — no audio leaves the Mac
**Plans:** 1/2 plans executed
Plans:
- [ ] 08-01-PLAN.md — VoiceService (SFSpeechRecognizer + AVAudioEngine + CGEvent injection) + build.sh Info.plist permissions (VOICE-03, VOICE-04)
- [ ] 08-02-PLAN.md — ClaudeMonitor hotkey wiring + ContentView mic button layout (VOICE-01, VOICE-02, LAYOUT-01, LAYOUT-02)

## Progress

**Execution Order:** 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Hardening | v1.1 | 2/2 | Complete | 2026-03-19 |
| 2. Reliability + Performance | v1.1 | 2/2 | Complete | 2026-03-20 |
| 3. UX Enhancements | v1.1 | 2/2 | Complete | 2026-03-20 |
| 4. Notifications | v1.1 | 2/2 | Complete | 2026-03-20 |
| 5. Settings Window | v2.0 | 2/2 | Complete | 2026-03-20 |
| 6. Activity Feed | v2.0 | 2/2 | Complete | 2026-03-20 |
| 7. AI Summary | 2/2 | Complete   | 2026-03-20 | - |
| 8. Voice Input + Layout | 1/2 | In Progress|  | - |
