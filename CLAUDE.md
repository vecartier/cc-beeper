# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

CC-Beeper is a macOS floating widget companion for Claude Code. It displays Claude's state on a retro LCD pager, handles permission approvals via global hotkeys or on-screen buttons, and provides voice input/output (STT/TTS). Communication with Claude Code happens via file-based IPC through Python hook scripts.

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

All communication goes through `~/.claude/cc-beeper/`:

- **Claude Code → CC-Beeper**: Python hook (`cc-beeper-hook.py`) monitors 8 Claude Code events, appends to `events.jsonl`. CC-Beeper watches this file via `DispatchSource` (kqueue).
- **Permission flow**: Hook writes `pending.json` → CC-Beeper shows NEEDS YOU state → user presses button/hotkey → CC-Beeper writes `response.json` → hook polls for it (0.3s intervals, 55s timeout) → returns decision to Claude Code.
- **TTS trigger**: On Stop event, hook extracts last assistant message from session transcript → writes `last_summary.txt` → CC-Beeper detects and reads aloud.

### State Machine (`ClaudeMonitor.swift`)

The core orchestrator. Four states: `.thinking` (tool calls in progress), `.finished` (idle, awaiting user), `.needsYou` (permission required), `.idle` (no sessions for 60s). Tracks multiple concurrent sessions via `sessionStates` dictionary.

### Voice — Dual-Engine Architecture

Both STT and TTS use a primary engine with automatic fallback:

- **STT**: Parakeet TDT (on-device, FluidAudio) → SFSpeech fallback. Parakeet streams partial transcripts and injects them live into the terminal via CGEvent while the user is still speaking.
- **TTS**: Kokoro subprocess (Python venv at `~/.cache/cc-beeper/kokoro-venv/`) → Apple AVSpeechSynthesizer fallback. Kokoro communicates via stdin/stdout + WAV file watcher.

### UI Structure

- **Main window**: Transparent, always-on-top, 360×160px pager shell with LCD display
- **LCD**: 286×45px screen with 14×12px animated pixel-art character, state text, clock, icons
- **Buttons**: PNG-based with press states — Accept/Deny pill, Record, Terminal, Mute
- **Themes**: 10 shell colors (PNG images), dark mode toggle affects LCD colors
- **Settings**: 8-tab window (Theme, Voice Record, Voice Reader, Feedback, Hotkeys, Permissions, Setup, About)

### Hook Installation

`setup.py` (Python) and `HookInstaller.swift` (Swift equivalent) both:
1. Copy `cc-beeper-hook.py` to `~/.claude/hooks/`
2. Read existing `~/.claude/settings.json`
3. Merge CC-Beeper's 8 hook entries (removing old ones first)
4. Write back without clobbering user's other hooks

## Key Conventions

- App activation policy is `.accessory` — no dock icon, menu bar only
- Global hotkeys use Carbon-level key events (consumed, not leaked to focused app): ⌥A accept, ⌥D deny, ⌥R record, ⌥T terminal, ⌥M mute
- IPC files use strict permissions: 0o700 directories, 0o600 files, symlink rejection
- Duplicate instance prevention via PID file at `~/.claude/cc-beeper/cc-beeper.pid`
- Settings persist to UserDefaults
- The hook script is pure Python (no dependencies) for portability
- `kokoro-tts-server.py` is bundled in Resources, runs as a subprocess with its own venv

## Dependencies

- **FluidAudio** (0.13.2+): On-device ML for Parakeet STT
- **HotKey** (0.2.1+): Global hotkey registration
- **FoundationModels**: Apple's on-device LLM framework (linked, macOS 26+)
