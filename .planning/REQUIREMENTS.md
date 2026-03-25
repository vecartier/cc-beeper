# Requirements: CC-Beeper (Claumagotchi)

**Defined:** 2026-03-24
**Core Value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow

## v3.0 Requirements

Requirements for Public Launch milestone. Each maps to roadmap phases.

### Onboarding

- [x] **ONBD-01**: Welcome screen with illustration, title, description of what CC-Beeper does, and "Get Started" button
- [x] **ONBD-02**: Step 1 — Scan for Claude Code CLI + hooks installation. Shows toggle that turns green when detected/installed
- [x] **ONBD-03**: Step 2 — Permissions: Voice/Microphone/Accessibility with toggles that redirect to System Settings and turn green when granted. User can skip and do later
- [x] **ONBD-04**: Step 3 — Download premium voices with link to System Settings > Spoken Content
- [x] **ONBD-05**: Success screen — "All set! Restart Claude Code to activate hooks"
- [x] **ONBD-06**: App installs to /Applications on first launch (wherever DMG was opened from)
- [x] **ONBD-07**: Menu bar "Setup..." entry re-opens onboarding wizard

### Menu Bar (Popover)

- [x] **MENU-01**: Click menu bar icon opens rich popover panel (replaces dropdown menu)
- [x] **MENU-02**: Quick toggles at top of popover: YOLO mode, mute/sound, hide widget, quit
- [x] **MENU-03**: Advanced settings section: theme picker, dark mode, auto-speak, vibration, notifications
- [x] **MENU-04**: Permissions section with live status toggles (re-trigger from here)
- [x] **MENU-05**: About section with version, GitHub link
- [x] **MENU-06**: "Setup..." and "Download Voices..." entries in popover

### Code Quality

- [x] **CODE-01**: All hardcoded `/Users/vcartier/` fallback paths removed from image loaders
- [x] **CODE-02**: Old egg shell assets (shell-*.png) deleted from Sources/shells/
- [x] **CODE-03**: All compiler warnings fixed (Sendable closures, unused variables)
- [x] **CODE-04**: Vibration/buzz logic extracted into dedicated BuzzService
- [x] **CODE-05**: Clean file organization (one type per file, consistent naming)

### Distribution

- [x] **DIST-01**: DMG package builds via `make dmg` with app icon and /Applications symlink
- [x] **DIST-02**: GitHub Release workflow with DMG artifact upload
- [x] **DIST-03**: Notarization via `notarytool` so Gatekeeper doesn't block the app
- [x] **DIST-04**: Auto-copy to /Applications on first launch

### GitHub

- [ ] **GH-01**: Landing-style README with hero GIF showing the beeper in action
- [ ] **GH-02**: Feature grid with icons (monitoring, voice, permissions, themes)
- [ ] **GH-03**: One-liner install command + DMG download link
- [ ] **GH-04**: Screenshots of all shell color themes
- [ ] **GH-05**: Contributing guide and license

### Visual Polish

- [x] **VFX-01**: Smooth state transitions on LCD (fade between states, not instant swap)
- [x] **VFX-02**: Dark mode shell variants render correctly with LCD overlay
- [x] **VFX-03**: Consistent button press feedback across all buttons

### Voice

- [x] **VOICE-05**: Voice recording uses Groq Whisper API (WAV file → API → text) instead of SFSpeech
- [x] **VOICE-06**: API key stored in macOS Keychain (prompted during onboarding if voice enabled)
- [x] **VOICE-07**: Summary flow: manual "Summarize" button when Claude finishes, not just auto-speak

## Future Requirements

### Post-Launch

- **POST-01**: Homebrew tap (`brew install cc-beeper`)
- **POST-02**: Per-project settings
- **POST-03**: Hotkey remapping
- **POST-04**: Conversation history panel
- **POST-05**: Custom TTS voice selection

## Out of Scope

| Feature | Reason |
|---------|--------|
| iOS/iPad companion | macOS only |
| App Store distribution | GitHub + DMG for v3.0 |
| BYOK API keys (beyond Groq) | Groq free tier sufficient |
| External TTS (OpenAI, ElevenLabs) | Ava Premium is adequate |
| Dropdown menu | Replaced by popover panel |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ONBD-01 | Phase 13 | Complete |
| ONBD-02 | Phase 13 | Complete |
| ONBD-03 | Phase 13 | Complete |
| ONBD-04 | Phase 13 | Complete |
| ONBD-05 | Phase 13 | Complete |
| ONBD-06 | Phase 13 | Complete |
| ONBD-07 | Phase 13 | Complete |
| MENU-01 | Phase 14 | Complete |
| MENU-02 | Phase 14 | Complete |
| MENU-03 | Phase 14 | Complete |
| MENU-04 | Phase 14 | Complete |
| MENU-05 | Phase 14 | Complete |
| MENU-06 | Phase 14 | Complete |
| CODE-01 | Phase 12 | Complete |
| CODE-02 | Phase 12 | Complete |
| CODE-03 | Phase 12 | Complete |
| CODE-04 | Phase 12 | Complete |
| CODE-05 | Phase 12 | Complete |
| DIST-01 | Phase 17 | Complete |
| DIST-02 | Phase 17 | Complete |
| DIST-03 | Phase 17 | Complete |
| DIST-04 | Phase 17 | Complete |
| GH-01 | Phase 18 | Pending |
| GH-02 | Phase 18 | Pending |
| GH-03 | Phase 18 | Pending |
| GH-04 | Phase 18 | Pending |
| GH-05 | Phase 18 | Pending |
| VFX-01 | Phase 16 | Complete |
| VFX-02 | Phase 16 | Complete |
| VFX-03 | Phase 16 | Complete |
| VOICE-05 | Phase 15 | Complete |
| VOICE-06 | Phase 15 | Complete |
| VOICE-07 | Phase 15 | Complete |

**Coverage:**
- v3.0 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-24*
