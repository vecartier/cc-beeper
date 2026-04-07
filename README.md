<div align="center">

# CC-Beeper

**A retro pager companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on macOS.**

Never miss a permission request, task completion, or error again — even when Claude Code is buried under 30 tabs.

<img src="assets/hero.gif" width="320">

<br><br><br>

<a href="https://github.com/vecartier/cc-beeper/releases/latest/download/CC-Beeper.dmg">
  <img src="https://img.shields.io/badge/%EF%A3%BF_DOWNLOAD_FOR_MAC-DMG-black?style=for-the-badge&labelColor=555555" alt="Download for Mac">
</a>

</div>

---

CC-Beeper is a tiny macOS widget that sits on your desktop and stays connected to Claude Code via local HTTP hooks. It shows what Claude is doing on a retro pixel-art LCD, plays sounds when it needs attention, and lets you approve or deny permissions with a hotkey — no terminal switching required.

Think of it as a pager for your AI coding assistant.

https://github.com/user-attachments/assets/d65f557b-1b5e-41f9-b9fe-9826897f9140

---

## LCD States

The screen shows 8 states, each with its own pixel-art animation and rotating subtitle pool. States follow a strict priority order so higher-urgency events always surface first.

| State | | What's happening |
|-------|-------|-----------------|
| **SNOOZING** | <img src="assets/states/snoozing.png" width="200"> | No active session for 60s. The character sleeps. |
| **WORKING** | <img src="assets/states/working.png" width="200"> | Claude is running a tool — shows what it's doing: *Busy with bash*, *Tinkering with write*... |
| **DONE!** | <img src="assets/states/done.png" width="200"> | Task completed. Blinks, then fades to idle after 3 min. |
| **ERROR** | <img src="assets/states/error.png" width="200"> | Task failed. Glitch entrance followed by a pixel meltdown. |
| **ALLOW?** | <img src="assets/states/allow.png" width="200"> | Permission needed. Press ⌥A to approve, ⌥D to deny. |
| **INPUT?** | | Claude asked a question and is waiting for your response. |
| **LISTENING** | <img src="assets/states/listening.png" width="200"> | Voice recording active — you're dictating a prompt. |
| **RECAP** | <img src="assets/states/recap.png" width="200"> | TTS is reading Claude's last response aloud. |

Priority: Error > Allow? > Input? > Listening > Recap > Working > Done > Snoozing.

---

## Permission Presets

Four modes that control how much CC-Beeper auto-approves on your behalf. Switchable from the menu bar.

| Preset | Behavior |
|--------|----------|
| **Strict** | Nothing auto-approved. Every tool needs manual approval. |
| **Relaxed** | Auto-approves reads (Read, Glob, Grep). Asks for everything else. |
| **Trusted** | Auto-approves file operations (Read, Glob, Grep, Write, Edit). Asks for bash. |
| **YOLO** | Auto-approves everything. The LCD character swaps to a rabbit. |

---

## Voice

### Dictation (STT)

Dictate prompts into Claude Code without touching the keyboard. Toggle with **⌥R** from anywhere, or **double clap** to go fully hands-free — clap twice to start recording, twice again to stop and send.

- **WhisperKit** — on-device transcription, 99 languages, small (~2 GB) or medium (~5 GB) model
- **Apple SFSpeech** fallback when Whisper isn't available
- Injects text into the focused terminal via keyboard simulation (Terminal.app, iTerm2, Warp, Alacritty, Kitty, WezTerm)

### Read Over (TTS)

Have Claude read its responses aloud when a task finishes.

- **Kokoro** — on-device, 54 voices across 9 languages (English US/UK, Spanish, French, Hindi, Italian, Japanese, Portuguese, Chinese)
- **Apple AVSpeechSynthesizer** fallback
- A single language preference drives both STT and TTS

---

## Widget Sizes

Three modes depending on how much screen space you want to give it:

- **Large** — full beeper with LCD + buttons (approve, deny, record, sound, terminal)
- **Compact** — LCD only, interact via hotkeys
- **Menu Only** — no widget on screen, just the menu bar icon

The menu bar icon is always visible in all modes.

---

## Themes

10 shell colors, each with a dark mode LCD variant.

![Shell colors](assets/shell-colors.png)

---

## Global Hotkeys

Work from any app, in any keyboard layout (AZERTY, QWERTZ, Dvorak). All remappable in Settings.

| Hotkey | Action |
|--------|--------|
| **⌥A** | Approve pending permission |
| **⌥D** | Deny pending permission |
| **⌥R** | Toggle voice recording |
| **⌥T** | Focus the active terminal |
| **⌥M** | Stop TTS / replay summary |

---

## Sound & Haptics

- **Ping** on permission and input requests
- **Pop** chime on task completion
- **Vibration** on done (3s) and on permission/input requests (repeats every 15s until resolved)
- Click the beeper to cancel vibration

---

## Getting Started

### Requirements

- macOS 26 or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed

### Install

1. Download the latest release from [Releases](https://github.com/vecartier/cc-beeper/releases)
2. Move `CC-Beeper.app` to `/Applications`
3. Launch — the onboarding wizard walks you through everything

### Onboarding

7 steps: hook installation, theme picker, widget size, permission preset, macOS permissions (Accessibility, Microphone, Speech Recognition), voice engine download (Kokoro + WhisperKit), and hotkey configuration.

Everything is optional and can be changed later in Settings.

---

## Settings

| Tab | What's inside |
|-----|--------------|
| **Theme** | 10 shell colors + dark mode toggle |
| **Dictation** | Whisper model size (small/medium), download |
| **Read Over** | Auto-speak toggle, Kokoro/Apple picker, language & voice |
| **Feedback** | Sound + vibration toggles |
| **Hotkeys** | 5 remappable hotkey fields |
| **Permissions** | 4 preset radio buttons |
| **Setup** | Reinstall hooks, reopen onboarding |
| **About** | Version, credits, links |

---

## Privacy

CC-Beeper is fully local. Nothing leaves your machine.

- **No network calls** — all communication happens over `127.0.0.1` between Claude Code's hooks and CC-Beeper's local HTTP server
- **No telemetry, no analytics, no crash reporting** — zero outbound connections
- **On-device speech** — WhisperKit and Kokoro both run locally. Your voice data is never uploaded
- **No accounts** — no sign-up, no login, no tokens
- **Hooks are transparent** — 7 entries in `~/.claude/settings.json`, all plain `curl` commands to `localhost`. Inspect or remove them anytime
- **Permissions are minimal** — Accessibility (hotkeys), Microphone (dictation), Speech Recognition (fallback STT). None are required

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

The menu bar icon reflects the current state: normal (outline), attention (orange), YOLO (purple), recording (circle+stop), speaking (speaker+waves), or hidden (dimmed).

The menu contains: session count, state label, Sleep/Wake toggle, permission preset picker, size picker, hotkey list, Settings, and Quit.

</details>

---

## Disclaimer

> CC-Beeper lets you approve or deny Claude Code tool requests directly from the widget. **You are responsible for reviewing what you approve.**
>
> **YOLO mode** automatically approves every permission request without prompting — including file modifications, shell commands, and network requests. **Use at your own risk.**
>
> The authors are not liable for any damage, data loss, or unintended consequences.

---

## Contributing

Contributions, ideas, and bug reports are welcome.

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

If CC-Beeper saves you from one missed permission prompt, give it a star.

</div>
