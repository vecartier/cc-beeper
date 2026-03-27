<p align="center">
  <img src="docs/cover.png" alt="CC-Beeper — all 10 color shells" width="700">
</p>

# CC-Beeper

<p align="center">
  A desktop companion for Claude Code. See what Claude is doing. Talk back.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-black?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6-orange?style=flat-square" alt="Swift 6">
  <img src="https://img.shields.io/badge/license-GPL--3.0-blue?style=flat-square" alt="GPL-3.0 License">
</p>

<p align="center">
  <a href="https://github.com/vecartier/cc-beeper/releases/latest"><strong>Download CC-Beeper</strong></a> · <code>brew install vecartier/tap/cc-beeper</code>
</p>

---

## Install

### Download (recommended)

[Download CC-Beeper.dmg](https://github.com/vecartier/cc-beeper/releases/latest) — open, drag CC-Beeper.app to Applications, and follow the one-time setup wizard.

### Homebrew

```bash
brew install vecartier/tap/cc-beeper
```

### Build from source

```bash
git clone https://github.com/vecartier/cc-beeper.git
cd cc-beeper
make install
```

`make install` builds the app, installs the Claude Code hooks, and launches CC-Beeper. Requires Swift (via Xcode Command Line Tools).

---

## What is CC-Beeper?

CC-Beeper is a floating macOS widget that lives on your desktop like a retro pager — updating its LCD display in real time as Claude Code works across your sessions. No tab-switching. No terminal watching. Just a glanceable companion that tells you what Claude is doing and lets you respond instantly.

| State | What it means |
|-------|--------------|
| **THINKING** | Claude is working — tool calls, file edits, reasoning in progress |
| **DONE** | Claude finished. Your next message is waiting. |
| **NEEDS YOU** | Claude needs permission to run a tool. Approve or deny from the widget. |

---

## Features

<table>
<tr>
<td align="center"><strong>Monitor</strong></td>
<td align="center"><strong>Voice Record</strong></td>
<td align="center"><strong>Voice Reader</strong></td>
<td align="center"><strong>Permissions</strong></td>
</tr>
<tr>
<td>Floating LCD pager shows Claude's live state across all sessions — no terminal watching required</td>
<td>Press Speak, dictate your message, CC-Beeper transcribes and injects it directly into Claude Code</td>
<td>CC-Beeper reads Claude's responses aloud using on-device AI voices (Kokoro) or Apple TTS</td>
<td>Approve or deny file writes, shell commands, and network calls without touching the terminal</td>
</tr>
<tr>
<td align="center"><strong>YOLO Mode</strong></td>
<td align="center"><strong>Themes</strong></td>
<td align="center"><strong>Global Hotkeys</strong></td>
<td align="center"><strong>Feedback</strong></td>
</tr>
<tr>
<td>Auto-approve all tool requests — YOLO badge on LCD when active</td>
<td>10 color shells with dark mode support: black, blue, green, mint, orange, pink, purple, red, white, yellow</td>
<td>Control CC-Beeper from any app without switching focus — accept, deny, record, mute</td>
<td>Sound effects for state changes and haptic-style vibration alerts when Claude needs your attention</td>
</tr>
</table>

---

## Settings

CC-Beeper's settings are organized into tabs:

| Tab | What it controls |
|-----|-----------------|
| **Theme** | Shell color picker and dark mode |
| **Voice Record** | TTS provider (Kokoro / Apple), voice selection, preview |
| **Voice Reader** | Voice reader toggle, STT engine info |
| **Feedback** | Sound effects and vibration toggles |
| **Hotkeys** | Remap global hotkeys (⌥ + key) |
| **Permissions** | Accessibility, microphone, speech recognition status |
| **Setup** | Re-run setup wizard or uninstall CC-Beeper |
| **About** | Version, links, and credits |

---

## Global Hotkeys

All hotkeys use **⌥ Option** as the modifier. Remap them in Settings > Hotkeys.

| Shortcut | Action |
|----------|--------|
| ⌥ A | Accept permission |
| ⌥ D | Deny permission |
| ⌥ R | Voice record (push to talk) |
| ⌥ T | Go to terminal |
| ⌥ M | Voice reader / stop |

---

## How it works

CC-Beeper uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to monitor sessions. A lightweight Python hook receives events from Claude Code and writes them to a shared IPC directory. The macOS app watches those files and updates instantly.

```
Claude Code  ──►  Hook (Python)  ──►  ~/.claude/cc-beeper/events.jsonl  ──►  CC-Beeper.app
                       │                                                        │
                  Permission? ───►  ~/.claude/cc-beeper/pending.json  ─────────►  Show NEEDS YOU
                       ▲                                                        │
                       └────────  ~/.claude/cc-beeper/response.json  ◄─────────┘
```

---

## Requirements

- macOS 14 or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- (Optional) Run setup wizard to download on-device AI voice models (~930 MB)

---

## Important disclaimer

> CC-Beeper lets you approve or deny Claude Code tool requests directly from the widget. **You are responsible for reviewing what you approve.** Clicking "Allow" grants Claude Code permission to execute the requested action on your machine.
>
> **YOLO mode** automatically approves every permission request without prompting. When enabled, Claude Code will execute all tool calls — including file modifications, shell commands, and network requests — without asking for confirmation. **Use YOLO mode at your own risk.**
>
> The authors are not liable for any damage, data loss, or unintended consequences. By using CC-Beeper, you accept these risks.

---

## Contributing

Contributions are welcome.

1. Fork the repo and create a feature branch
2. CC-Beeper is a Swift Package — open `Package.swift` in Xcode or build with `make build`
3. Submit a pull request with a clear description

CC-Beeper uses Claude Code's hooks system. See the [Hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks) for how the IPC layer works.

- **Bug reports:** open a GitHub issue
- **Feature requests:** open a GitHub discussion

---

## License

GPL-3.0 — see [LICENSE](LICENSE)
