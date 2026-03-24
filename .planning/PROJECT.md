# CC-Beeper (Claumagotchi)

## What This Is

A retro pager-styled macOS desktop companion for Claude Code. It monitors active sessions, handles permission requests, provides voice input/output, and lets users interact with Claude without touching the terminal — all from a skeuomorphic floating "Code Beeper" widget and menu bar icon.

## Core Value

Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow.

## Current Milestone: v3.0 Public Launch

**Goal:** Make CC-Beeper ready for strangers — onboarding, clean code, distribution, GitHub presence. Drop-ready for HackerNews, Reddit, Twitter.

**Target features:**
- First-launch onboarding wizard (permissions, hooks, voice setup)
- Full code cleanup (no hardcoded paths, no dead assets, no warnings)
- DMG packaging + GitHub Releases distribution
- Landing-style GitHub README with GIF demos
- Visual polish (animations, transitions, dark mode variants)
- Bug fixes (voice approach, summary flow)

## Requirements

### Validated

<!-- Shipped and confirmed valuable -->

- ✓ Session monitoring via JSONL file watcher (thinking/finished/needsYou states) — v1.1
- ✓ Permission request handling (allow/deny via UI buttons and YOLO auto-accept mode) — v1.1
- ✓ Animated pixel character reflecting session state — v1.1
- ✓ Menu bar extra with status, actions, theme picker — v1.1
- ✓ Color themes with dark mode support — v1.1
- ✓ Sound alerts (ping for permissions, pop for done) — v1.1
- ✓ Single-instance enforcement via PID file — v1.1
- ✓ Global hotkeys for all actions — v1.1
- ✓ macOS Notification Center integration — v1.1
- ✓ Voice input via toggle record → on-device transcription → terminal injection — v2.0
- ✓ Auto-speak summaries (Apple Intelligence → Ava Premium TTS) — v2.0
- ✓ Summary hook (Python, fires on Claude stop) — v2.0
- ✓ Code Beeper horizontal pager UI with PNG buttons — v3.0-pre
- ✓ 8 color shell themes (black, orange, blue, green, purple, red, white, yellow) — v3.0-pre
- ✓ LED indicators with pulse animation — v3.0-pre
- ✓ Vibration effect with beep sounds — v3.0-pre
- ✓ Two-line LCD (title + scrolling detail) with YOLO badge — v3.0-pre
- ✓ Sound/mute interrupt button — v3.0-pre
- ✓ Marquee scrolling text for long details — v3.0-pre

### Active

<!-- Current scope — v3.0 Public Launch -->

- [ ] First-launch onboarding wizard (separate window)
- [ ] Claude Code detection before setup
- [ ] Permission requests with live status (Accessibility, Microphone, Speech Recognition)
- [ ] Hook auto-installation during onboarding
- [ ] Voice download guide (link to System Settings)
- [ ] Menu "Setup..." entry to re-trigger onboarding
- [ ] Menu "Download Voices..." entry
- [ ] Remove all hardcoded /Users/vcartier/ paths
- [ ] Delete old egg shell assets (shell-*.png)
- [ ] Fix compiler warnings (Sendable, unused vars)
- [ ] Extract vibration/buzz into dedicated service
- [ ] Clean up code organization
- [ ] DMG packaging for GitHub Releases
- [ ] Auto-install to /Applications
- [ ] Code signing / notarization for Gatekeeper
- [ ] Landing-style README with hero GIF, feature grid, badges
- [ ] Visual polish (animations, transitions, screen effects)
- [ ] Fix voice approach (evaluate Groq Whisper vs SFSpeech)
- [ ] Fix summary flow (manual trigger vs auto)

### Out of Scope

- iOS/iPad companion — macOS only
- App Store distribution — GitHub + DMG for now
- BYOK API keys — Apple Intelligence is free and on-device
- External TTS (OpenAI, ElevenLabs) — Ava Premium is adequate
- Per-project settings — ship with global settings first
- Hotkey remapping — ship with fixed hotkeys

## Context

- Swift 6.2+ / macOS 26+ / SwiftUI + AppKit
- Zero external dependencies — all system frameworks
- Python hook script bridges Claude Code events to the app via JSONL IPC
- Codebase is ~1500 LOC Swift, ~300 LOC Python
- Code Beeper UI redesign completed in manual session (not GSD-tracked)
- Target audience: Claude Code users who want a desktop companion

## Constraints

- **Platform**: macOS 26+ — uses FoundationModels, Speech framework
- **Dependencies**: No third-party frameworks
- **Distribution**: `make install` + DMG download from GitHub Releases
- **Signing**: Apple Development identity (Accessibility permission persistence)
- **Quality bar**: HN/Reddit/Twitter launch — must look and feel professional

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| File-based IPC over XPC/sockets | Simpler, works cross-process, debuggable | ✓ Good |
| No external dependencies | Minimal attack surface, easy distribution | ✓ Good |
| Code Beeper form factor (horizontal pager) | More screen space, buttons on shell, nostalgic | ✓ Good |
| PNG buttons (not programmatic) | Pixel-perfect Figma designs, no rendering issues | ✓ Good |
| Window-based vibration (not view offset) | Prevents sub-pixel blur on retina displays | ✓ Good |
| Separate onboarding window | Clean UX, doesn't clutter the beeper widget | — Pending |
| DMG + GitHub Releases | Broadest reach without App Store overhead | — Pending |

---
*Last updated: 2026-03-24 after v3.0 Public Launch milestone initialization*
