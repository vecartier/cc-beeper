<!-- Replace docs/demo.gif with your screen recording when ready -->
<p align="center">
  <img src="docs/demo.gif" alt="CC-Beeper in action" width="600">
</p>

# CC-Beeper

<p align="center">
  A retro pager companion for Claude Code. Floats on your screen. Shows what Claude is doing. Lets you talk back.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-black?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6-orange?style=flat-square" alt="Swift 6">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License">
</p>

<p align="center">
  <a href="https://github.com/vecartier/Claumagotchi/releases/latest"><strong>⬇ Download DMG</strong></a>
</p>

---

## Install

### Download (recommended)

[Download CC-Beeper.dmg](https://github.com/vecartier/Claumagotchi/releases/latest) — open, double-click CC-Beeper.app, and follow the setup wizard. No Terminal required.

### Build from source

```bash
git clone https://github.com/vecartier/Claumagotchi.git
cd Claumagotchi
make install
```

`make install` builds the app, installs hooks, and launches CC-Beeper. Requires Swift (via Xcode Command Line Tools).

---

## What is CC-Beeper?

CC-Beeper is a floating macOS desktop widget that shows you what Claude Code is doing across all your sessions — and lets you respond without touching the terminal. It sits on screen like a retro pager, updating its LCD display in real time.

| State | Meaning |
|-------|---------|
| THINKING | Claude is working — tool calls, file edits, reasoning |
| DONE | Claude finished and is waiting for your next message |
| NEEDS YOU | Claude needs permission to run a tool |

---

## Features

<table>
<tr>
<td align="center"><strong>Monitor</strong></td>
<td align="center"><strong>Voice</strong></td>
<td align="center"><strong>Permissions</strong></td>
<td align="center"><strong>Themes</strong></td>
</tr>
<tr>
<td>🖥️ Floating LCD pager shows Claude's state in real time across all sessions</td>
<td>🎙️ Press Speak, dictate your message, CC-Beeper injects it into Claude Code</td>
<td>✅ Approve or deny tool requests — file writes, shell commands, network calls — without touching the terminal</td>
<td>🎨 10 color shells: black, blue, green, mint, orange, pink, purple, red, white, yellow</td>
</tr>
</table>

- **YOLO mode** — auto-approve all tool requests (shows YOLO on LCD when active)
- **Vibration alerts** — haptic-style window shake when Claude needs you
- **Global hotkeys** — control CC-Beeper without switching focus
- **Auto-speak** — CC-Beeper reads Claude's summaries aloud when it finishes

---

## Shell Themes

<!-- docs/cover.png = your cover image showing all 10 shells on black background -->
<p align="center"><img src="docs/cover.png" alt="All 10 CC-Beeper color shells" width="700"></p>

Choose from 10 color shells — black, blue, green, mint, orange, pink, purple, red, white, yellow. Dark mode supported.

---

## How it works

CC-Beeper uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to monitor sessions. A Python hook script receives events from Claude Code and writes them to a shared IPC directory. The macOS app watches those files and updates in real time.

```
Claude Code  ──►  Hook (Python)  ──►  /tmp/cc-beeper/*.jsonl  ──►  CC-Beeper.app
                       │                                                │
                  Permission? ───►  /tmp/cc-beeper/pending.json ───────►  Show NEEDS YOU
                       ▲                                                │
                       └────────  /tmp/cc-beeper/response.json  ◄──────┘
```

---

## Requirements

- macOS 14 or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- (Optional) Groq API key for higher-quality voice transcription
- (Optional) OpenAI API key for AI-powered text-to-speech

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

CC-Beeper uses Claude Code's hooks system. See [Hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks) for how the IPC layer works.

- **Bug reports:** open a GitHub issue
- **Feature requests:** open a GitHub discussion

---

## License

MIT — see [LICENSE](LICENSE)
