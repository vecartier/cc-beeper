# Roadmap: Claumagotchi

## Milestones

- 🚧 **v1.1 Polish + Hardening** - Phases 1-4 (in progress)

## Overview

v1.1 hardens the existing foundation before adding new visible capabilities. Phase 1 fixes bugs and closes security gaps — many of which share the same code paths in the Python hook and Swift monitor. Phase 2 improves reliability and performance invisibly, making the app more stable before the bigger UI lifts. Phase 3 adds the visible UX features: session count, idle animation, richer permission info, and global hotkeys. Phase 4 integrates macOS Notification Center as a standalone subsystem that builds on the stabilized event pipeline.

## Phases

### 🚧 v1.1 Polish + Hardening

**Milestone Goal:** Fix known issues, harden security, improve stability and performance, then ship three user-visible improvements and Notification Center integration.

- [x] **Phase 1: Hardening** - Fix bugs and close security gaps in the IPC and event pipeline
- [x] **Phase 2: Reliability + Performance** - Stabilize the file watcher, timers, and rendering without changing behavior (completed 2026-03-20)
- [x] **Phase 3: UX Enhancements** - Add session count, idle animation, richer permission context, and global hotkeys (completed 2026-03-20)
- [ ] **Phase 4: Notifications** - Integrate macOS Notification Center with permission, finish, and error alerts

## Phase Details

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
**Plans:** 2 plans
Plans:
- [x] 04-01-PLAN.md — NotificationManager + ClaudeMonitor wiring + build.sh code signing (NOTIF-01, NOTIF-02, NOTIF-03)
- [ ] 04-02-PLAN.md — Menu bar notifications toggle + end-to-end verification (NOTIF-04)

## Progress

**Execution Order:** 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Hardening | 2/2 | Complete   | 2026-03-19 |
| 2. Reliability + Performance | 2/2 | Complete   | 2026-03-20 |
| 3. UX Enhancements | 2/2 | Complete   | 2026-03-20 |
| 4. Notifications | 1/2 | In progress | - |
