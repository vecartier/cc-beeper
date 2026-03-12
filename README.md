# Claumagotchi

<p align="center">
  <img src="screenshot.png" alt="Claumagotchi" width="280">
</p>

A Tamagotchi-style desktop companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It floats above your windows and shows you what Claude is doing across all your sessions — thinking, done, or waiting for permission. You can approve or deny tool requests directly from the widget.

## Requirements

- macOS 14+
- Swift 5.10+ (comes with Xcode or Xcode Command Line Tools)
- Python 3 (comes with macOS)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## Install

### Quick install (DMG)

Download the latest `Claumagotchi.dmg` from [Releases](https://github.com/vecartier/Claumagotchi/releases), open it, and drag **Claumagotchi.app** to **Applications**. Then register the hooks:

```bash
cd ~/Claumagotchi   # or wherever you cloned the repo
python3 setup.py
open /Applications/Claumagotchi.app
```

To build the DMG yourself:

```bash
make dmg
```

### Build from source

```bash
git clone https://github.com/vecartier/Claumagotchi.git ~/Claumagotchi
cd ~/Claumagotchi
make install
```

That's it. The app builds, hooks are registered, and the widget launches. It will auto-launch every time you start a Claude Code session.

To build without installing hooks or launching:

```bash
make build
```

To launch manually:

```bash
open Claumagotchi.app
```

## How it works

Claumagotchi uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to monitor sessions. A Python hook script receives events from Claude Code and writes them to `/tmp/claumagotchi-events.jsonl`. The SwiftUI app watches that file and updates the display in real time.

```
Claude Code  -->  Hook (Python)  -->  /tmp/*.jsonl  -->  SwiftUI App
                       |                                      |
                  Permission? -----> /tmp/pending.json -----> Show UI
                       ^                                      |
                       +--------  /tmp/response.json  <-------+
```

The events file auto-truncates at 50KB to prevent unbounded growth.

### States

| State | What it means |
|-------|--------------|
| **THINKING...** | Claude is actively working (tool calls, reasoning) |
| **DONE!** | Claude finished and is waiting for your next message |
| **NEEDS YOU!** | Claude needs permission to use a tool |

### Buttons

Three buttons in an inverted-V layout on dark purple translucent backgrounds:

- **Left** (red X) — deny the permission request
- **Right** (green checkmark) — approve the permission request
- **Center** (purple arrow) — switch to your terminal

Permission state persists until you explicitly act — it won't disappear on its own.

## Menu bar

Click the egg icon in your menu bar for:

- **Allow / Deny** — handle permissions without touching the widget
- **Go to Conversation** — jump to your terminal
- **Enable/Disable Auto-Accept** — automatically approve all permission requests (shows "YOLO" on the LCD when active)
- **Enable/Disable Sounds** — toggle notification sounds
- **Theme** — pick a color pairing (Sunset, Sakura, Ocean, Forest, Lavender, Honey, Mint, Berry) and toggle dark mode
- **Show / Hide** — toggle the floating widget
- **Quit**

## Settings

Settings persist across restarts via UserDefaults:

- **Auto-Accept** — approve all tool permissions automatically (off by default). When active, a blinking "YOLO" indicator appears on the LCD screen.
- **Sounds** — play a chime when Claude finishes or needs permission (on by default)
- **Theme** — 8 color pairings for the shell and buttons (default: Sunset)
- **Dark Mode** — darkened shell and inverted LCD for low-light use

## Uninstall

```bash
cd ~/Claumagotchi
make uninstall
```

This removes the hooks from Claude Code settings, stops the app, and cleans up temp files. You can then delete the folder.

## Project structure

```
Claumagotchi/
  Package.swift          # Swift package manifest (macOS 14+, Swift 5.10)
  Makefile               # build / install / uninstall / dmg
  build.sh               # Builds the .app bundle
  create-dmg.sh          # Packages the app into a DMG for distribution
  setup.py               # Registers hooks with Claude Code
  uninstall.py           # Removes hooks and cleans up
  Sources/
    ClaumagotchiApp.swift # App entry, menu bar, window config
    ClaudeMonitor.swift   # State machine, file watcher, event processing
    ContentView.swift     # Egg shell UI, buttons, pixel title
    ScreenView.swift      # LCD screen, pixel character sprites
    ThemeManager.swift    # Color themes and dark mode
  hooks/
    claumagotchi-hook.py  # Claude Code hook script (installed to ~/.claude/hooks/)
```

## Important disclaimer

Claumagotchi lets you approve or deny Claude Code tool requests (file writes, shell commands, etc.) directly from the widget. **You are responsible for reviewing what you approve.** Clicking "Allow" grants Claude Code permission to execute the requested action on your machine.

**Auto-Accept mode** automatically approves every permission request without prompting you. When enabled, Claude Code will execute all tool calls — including file modifications, shell commands, and network requests — without asking for confirmation. **Use Auto-Accept at your own risk.** It is disabled by default for a reason.

The authors of this software are not liable for any damage, data loss, or unintended consequences resulting from approved tool executions, whether approved manually or via Auto-Accept. By using this software, you acknowledge that you understand and accept these risks.

Always review permission details in the widget or menu bar before approving, especially for destructive operations.

## License

MIT
