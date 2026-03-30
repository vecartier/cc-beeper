# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

CC-Beeper is a macOS floating widget companion for Claude Code. It displays Claude's state on a retro LCD pager, handles permission approvals via global hotkeys or on-screen buttons, and provides voice input/output (STT/TTS). Communication with Claude Code happens via a local HTTP server that receives curl-based hook events.

## Build & Run

```bash
# Build the app bundle
make build          # runs build.sh → swift build -c release → creates CC-Beeper.app

# Build + install hooks + launch
make install        # builds, runs setup.py to install hooks in ~/.claude/settings.json, opens app

# Run tests
swift test

# Create distributable DMG
make dmg

# Clean
make clean
```

After every build, copy CC-Beeper.app to /Applications.

The app requires macOS 26+ (Swift 6.2, FoundationModels framework).

## Architecture

### IPC — How CC-Beeper Talks to Claude Code

Communication uses a local HTTP server (`HTTPHookServer.swift`) running on `127.0.0.1`:

- **Claude Code → CC-Beeper**: Claude Code hooks fire curl commands that POST JSON to `http://localhost:{port}/hook`. The active port is written to `~/.claude/cc-beeper/port` on startup.
- **Permission flow**: Notification hook with `notification_type: "permission_prompt"` arrives via HTTP POST. CC-Beeper holds the TCP connection open until user clicks approve/deny. Response body (`hookSpecificOutput`) flows back through curl's stdout to Claude Code. Both Notification and PermissionRequest hooks are registered as blocking (no async, --max-time 55) to support the permission flow.
- **TTS trigger**: On Stop event, the HTTP payload includes `last_assistant_message` directly. CC-Beeper reads it aloud via TTS — no file parsing needed.

### State Machine (`ClaudeMonitor.swift`)

The core orchestrator. Four states: `.thinking` (tool calls in progress), `.finished` (idle, awaiting user), `.needsYou` (permission required), `.idle` (no sessions for 60s). Tracks multiple concurrent sessions via `sessionStates` dictionary.

### Voice — Dual-Engine Multilingual Architecture

Both STT and TTS use a primary engine with automatic fallback, driven by a single `kokoroLangCode` preference:

- **STT**: WhisperKit (on-device, 99 languages, batch transcription) → SFSpeech fallback. Model size selectable (small/medium) in Settings. Language hint from `kokoroLangCode`.
- **TTS**: Kokoro subprocess (Python venv at `~/.cache/cc-beeper/kokoro-venv/`) → Apple AVSpeechSynthesizer fallback. Supports 9 language codes (EN-US, EN-UK, FR, ES, IT, PT, HI, JA, ZH). Communicates via stdin/stdout + WAV file watcher.
- **Language preference**: Single `kokoroLangCode` in UserDefaults drives both STT and TTS. Defaults to macOS system language on first launch. Voice picker auto-filters to current language.

### UI Structure

- **Main window**: Transparent, always-on-top, 360×160px pager shell with LCD display
- **LCD**: 286×45px screen with 14×12px animated pixel-art character, state text, clock, icons
- **Buttons**: PNG-based with press states — Accept/Deny pill, Record, Terminal, Sound
- **Themes**: 10 shell colors (PNG images), dark mode toggle affects LCD colors
- **Settings**: 8-tab window (General, Audio, Voice, VoiceOver, Feedback, Hotkeys, Permissions, Setup, About)
- **Onboarding**: Multi-step wizard (Welcome, CLI detection, Permissions, Language, Model download, Done)

### Hook Installation

`HookInstaller.swift` registers 6 hook entries in `~/.claude/settings.json`:
1. 4 async monitoring hooks (PreToolUse, PostToolUse, Stop, StopFailure) using `curl -d @-` to pipe stdin JSON to the HTTP endpoint
2. 2 blocking hooks (Notification, PermissionRequest) using `curl --max-time 55` for the permission approval flow
Hook identification uses `cc-beeper/port` in the command string for safe update/removal without touching user hooks.

## Key Conventions

- App activation policy is `.accessory` — no dock icon, menu bar only
- Global hotkeys use character-based binding (layout-independent, resolves physical key via current keyboard layout): ⌥A accept, ⌥D deny, ⌥R record, ⌥T terminal, ⌥M mute
- IPC files use strict permissions: 0o700 directories, 0o600 files, symlink rejection
- Duplicate instance prevention via port file at `~/.claude/cc-beeper/port` — on launch, pings the port to check if another instance is responding
- Settings persist to UserDefaults
- `kokoro-tts-server.py` is bundled in Resources, runs as a subprocess with its own venv

## Dependencies

- **FluidAudio** (0.12.4): On-device ML (Kokoro TTS CoreML models)
- **WhisperKit** (0.17.0+): On-device Whisper speech recognition
- **HotKey** (0.2.1+): Global hotkey registration
- **FoundationModels**: Apple's on-device LLM framework (linked, macOS 26+)
