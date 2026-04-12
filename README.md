<div align="center">

# CC-Beeper

**A floating macOS pager for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).**

*Stop babysitting your terminal. Start shipping.*

<img src="assets/hero.gif" width="320">

<br><br>

<a href="https://github.com/vecartier/cc-beeper/releases/latest/download/CC-Beeper.dmg">
  <img src="https://img.shields.io/badge/%EF%A3%BF_DOWNLOAD_FOR_MAC-DMG-black?style=for-the-badge&labelColor=555555" alt="Download for Mac">
</a>



</div>

---

## Why I Made This

You kick off a task in Claude Code. Then life happens. Claude finishes, or hits an error, or needs a permission — but your terminal is buried under three windows.

CC-Beeper fixes that. It's a small widget that sits on your desktop, shows what Claude is doing, and lets you respond without switching apps. Never miss an update. Respond without breaking your flow.

---

## See It in Action

https://github.com/user-attachments/assets/d65f557b-1b5e-41f9-b9fe-9826897f9140

---

## Features

### Real-Time States

At a glance, know exactly what Claude is up to. CC-Beeper tracks 8 states, each with its own pixel-art animation. Higher-urgency events always take priority.

| State | | What it means |
|-------|-------|--------------|
| **SNOOZING** | <img src="assets/states/snoozing.png" width="200"> | No active session. Claude is idle. |
| **WORKING** | <img src="assets/states/working.png" width="200"> | Claude is running a tool — *Busy with bash*, *Tinkering with write*... |
| **DONE!** | <img src="assets/states/done.png" width="200"> | Task completed successfully. |
| **ERROR** | <img src="assets/states/error.png" width="200"> | Something went wrong. |
| **ALLOW?** | <img src="assets/states/allow.png" width="200"> | Claude needs permission. Approve (⌥A) or deny (⌥D). |
| **INPUT?** | <img src="assets/states/input.png" width="200"> | Claude asked a question. Waiting for your response. |
| **LISTENING** | <img src="assets/states/listening.png" width="200"> | Recording your voice for dictation. |
| **RECAP** | <img src="assets/states/recap.png" width="200"> | Reading Claude's last response aloud. |

---

### Auto-Accept Modes

When Claude Code needs to use a tool, CC-Beeper can auto-approve it or ask you first. Four presets let you dial the automation while keeping control. Switchable anytime from the menu bar.

| Mode | What happens |
|------|-------------|
| **Strict** | Ask me every time. Nothing runs without your approval. |
| **Relaxed** | Reads are fine. Asks before writes and commands. |
| **Trusted** | File operations are fine. Asks before shell commands. |
| **YOLO** | Don't ask. Just do it. Auto-approves everything — including file writes, deletes, and shell commands. |

---

### Voice

#### Dictation

Prompt Claude, or answer its questions, just by talking. Toggle with **⌥R** from anywhere, or **double clap** to go fully hands-free.

- **WhisperKit** — on-device, 99 languages, no cloud, no API key
- **Apple Speech** — built-in fallback, no download needed
- Works with Terminal.app, iTerm2, Warp, Alacritty, Kitty, and WezTerm

#### Read Aloud

Claude finished? Hear the summary out loud.

- **Kokoro** — on-device, 54 voices across 9 languages
- **Apple Speech** — built-in fallback

---

### Global Hotkeys

Use them from any app, in any keyboard layout (AZERTY, QWERTZ, Dvorak). All remappable in Settings.

| Hotkey | Action |
|--------|--------|
| **⌥A** | Approve pending permission |
| **⌥D** | Deny pending permission |
| **⌥R** | Toggle voice recording |
| **⌥T** | Focus the active terminal |
| **⌥M** | Stop TTS / replay last response |

---

### Themes, Sizes & Sound

- **10 shell colors**
- **3 widget sizes** — Large (buttons + LCD), Compact (LCD only), or Menu Only (icon in the menu bar)
- **Sound & haptics** — ping on permission requests, chime on task completion, vibration until resolved

![Shell colors](assets/shell-colors.png)

---

## Getting Started

**Requirements:** macOS 14 Sonoma+ · [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

1. Download the [latest release](https://github.com/vecartier/cc-beeper/releases)
2. Move `CC-Beeper.app` to `/Applications`
3. Launch — the onboarding wizard handles hooks, theme, permissions, voice engines, and hotkeys

Everything is optional and can be changed later in Settings.

---

## Privacy

> **All local. No API keys. Nothing leaves your Mac.**

- All communication happens over `127.0.0.1` — plain `curl` hooks to a local HTTP server
- No telemetry, no analytics, no crash reporting — zero outbound connections
- WhisperKit and Kokoro run on-device. Your voice is never uploaded
- No accounts, no sign-up, no tokens
- Hooks are transparent — inspect or remove them from `~/.claude/settings.json` anytime

---

## Technical Details

<details>
<summary><strong>How the hooks work</strong></summary>

CC-Beeper binds to a local port (19222-19230) on launch and registers 7 hook scripts in `~/.claude/settings.json`: UserPromptSubmit, PreToolUse, PostToolUse, Stop, StopFailure (all async), plus Notification and PermissionRequest (blocking — CC-Beeper holds the TCP connection open until the user responds).

Hooks are identified by `cc-beeper/port` in the command string for safe update/removal without touching user hooks.

</details>

<details>
<summary><strong>Session management</strong></summary>

CC-Beeper tracks multiple concurrent Claude Code sessions. The displayed state resolves by priority across all active sessions. Sessions auto-prune after 2 hours of inactivity.

</details>

<details>
<summary><strong>Instance detection</strong></summary>

On launch, CC-Beeper pings ports 19222-19230 via HTTP to detect if another instance is already running, preventing conflicts.

</details>

<details>
<summary><strong>Menu bar</strong></summary>

The menu bar icon reflects the current state: normal (outline), attention (orange), YOLO (purple), recording (red circle), speaking (green speaker), or hidden (dimmed).

The menu contains: session count, state label, Mute/Unmute, Sleep/Wake, Clap Dictation toggle, Fix Permissions (when needed), auto-accept preset picker, size picker, hotkey reference, Settings, and Quit.

</details>

<details>
<summary><strong>Settings</strong></summary>

| Tab | What's inside |
|-----|--------------|
| **Theme** | 10 shell colors |
| **Dictation** | Double Clap Dictation toggle, Whisper model size (small/medium), download |
| **Read Over** | Auto-speak toggle, Kokoro/Apple picker, language & voice |
| **Feedback** | Sound + vibration toggles |
| **Hotkeys** | 5 remappable hotkey fields |
| **Permissions** | 4 preset radio buttons |
| **Setup** | Reinstall hooks, reopen onboarding |
| **About** | Version, credits, links |

</details>

---

## Disclaimer

**CC-Beeper is an independent, community-built project. It is not affiliated with, endorsed by, or sponsored by Anthropic.**

CC-Beeper was designed and fully vibe-coded with [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Use it at your own risk.

Auto-accept modes approve Claude Code tool requests on your behalf — including file modifications, shell commands, and network requests. **YOLO mode approves everything without prompting.** You are responsible for reviewing what you approve.

The authors are not liable for any damage, data loss, or unintended consequences.

---

## Contributing

Feature suggestions and code improvements are welcome.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/your-idea`)
3. Commit your changes
4. Open a Pull Request

---

## License

GPL-3.0 — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built by [Victor Cartier](https://github.com/vecartier)**

Free · Open Source · Native macOS

If CC-Beeper saves you from one missed permission prompt, give it a ⭐

</div>
