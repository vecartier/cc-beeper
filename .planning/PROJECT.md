# Claumagotchi

## What This Is

A Tamagotchi-style macOS desktop companion for Claude Code. It monitors active sessions via file-based IPC, displays state as an animated pixel character, and handles permission requests — all from a floating widget and menu bar icon.

## Core Value

Users can see what Claude is doing and respond to permission requests without leaving their workflow.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- Session monitoring via JSONL file watcher (thinking/finished/needsYou states)
- Permission request handling (allow/deny via UI buttons and YOLO auto-accept mode)
- Animated pixel character reflecting session state (thinking, working, alert, happy, YOLO)
- Menu bar extra with status, actions, theme picker
- 9 color themes with dark mode support
- Sound alerts (ping for permissions, pop for done)
- Single-instance enforcement via PID file
- Auto-launch on Claude Code session start
- Auto-update via LaunchAgent
- DMG distribution

### Active

<!-- Current scope. Building toward these. -->

- [ ] Fix known bugs (YOLO icon, window lookup, default-allow on malformed response)
- [ ] Harden security (default-deny, event validation, response file integrity)
- [ ] Improve reliability (file watcher recovery, timer management)
- [ ] Improve performance (cache noise texture, pause timers when hidden, reduce disk I/O, unify hex parsers)
- [ ] Show active session count on screen
- [ ] Idle/sleeping animation after inactivity
- [ ] Richer permission info (full file path or command, not just tool name)
- [ ] Global hotkeys (Option+A allow, Option+D deny) for permission response without mouse
- [ ] macOS Notification Center integration (with enable/disable toggle)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Actionable notification buttons — app is always floating, buttons in notifications are redundant
- Tests — valuable but separate milestone to avoid scope bloat
- Swift Concurrency migration (async/await) — refactor milestone, not a polish pass
- iOS/iPad companion — macOS only

## Context

- Swift 5.10+ / macOS 14+ / SwiftUI + AppKit
- Zero external dependencies — all system frameworks
- Python hook script bridges Claude Code events to the app via JSONL IPC
- Codebase is small (~1200 LOC Swift, ~300 LOC Python) — changes are low-risk
- Codebase map available at `.planning/codebase/`

## Constraints

- **Platform**: macOS 14+ only — uses AppKit, SwiftUI, kqueue file watching
- **Dependencies**: No third-party frameworks — keep it self-contained
- **Distribution**: Must remain buildable via `make build` with just Xcode CLI tools
- **IPC protocol**: Hook ↔ app communication via `~/.claude/claumagotchi/` files — changes must be backward compatible

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| File-based IPC over XPC/sockets | Simpler, works cross-process, debuggable | ✓ Good |
| No external dependencies | Minimal attack surface, easy distribution | ✓ Good |
| Global hotkey Option+A/D for permissions | Fastest response path without mouse | — Pending |
| Notifications for visibility, not actions | App is always floating — action buttons redundant | — Pending |
| Default-deny on malformed response | Security: fail closed, not open | — Pending |

---
*Last updated: 2026-03-19 after v1.1 milestone initialization*
