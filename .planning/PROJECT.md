# Claumagotchi

## What This Is

A Game Boy Color–styled macOS desktop companion for Claude Code. It monitors active sessions, handles permission requests, provides voice input/output, and lets users interact with Claude without touching the terminal — all from a skeuomorphic floating widget and menu bar icon.

## Core Value

Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow.

## Current Milestone: v2.0 Game Boy

**Goal:** Transform the Tamagotchi egg into a Game Boy Color form factor with voice input, auto-speak summaries, and a full button panel — so users never need to look at the terminal.

**Target features:**
- Game Boy Color UI shell (skeuomorphic, larger screen, A/B/Select/Start buttons)
- Voice-to-terminal input (toggle record, inject without leaving current app)
- Auto-speak summaries when Claude finishes (hook-based, Apple Intelligence)
- YOLO toggle, power on/off, hide, mute — all with hotkeys
- Works across all projects and sessions

## Requirements

### Validated

<!-- Shipped and confirmed valuable — v1.1 -->

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
- ✓ YOLO mode distinct purple icon in menu bar — Phase 1
- ✓ Stable window lookup via identifier (not title) — Phase 1
- ✓ Default-deny on malformed/missing permission response — Phase 1
- ✓ Event JSON schema validation before processing — Phase 1
- ✓ Response freshness check (rejects stale/pre-written responses) — Phase 1
- ✓ File watcher auto-recovers from events.jsonl deletion/rename — Phase 2
- ✓ Sprite animation pauses when window is hidden — Phase 2
- ✓ DispatchWorkItem idle timer (no manual Timer objects) — Phase 2
- ✓ Noise texture cached as static NSImage (renders once) — Phase 2
- ✓ Throttled sessions.json reads (every 30s, not per-event) — Phase 2
- ✓ Unified hex color parsing (single implementation) — Phase 2
- ✓ Session count badge on LCD screen — Phase 3
- ✓ Idle/sleeping animation after 60s inactivity — Phase 3
- ✓ Full file path in permission prompts (not just basename) — Phase 3
- ✓ Global hotkeys Option+A/D with accessibility gate — Phase 3
- ✓ macOS Notification Center integration with toggle — Phase 4

### Active

<!-- Current scope — v2.0 Game Boy -->

- [ ] Game Boy Color UI redesign (shell, screen, button panel, speaker grille, power LED)
- [ ] Voice input via toggle record (SFSpeechRecognizer → CGEvent HID → auto-Enter)
- [ ] Invisible terminal injection (focus terminal → inject → refocus previous app)
- [ ] Auto-speak summaries (hook writes JSONL last response → Apple Intelligence → Ava Premium TTS)
- [ ] Summary hook (Python, fires on Claude stop event, writes to last_summary.txt)
- [ ] YOLO mode toggle (slider-style on the shell)
- [ ] Power on/off (disables all monitoring, silences everything)
- [ ] Hide/show widget (minimize to menu bar, restore from menu)
- [ ] Mute current TTS (button to stop speaking mid-sentence)
- [ ] Hotkeys for all actions
- [ ] Larger screen with permission details (tool, file path, what it's doing)
- [ ] Menu bar: show/hide, sound effects toggle, auto-speak toggle, power toggle
- [ ] Cross-session support (works across all projects)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Actionable notification buttons — widget is always floating, buttons in notifications are redundant
- Tests — valuable but separate milestone to avoid scope bloat
- Swift Concurrency migration (async/await) — refactor milestone, not a polish pass
- iOS/iPad companion — macOS only
- Settings window — v2.0 controls go in menu bar and on the widget itself
- Activity feed UI — summaries replace the need for a raw activity log
- BYOK API keys — Apple Intelligence is free and on-device, no key management needed
- External TTS (OpenAI, ElevenLabs) — using Ava Premium, no cost

## Context

- Swift 6.2+ / macOS 26+ / SwiftUI + AppKit
- Zero external dependencies — all system frameworks (incl. FoundationModels, Speech, AVFoundation)
- Python hook script bridges Claude Code events to the app via JSONL IPC
- Summary hook reads conversation JSONL from `~/.claude/projects/`
- Codebase is small (~1200 LOC Swift, ~300 LOC Python) — changes are low-risk
- Prototype at `/Users/vcartier/Desktop/VoiceLoop/` validates voice + TTS + hook approach
- Codebase map available at `.planning/codebase/`
- v2.0 was previously attempted and reverted — voice (SFSpeechRecognizer) and settings window had issues. Lessons learned:
  - SFSpeechRecognizer works but audio engine gets corrupted by rapid start/stop cycles (fix: `sudo killall coreaudiod`)
  - `format: nil` in installTap for headphone compatibility
  - NSPanel with `nonactivatingPanel` breaks SwiftUI button taps — use regular floating window
  - CGEvent injection needs `nil` event source + `.cghidEventTap` (FluidVoice pattern)
  - Accessibility permission invalidated by ad-hoc re-signing — use Apple Development identity
  - Apple Intelligence summarization works but needs careful prompting

## Constraints

- **Platform**: macOS 26+ — uses FoundationModels (Apple Intelligence), Speech framework
- **Dependencies**: No third-party frameworks — keep it self-contained
- **Distribution**: Must remain buildable via `make build` with just Xcode CLI tools
- **IPC protocol**: Hook ↔ app communication via `~/.claude/claumagotchi/` files — backward compatible
- **Signing**: Must use Apple Development identity (not ad-hoc) so Accessibility permission persists across rebuilds
- **UI**: Skeuomorphic Game Boy Color aesthetic — not flat/modern. Plastic feel, bevels, physical-looking buttons.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| File-based IPC over XPC/sockets | Simpler, works cross-process, debuggable | ✓ Good |
| No external dependencies | Minimal attack surface, easy distribution | ✓ Good |
| Global hotkeys for all actions | Hands-free interaction from any app | ✓ Good |
| Default-deny on malformed response | Security: fail closed, not open | ✓ Good |
| Game Boy Color form factor over Tamagotchi egg | More buttons, larger screen, familiar nostalgic form | — Pending |
| Apple Intelligence for summaries (not external API) | Free, on-device, no API key needed | — Pending |
| Ava Premium TTS (not external API) | Free, decent quality, no cost | — Pending |
| Hook-based summary (not terminal scraping) | Clean data from JSONL, no parsing issues | ✓ Good (validated in prototype) |
| Regular floating window (not NSPanel) | NSPanel breaks SwiftUI button taps | ✓ Good (validated in prototype) |
| Focus-inject-refocus pattern for voice | User never sees terminal switch | — Pending |
| v2.0 reverted, fresh start from v1.1 | Previous v2.0 features were unreliable | ✓ Good |

---
*Last updated: 2026-03-21 after v2.0 Game Boy milestone initialization*
