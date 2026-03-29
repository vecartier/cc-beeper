# Requirements: CC-Beeper v7.0

**Defined:** 2026-03-29
**Core Value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow

## v7.0 Requirements

### HTTP Hooks

- [x] **HTTP-01**: CC-Beeper runs a local HTTP server (NWListener, localhost only) that receives Claude Code hook events via POST /hook
- [ ] **HTTP-02**: Hook events are routed by `hook_type` field to the LCD state machine (PreToolUse → WORKING, Stop → DONE, StopFailure → ERROR, Notification → classify per INPUT rules)
- [x] **HTTP-03**: The active server port is written to `~/.claude/cc-beeper/port` on startup and deleted on quit
- [ ] **HTTP-04**: On Stop events, CC-Beeper extracts the last assistant message from the transcript (via transcript_path) for TTS summary, replacing the old Python summary extraction
- [ ] **HTTP-05**: The old Python hook script (cc-beeper-hook.py), JSONL file watcher, and file-based IPC code are removed from the codebase
- [ ] **HTTP-06**: Hook commands in settings.json use `curl -d @-` to pipe stdin JSON to CC-Beeper's HTTP endpoint, with `-o /dev/null` and `|| true` for silent failure

### LCD States

- [ ] **LCD-01**: The beeper displays 7 distinct states: IDLE, THINKING, WORKING, APPROVE?, NEEDS INPUT, ERROR, DONE — each with state-specific title text
- [ ] **LCD-02**: WORKING state shows tool context as scrolling text (e.g., "WORKING: npm test", "WORKING: Reading auth.ts"), truncated to 30 chars
- [ ] **LCD-03**: APPROVE? state shows permission context (e.g., "APPROVE? rm -rf dist"), truncated to 30 chars
- [ ] **LCD-04**: ERROR state shows error context from StopFailure payload (e.g., "ERROR: Rate limited")
- [ ] **LCD-05**: DONE state auto-transitions to IDLE after 3 seconds
- [ ] **LCD-06**: State priority is enforced: ERROR > APPROVE? > NEEDS INPUT > WORKING > THINKING > DONE > IDLE — lower-priority events don't overwrite higher-priority states
- [ ] **LCD-07**: Auth success/error notifications display as transient flashes (2-3s) over the current state without changing the state machine

### Input vs Permission

- [ ] **INP-01**: Notification payloads are classified as permission (tool approval) or input (question/discussion/multiple choice) based on the notification type field
- [ ] **INP-02**: In Guarded YOLO and Full YOLO modes, permission notifications are suppressed (LCD stays on current state), but input notifications always show NEEDS INPUT
- [ ] **INP-03**: Unknown notification types default to NEEDS INPUT (visible) — false positives over false negatives

### Permission Spectrum

- [ ] **PERM-01**: The menu bar popover contains a segmented control with 4 permission modes: Cautious (default), Guided (plan), Guarded YOLO (bypass + deny preserved), Full YOLO (bypass + deny cleared)
- [ ] **PERM-02**: Selecting a mode reads settings.json, modifies only the permission_mode field (and deny rules for Full YOLO), and writes back atomically without reformatting
- [ ] **PERM-03**: On mode change, the LCD shows a toast overlay "RESTART SESSION TO APPLY" for 5 seconds
- [ ] **PERM-04**: Before writing a mode change, a brief preview is shown describing what will change
- [ ] **PERM-05**: Switching from Full YOLO to another mode restores previously cached deny rules from `~/.claude/cc-beeper/cached-deny-rules.json`
- [ ] **PERM-06**: If settings.json is malformed, the segmented control is disabled with a warning message

### YOLO Sunglasses

- [ ] **YOLO-01**: When permission mode is Guarded YOLO or Full YOLO, the beeper character renders with pixel sunglasses, persisting across all LCD states
- [ ] **YOLO-02**: Sunglasses appear/disappear with a slide-down/slide-up animation on mode change

### LCD Animations

- [ ] **ANIM-01**: Each LCD state has a distinct animation: IDLE (static), THINKING (slow pulse), WORKING (marquee scroll), APPROVE? (fast blink), NEEDS INPUT (slow blink), ERROR (flash then hold), DONE (brief flash then fade) — LCD color stays consistent with theme, no per-state color changes
- [ ] **ANIM-02**: APPROVE? and NEEDS INPUT are distinguishable at a glance by different blink speeds and text

### Hook Improvements

- [ ] **HOOK-01**: All CC-Beeper hook entries in settings.json have `async: true` and `timeout: 5000`
- [ ] **HOOK-02**: Only the PreToolUse hook has `statusMessage: "CC-Beeper monitoring…"`
- [ ] **HOOK-03**: All hook commands produce zero stdout output under all conditions (CC-Beeper running, not running, port file missing)
- [ ] **HOOK-04**: CC-Beeper hooks are identified in settings.json by matching `cc-beeper` in the command string, enabling safe update/removal without touching user hooks


### Onboarding

- [ ] **ONBD-01**: Onboarding detects and migrates old JSONL-based CC-Beeper hooks to HTTP hooks, with user confirmation and "What this changes" expandable detail
- [ ] **ONBD-02**: Onboarding starts the HTTP server and confirms it's listening before completing
- [ ] **ONBD-03**: Existing voice, language, and model download onboarding steps are preserved
- [ ] **ONBD-04**: If settings.json is malformed, onboarding shows a clear error and does not attempt to write to it

### README

- [ ] **GH-01**: README opens with a hero GIF showing the beeper reacting to a live Claude Code session (IDLE → THINKING → WORKING → APPROVE? → DONE cycle)
- [ ] **GH-02**: README includes feature highlights with inline screenshots: LCD status, permission mode toggle, YOLO sunglasses, menu bar presence
- [ ] **GH-03**: README includes install instructions (Homebrew + DMG fallback), setup overview, how-it-works technical paragraph, and uninstall guide


## v8+ Requirements

Deferred to future release.

- **FUTURE-01**: Switchboard window (hooks/guards/automations GUI)
- **FUTURE-02**: Guidelines editor for ~/.claude/CLAUDE.md
- **FUTURE-03**: Per-project hooks/settings management
- **FUTURE-04**: Proactive behavior-based nudges

## Out of Scope

| Feature | Reason |
|---------|--------|
| Switchboard / hooks management GUI | CC-Beeper is a monitoring layer, not a config manager |
| Guard/automation presets | No bundled hook scripts in v7.0 |
| Guidelines editor | CLAUDE.md editing belongs in terminal/editor |
| Per-project settings | Ship with global settings first |
| iOS/iPad companion | macOS only |
| App Store distribution | GitHub + DMG for now |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HTTP-01 | Phase 35 | Complete |
| HTTP-02 | Phase 35 | Pending |
| HTTP-03 | Phase 35 | Complete |
| HTTP-04 | Phase 35 | Pending |
| HTTP-05 | Phase 35 | Pending |
| HTTP-06 | Phase 35 | Pending |
| HOOK-01 | Phase 35 | Pending |
| HOOK-02 | Phase 35 | Pending |
| HOOK-03 | Phase 35 | Pending |
| HOOK-04 | Phase 35 | Pending |
| LCD-01 | Phase 36 | Pending |
| LCD-02 | Phase 36 | Pending |
| LCD-03 | Phase 36 | Pending |
| LCD-04 | Phase 36 | Pending |
| LCD-05 | Phase 36 | Pending |
| LCD-06 | Phase 36 | Pending |
| LCD-07 | Phase 36 | Pending |
| INP-01 | Phase 36 | Pending |
| INP-02 | Phase 36 | Pending |
| INP-03 | Phase 36 | Pending |
| PERM-01 | Phase 37 | Pending |
| PERM-02 | Phase 37 | Pending |
| PERM-03 | Phase 37 | Pending |
| PERM-04 | Phase 37 | Pending |
| PERM-05 | Phase 37 | Pending |
| PERM-06 | Phase 37 | Pending |
| YOLO-01 | Phase 37 | Pending |
| YOLO-02 | Phase 37 | Pending |
| ANIM-01 | Phase 36 | Pending |
| ANIM-02 | Phase 36 | Pending |
| ONBD-01 | Phase 39 | Pending |
| ONBD-02 | Phase 39 | Pending |
| ONBD-03 | Phase 39 | Pending |
| ONBD-04 | Phase 39 | Pending |
| GH-01 | Phase 40 | Pending |
| GH-02 | Phase 40 | Pending |
| GH-03 | Phase 40 | Pending |

**Coverage:**
- v7.0 requirements: 36 total
- Mapped to phases: 36
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-29*
*Last updated: 2026-03-29 — Traceability mapped after roadmap creation (phases 34-40)*
