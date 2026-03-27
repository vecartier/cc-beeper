# Roadmap: CC-Beeper

## Milestones

- ✅ **v1.1 Polish + Hardening** - Phases 1-4 (shipped 2026-03-20)
- ❌ **v2.0 Voice & Intelligence** - Phases 5-8 (reverted 2026-03-21)
- ✅ **v2.0 Voice Loop** - Phases 9-11 (shipped 2026-03-22)
- ✅ **v3.0 Public Launch** - Phases 12-18 (shipped 2026-03-25)
- 🚧 **v3.1 Polish & Fixes** - Phases 19-22 (in progress)
- ✅ **v4.0 Offline Voice** - Phases 23-26 (shipped 2026-03-27)
- 🆕 **v5.0 Polish & Distribution** - Phases 27-29 (planned)

## Overview

v1.1 hardened the foundation. v2.0 Voice Loop added hands-free voice I/O and auto-speak summaries. v3.0 Public Launch made CC-Beeper ready for strangers: code cleanup, onboarding, rich menu popover, Groq voice, visual polish, DMG distribution, and a landing-style GitHub README. v3.1 Polish & Fixes erases all Claumagotchi traces (laptop-wide and in-repo), fixes the broken auto-speak TTS flow, refreshes the GitHub presence with new cover art and rewritten copy, and adds a beeper-shaped menu bar icon — closing with a full branding pass once the user provides the Figma-exported assets. v4.0 Offline Voice replaces all cloud voice APIs with on-device AI: FluidAudio brings Parakeet TDT for transcription and Kokoro-82M for TTS, eliminating every API key dependency. Cleanup removes all Groq/OpenAI voice paths and the Keychain infrastructure that supported them. v5.0 Polish & Distribution fixes the two voice reliability regressions introduced by the offline models (STT injection and TTS delays), renames "Auto-speak" to "VoiceOver" throughout the app, and ships a branded DMG + Homebrew tap so users can install with one command.

## Phases

<details>
<summary>✅ v1.1 Polish + Hardening (Phases 1-4) - SHIPPED 2026-03-20</summary>

### Phase 1: Hardening
**Plans:** 2/2 complete

### Phase 2: Reliability + Performance
**Plans:** 2/2 complete

### Phase 3: UX Enhancements
**Plans:** 2/2 complete

### Phase 4: Notifications
**Plans:** 2/2 complete

</details>

<details>
<summary>❌ v2.0 Voice & Intelligence (Phases 5-8) - REVERTED 2026-03-21</summary>

### Phase 5: Settings Window
**Plans:** 2/2 complete

### Phase 6: Activity Feed
**Plans:** 2/2 complete

### Phase 7: AI Summary
**Plans:** 2/2 complete

### Phase 8: Voice Input + Layout
**Plans:** 2/2 complete

</details>

<details>
<summary>✅ v2.0 Voice Loop (Phases 9-11) - SHIPPED 2026-03-22</summary>

### Phase 9: UI + Controls
**Plans:** 3/3 complete

### Phase 10: Voice Input + Injection
**Plans:** 1/1 complete

### Phase 11: Auto-Speak + Summary Hook
**Plans:** 2/2 complete

</details>

<details>
<summary>✅ v3.0 Public Launch (Phases 12-18) - SHIPPED 2026-03-25</summary>

### Phase 12: Code Quality
**Goal**: The codebase is clean, portable, and warning-free — no hardcoded user paths, no dead assets, no compiler noise
**Depends on**: Phase 11
**Requirements**: CODE-01, CODE-02, CODE-03, CODE-04, CODE-05
**Success Criteria** (what must be TRUE):
  1. App builds and runs on a machine that is not /Users/vcartier/ — no crash or missing asset from hardcoded paths
  2. No shell-*.png files exist in Sources/shells/ — old egg assets fully removed
  3. Xcode builds with zero warnings (Sendable, unused variables, all categories)
  4. Vibration/buzz behavior is managed by a dedicated BuzzService — no inline buzz logic scattered across views
  5. Each Swift file contains exactly one type, files are consistently named to match their type
**Plans**: 2/2 complete

### Phase 13: Onboarding
**Goal**: First-time users are guided through everything they need to start using CC-Beeper — no manual Terminal commands, no confusion
**Depends on**: Phase 12
**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05, ONBD-06, ONBD-07
**Success Criteria** (what must be TRUE):
  1. On first launch, a separate onboarding window opens automatically before the beeper widget appears
  2. User can see step-by-step progress: welcome → CLI detection + hooks → permissions → voice download → success
  3. The Claude Code CLI detection toggle turns green when the CLI is found and hooks are installed
  4. Permission toggles (Accessibility, Microphone, Speech Recognition) redirect to System Settings and turn green when granted; user can skip
  5. On success screen, user sees "Restart Claude Code to activate hooks" instruction
  6. App copies itself to /Applications on first launch (wherever it was opened from)
  7. "Setup..." entry in the menu bar re-opens the onboarding window at any time
**Plans**: 4/4 complete

### Phase 14: Menu Bar Popover
**Goal**: The menu bar icon opens a rich popover panel that replaces the old dropdown — all settings and controls in one place
**Depends on**: Phase 13
**Requirements**: MENU-01, MENU-02, MENU-03, MENU-04, MENU-05, MENU-06
**Success Criteria** (what must be TRUE):
  1. Clicking the menu bar icon opens a popover panel (not a dropdown menu)
  2. Quick toggles at the top of the popover control YOLO mode, mute/sound, widget visibility, and quit
  3. Advanced settings section exposes theme picker, dark mode, auto-speak, vibration, and notifications
  4. Permissions section shows live status for each permission and lets users re-trigger them from the popover
  5. About section shows the app version and a clickable GitHub link
  6. "Setup..." and "Download Voices..." entries are present and functional in the popover
**Plans**: 2/2 complete

### Phase 15: Voice Fixes
**Goal**: On-device voice works reliably by default; optional BYOK API keys (Groq Whisper for transcription, OpenAI for TTS) unlock higher quality; keys are stored securely in Keychain and configurable in Settings and onboarding
**Depends on**: Phase 12
**Requirements**: VOICE-05, VOICE-06, VOICE-07
**Success Criteria** (what must be TRUE):
  1. With no API keys set, pressing Speak records and transcribes using on-device SFSpeechRecognizer (no regression)
  2. With a Groq API key set, pressing Speak records a WAV file and sends it to Groq Whisper API for transcription
  3. With an OpenAI API key set, TTS uses the OpenAI API instead of AVSpeechSynthesizer
  4. API keys are stored in macOS Keychain, editable in Settings > Voice, and promptable in an optional onboarding step
**Plans**: 2/2 complete

### Phase 16: Visual Polish
**Goal**: CC-Beeper looks and feels finished — deep rename from Claumagotchi, LCD bounce animation, dark mode verification, button feedback, vibration fixes, Xcode-style Settings sidebar
**Depends on**: Phase 14, Phase 15
**Requirements**: VFX-01, VFX-02, VFX-03
**Success Criteria** (what must be TRUE):
  1. All references to "Claumagotchi" replaced with "CC-Beeper" (bundle ID, binary, Package.swift, user-facing strings, hook scripts, build scripts)
  2. Pixel character does a quick vertical bounce when LCD state changes (retro feel, not text crossfade)
  3. Dark mode shell variants display correctly with the LCD overlay — no tinting artifacts or misalignment
  4. Every button produces identical PNG-swap press feedback on tap
  5. Clicking the beeper window stops the current vibration; window remains draggable during shake
  6. Settings window has Xcode-style sidebar with 4 tabs (Audio, Permissions, Voice, About)
**Plans**: 3/3 complete

### Phase 17: Distribution
**Goal**: Anyone can download and install CC-Beeper in under 60 seconds — no Gatekeeper warnings, no manual drag-to-Applications
**Depends on**: Phase 16
**Requirements**: DIST-01, DIST-02, DIST-03, DIST-04
**Success Criteria** (what must be TRUE):
  1. Running `make dmg` produces a signed DMG with the app icon and an /Applications symlink
  2. The DMG artifact is attached to a GitHub Release automatically via the release workflow
  3. Opening the app on a clean Mac with no developer tools passes Gatekeeper — no "unidentified developer" warning
  4. On first launch from the DMG, the app copies itself to /Applications without user having to drag it manually
**Plans**: 2/2 complete

### Phase 18: GitHub README
**Goal**: The GitHub repository looks like a product landing page — a stranger visiting it immediately understands what CC-Beeper is and wants to install it
**Depends on**: Phase 17
**Requirements**: GH-01, GH-02, GH-03, GH-04, GH-05
**Success Criteria** (what must be TRUE):
  1. README opens with a hero GIF showing the beeper reacting to a live Claude Code session
  2. A feature grid with icons covers the four pillars: monitoring, voice, permissions, themes
  3. A one-liner install command and a DMG download link are prominently placed above the fold
  4. Screenshots of all 10 shell color themes are displayed in the README
  5. A contributing guide and license section are present at the bottom
**Plans**: 1/1 complete

</details>

### v3.1 Polish & Fixes (In Progress)

**Milestone Goal:** Erase all Claumagotchi traces (laptop-wide + in-repo), fix the broken auto-speak TTS flow, refresh GitHub presence with new cover art and rewritten copy, add a beeper-shaped menu bar icon, and complete a final branding pass (app icon + DMG) once the user provides Figma-exported assets.

- [x] **Phase 19: Cleanup** - Purge all Claumagotchi references from the laptop and the codebase (completed 2026-03-25)
- [x] **Phase 20: Fix Auto-Speak TTS** - Wire summary-hook into hook registration so TTS fires end-to-end (completed 2026-03-25)
- [x] **Phase 21: GitHub & Branding** - Rewrite README with new cover image, update repo metadata, ship beeper menu bar icon (completed 2026-03-26)
- [ ] ~~**Phase 22: Final Branding**~~ - DEFERRED (app icon + DMG branding — user assets not ready, moved to future milestone)

<details>
<summary>✅ v4.0 Offline Voice (Phases 23-26) - SHIPPED 2026-03-27</summary>

**Milestone Goal:** Replace all cloud voice APIs with on-device AI. FluidAudio delivers Parakeet TDT for transcription and Kokoro-82M for TTS — zero API keys, zero internet required, instant response. Apple native voices remain as fallback. All API key infrastructure (Keychain, Groq/OpenAI code paths, Settings key fields) is removed once local models are working.

- [x] **Phase 23: Foundation** - Switch to GPL-3.0 and add FluidAudio SPM dependency (unblocks offline voice) (completed 2026-03-27)
- [x] **Phase 24: Offline STT** - Replace VoiceService transcription with Parakeet TDT; SFSpeech as fallback (completed 2026-03-27)
- [x] **Phase 25: Offline TTS** - Replace TTSService with Kokoro-82M; Apple Ava as fallback (completed 2026-03-27)
- [x] **Phase 26: Cleanup** - Remove all Groq/OpenAI API paths, Keychain storage, and Settings key fields (completed 2026-03-27)

</details>

### v5.0 Polish & Distribution (Planned)

**Milestone Goal:** Fix voice reliability regressions introduced by the offline models (STT injection and TTS delays), rename "Auto-speak" to "VoiceOver" throughout the app, and ship a branded DMG + Homebrew tap so users can install with one command.

- [ ] **Phase 27: STT Reliability** - Diagnose and fix unreliable voice recording → Parakeet transcription → terminal injection
- [ ] **Phase 28: TTS Reliability + Rename** - Fix Kokoro TTS delays and silence; rename "Auto-speak" to "VoiceOver" across all UI and code
- [ ] **Phase 29: Distribution** - Branded DMG background + Homebrew tap at vecartier/tap/cc-beeper

## Phase Details

### Phase 19: Cleanup
**Goal**: Every trace of "Claumagotchi" is gone — from the user's laptop (old .app, Desktop assets, memory files) and from the CC-Beeper codebase (code, comments, configs, scripts)
**Depends on**: Phase 18
**Requirements**: CLN-01, CLN-02
**Success Criteria** (what must be TRUE):
  1. No Claumagotchi .app exists in /Applications, and no Claumagotchi-era PNG assets remain on the Desktop
  2. No entries in ~/.claude/memory/ reference "Claumagotchi" (entries updated or removed)
  3. A grep of the entire CC-Beeper repo returns zero matches for the string "Claumagotchi" (case-insensitive) across all Swift files, Python scripts, configs, and comments
  4. The app still builds and runs correctly after the in-repo cleanup
**Plans**: 2 plans

Plans:
- [x] 19-01: Laptop-wide Claumagotchi purge — remove old .app, Desktop assets, .claude/memory refs
- [x] 19-02: In-repo code purge — sweep all Swift, Python, config, and comment files for remaining "Claumagotchi" strings

### Phase 20: Fix Auto-Speak TTS
**Goal**: When Claude Code finishes a session, the summary-hook fires automatically, and the app speaks the summary aloud — with a graceful fallback if no OpenAI key is set
**Depends on**: Phase 19
**Requirements**: FIX-01, FIX-02
**Success Criteria** (what must be TRUE):
  1. After Claude Code stops, summary-hook.py is invoked automatically — the user hears a spoken summary without pressing anything
  2. The hook fires because HookInstaller now includes summary-hook in its registration list — the fix is verified by inspecting the installed hooks file
  3. With an OpenAI API key set, TTS uses OpenAI voice; without a key, TTS falls back to Apple Ava Premium voice without an error or silence
  4. If Ava Premium is not downloaded, the app falls back to the default system voice rather than crashing or staying silent
**Plans**: 2 plans

Plans:
- [x] 20-01-PLAN.md — Merge summary extraction into cc-beeper-hook.py Stop handler, delete standalone summary-hook.py
- [x] 20-02-PLAN.md — Add Groq TTS provider, provider-based routing, Settings dropdown, fallback hardening

### Phase 21: GitHub & Branding
**Goal**: The GitHub repo and menu bar icon reflect the CC-Beeper identity — the README features the new multi-shell cover image, the copy is exciting and concise, the repo metadata is updated, and the menu bar shows a beeper-shaped silhouette
**Depends on**: Phase 19
**Requirements**: GH2-01, GH2-02, GH2-03, BRD-01
**Success Criteria** (what must be TRUE):
  1. The README hero section displays the new multi-shell cover image (not the old placeholder or Claumagotchi era art)
  2. README copy is rewritten — no mentions of Claumagotchi, language is exciting and concise, a first-time reader immediately understands what CC-Beeper does
  3. The GitHub repository description, topics, and website field are updated to match CC-Beeper branding
  4. The menu bar icon is a beeper-shaped silhouette (not a generic icon), visible and legible in both light and dark menu bars
**Plans**: 2 plans

Plans:
- [x] 21-01: Create beeper-shaped menu bar icon (silhouette asset + wire into app)
- [x] 21-02: Rewrite README with new cover image, refreshed copy, updated metadata; push repo description update

### Phase 22: Final Branding
**Goal**: CC-Beeper has a custom app icon and a branded DMG — completing the visual identity once the user delivers the Figma-exported assets
**Depends on**: Phase 21
**Requirements**: BRD-02, BRD-03
**Success Criteria** (what must be TRUE):
  1. The custom app icon (user-provided Figma export) appears in the Dock, Finder, and the About panel — no generic placeholder icon remains
  2. The DMG window displays the CC-Beeper volume name and background (if asset provided), consistent with the app's visual identity
  3. `make dmg` produces the branded DMG without manual steps
**Plans**: 2 plans

Plans:
- [ ] 22-01: Integrate user-provided app icon into Assets.xcassets at all required resolutions
- [ ] 22-02: Update DMG script with CC-Beeper volume name and optional background image

**Note:** Phase 22 is blocked until the user provides the Figma-exported app icon. BRD-02 is a user-dependency gate; BRD-03 (DMG branding) follows immediately after.

### Phase 23: Foundation
**Goal**: The project is licensed under GPL-3.0 and FluidAudio is integrated as an SPM dependency — the two prerequisites that unlock all offline voice work
**Depends on**: Phase 22 (or can start in parallel — independent of branding state)
**Requirements**: LIC-01, STT-01
**Success Criteria** (what must be TRUE):
  1. The LICENSE file is GPL-3.0, the README license badge reflects GPL-3.0, and no MIT references remain in any project file
  2. FluidAudio is listed as a dependency in Package.swift and the project builds cleanly with it resolved
  3. The Parakeet TDT CoreML model is bundled or fetched at first launch and confirmed present in the app bundle or model cache
**Plans**: 1 plan

Plans:
- [x] 23-01-PLAN.md — Switch license to GPL-3.0, add FluidAudio SPM dependency, verify build

### Phase 24: Offline STT
**Goal**: Voice recording transcribes on-device using Parakeet TDT — no API key, no internet, no Groq dependency
**Depends on**: Phase 23
**Requirements**: STT-02, STT-03
**Success Criteria** (what must be TRUE):
  1. Pressing the voice button records audio and transcribes it using Parakeet TDT without any API key configured
  2. The transcription result is injected into the terminal exactly as it was with the previous Groq Whisper path
  3. If the Parakeet model fails to load, VoiceService falls back to SFSpeechRecognizer and the user sees a clear indication of which engine is active
  4. The Settings > Voice panel shows which STT engine is in use (Parakeet or SFSpeech fallback)
**Plans**: 2 plans

Plans:
- [x] 24-01-PLAN.md — Create ParakeetService actor + wire into VoiceService (replace Groq path, SFSpeech fallback)
- [x] 24-02-PLAN.md — Onboarding model download step + Settings STT engine indicator

### Phase 25: Offline TTS
**Goal**: Auto-speak summaries and all spoken output use Kokoro-82M on-device — no API key, no internet, no Groq/OpenAI dependency
**Depends on**: Phase 23
**Requirements**: TTS-01, TTS-02, TTS-03
**Success Criteria** (what must be TRUE):
  1. When Claude Code finishes, the summary is spoken aloud using Kokoro-82M without any API key configured
  2. The manual "Summarize" button triggers Kokoro TTS and the user hears the summary within a second of pressing it
  3. If the Kokoro model fails to load, TTSService falls back to Apple Ava Premium (or the system default voice) and continues speaking without silence or error
  4. The Settings > Voice panel shows which TTS engine is in use (Kokoro or Apple fallback)
**Plans**: 2 plans

Plans:
- [x] 25-01-PLAN.md — KokoroService actor + TTSService Kokoro integration + ClaudeMonitor migration
- [x] 25-02-PLAN.md — Onboarding dual model download + Settings voice picker

### Phase 26: Cleanup
**Goal**: Every Groq/OpenAI voice code path is gone — no API key fields in Settings or onboarding, no Keychain storage, no dead service classes
**Depends on**: Phase 24, Phase 25
**Requirements**: CLN2-01, CLN2-02, CLN2-03
**Success Criteria** (what must be TRUE):
  1. Settings > Voice contains no API key input fields — only engine selection and fallback controls
  2. Onboarding contains no step or prompt asking for Groq or OpenAI API keys
  3. KeychainService is removed from the codebase and the project builds with zero references to it
  4. GroqTranscriptionService and all Groq/OpenAI TTS routing code are deleted — a grep for "Groq" and "OpenAI" in Swift source returns zero matches
**Plans**: 1 plan

Plans:
- [x] 26-01-PLAN.md — Delete dead Groq/OpenAI/Keychain files, purge all cloud API references from remaining code

### Phase 27: STT Reliability
**Goal**: Pressing the voice button reliably records audio, transcribes with Parakeet TDT, and injects the result into the terminal every single time — no silent failures, no dropped injections
**Depends on**: Phase 26
**Requirements**: FIX2-01, FIX2-02, FIX2-05
**Success Criteria** (what must be TRUE):
  1. Pressing the voice button, speaking, and releasing injects the transcription into the active terminal session on every attempt — no silent drop across 10 consecutive tests
  2. Parakeet TDT transcription completes within a reasonable time (under 5 seconds for a short utterance) — no indefinite hang or timeout with no output
  3. If recording fails to start (e.g., microphone permission revoked), the user sees a visible error state on the beeper rather than silence
  4. If Parakeet fails mid-transcription, VoiceService falls back to SFSpeechRecognizer and the injection still completes
  5. Auto-approved tool calls (e.g., WebFetch on "accept edits" mode) do not trigger "Needs you!" — the beeper stays in THINKING state
**Plans**: 2 plans

Plans:
- [x] 27-01-PLAN.md — Fix VoiceService recording race, terminal focus, injection reliability (6 bugs)
- [ ] 27-02-PLAN.md — Add permission_mode fast-path to hook (false-positive Needs You fix)

### Phase 28: TTS Reliability + Rename
**Goal**: Summaries are spoken reliably via Kokoro TTS every time Claude finishes or the user presses Summarize, and the feature is called "VoiceOver" everywhere in the app
**Depends on**: Phase 26
**Requirements**: FIX2-03, FIX2-04, REN-01, REN-02
**Success Criteria** (what must be TRUE):
  1. When Claude Code finishes a session, Kokoro TTS speaks the summary without delay or silence — verified across 5 consecutive stop events
  2. Pressing the manual Summarize button triggers Kokoro TTS and the user hears audio within 2 seconds — no intermittent silence
  3. Every user-visible label that previously read "Auto-speak" now reads "VoiceOver" — checked in the menu bar popover, Settings, and all onboarding text
  4. IPC field names and hook event terminology updated to "VoiceOver" — a grep for "auto.speak" (case-insensitive, with or without hyphen) in Swift and Python source returns zero matches
**Plans**: TBD
**UI hint**: yes

### Phase 29: Distribution
**Goal**: CC-Beeper ships with a polished branded DMG and is installable via a single Homebrew command — no manual drag, no terminal gymnastics
**Depends on**: Phase 26
**Requirements**: DIST2-01, DIST2-02, DIST2-03
**Success Criteria** (what must be TRUE):
  1. Opening the DMG shows a CC-Beeper branded background and the volume is named "CC-Beeper" (not "Untitled" or a generic name)
  2. Running `make dmg` on a clean checkout produces the branded DMG without any manual intervention — no extra scripts or assets to locate
  3. Running `brew install vecartier/tap/cc-beeper` on a Mac without the app downloads and installs the latest release
  4. The Homebrew tap formula references the correct GitHub release asset and passes `brew audit` with no errors
**Plans**: TBD


## Progress

**Execution Order (v3.1):** 19 -> 20 (can parallel with 21) -> 21 -> 22

**Execution Order (v4.0):** 23 (LIC-01 + STT-01 together) -> 24 + 25 (can run in parallel) -> 26

Note (v4.0): Phase 24 (Offline STT) and Phase 25 (Offline TTS) both depend only on Phase 23 and can execute in parallel. Phase 26 (Cleanup) waits for both Phase 24 and Phase 25 to be complete — API paths must not be removed until local replacements are verified working.

**Execution Order (v5.0):** 27 + 28 (can run in parallel, both depend only on Phase 26) -> 29

Note (v5.0): Phase 27 (STT Reliability) and Phase 28 (TTS Reliability + Rename) both depend only on Phase 26 and touch independent subsystems (VoiceService/ParakeetService vs. TTSService/KokoroService). They can execute in parallel. Phase 29 (Distribution) is fully independent of voice work and can start any time after Phase 26.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 9. UI + Controls | v2.0 Voice Loop | 3/3 | Complete | 2026-03-22 |
| 10. Voice Input + Injection | v2.0 Voice Loop | 1/1 | Complete | 2026-03-22 |
| 11. Auto-Speak + Summary Hook | v2.0 Voice Loop | 2/2 | Complete | 2026-03-22 |
| 12. Code Quality | v3.0 Public Launch | 2/2 | Complete | 2026-03-24 |
| 13. Onboarding | v3.0 Public Launch | 4/4 | Complete | 2026-03-24 |
| 14. Menu Bar Popover | v3.0 Public Launch | 2/2 | Complete | 2026-03-24 |
| 15. Voice Fixes | v3.0 Public Launch | 2/2 | Complete | 2026-03-25 |
| 16. Visual Polish | v3.0 Public Launch | 3/3 | Complete | 2026-03-25 |
| 17. Distribution | v3.0 Public Launch | 2/2 | Complete | 2026-03-25 |
| 18. GitHub README | v3.0 Public Launch | 1/1 | Complete | 2026-03-25 |
| 19. Cleanup | v3.1 Polish & Fixes | 2/2 | Complete | 2026-03-25 |
| 20. Fix Auto-Speak TTS | v3.1 Polish & Fixes | 2/2 | Complete | 2026-03-25 |
| 21. GitHub & Branding | v3.1 Polish & Fixes | 2/2 | Complete | 2026-03-26 |
| 22. Final Branding | v3.1 Polish & Fixes | 0/2 | Not started | - |
| 23. Foundation | v4.0 Offline Voice | 0/1 | Complete | 2026-03-27 |
| 24. Offline STT | v4.0 Offline Voice | 2/2 | Complete | 2026-03-27 |
| 25. Offline TTS | v4.0 Offline Voice | 2/2 | Complete | 2026-03-27 |
| 26. Cleanup | v4.0 Offline Voice | 1/1 | Complete | 2026-03-27 |
| 27. STT Reliability | v5.0 Polish & Distribution | 1/2 | In Progress|  |
| 28. TTS Reliability + Rename | v5.0 Polish & Distribution | 0/TBD | Not started | - |
| 29. Distribution | v5.0 Polish & Distribution | 0/TBD | Not started | - |
