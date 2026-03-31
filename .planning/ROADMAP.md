# Roadmap: CC-Beeper

## Milestones

- ✅ **v1.1 Polish + Hardening** - Phases 1-4 (shipped 2026-03-20)
- ❌ **v2.0 Voice & Intelligence** - Phases 5-8 (reverted 2026-03-21)
- ✅ **v2.0 Voice Loop** - Phases 9-11 (shipped 2026-03-22)
- ✅ **v3.0 Public Launch** - Phases 12-18 (shipped 2026-03-25)
- ✅ **v3.1 Polish & Fixes** - Phases 19-21 (shipped 2026-03-26)
- ✅ **v4.0 Offline Voice** - Phases 23-26 (shipped 2026-03-27)
- ✅ **v5.0 Polish & Distribution** - Phases 27-28 (shipped 2026-03-27)
- ✅ **v6.0 Multilingual Voice** - Phases 30-33 (shipped 2026-03-29)
- ✅ **v7.0 Pre-Launch** - Phases 35-38 (shipped 2026-03-31)
- 🚧 **v1.0 Public Launch** - Phases 39-46 (in progress)

## Overview

v1.1 hardened the foundation. v2.0 Voice Loop added hands-free voice I/O and auto-speak summaries. v3.0 Public Launch made CC-Beeper ready for strangers: code cleanup, onboarding, rich menu popover, Groq voice, visual polish, DMG distribution, and a landing-style GitHub README. v3.1 Polish & Fixes erases all Claumagotchi traces (laptop-wide and in-repo), fixes the broken auto-speak TTS flow, refreshes the GitHub presence with new cover art and rewritten copy, and adds a beeper-shaped menu bar icon. v4.0 Offline Voice replaces all cloud voice APIs with on-device AI: FluidAudio brings Parakeet TDT for transcription and Kokoro-82M for TTS, eliminating every API key dependency. v5.0 Polish & Distribution fixes the two voice reliability regressions introduced by the offline models, renames "Auto-speak" to "VoiceOver" throughout the app, and ships a branded DMG + Homebrew tap. v6.0 Multilingual Voice replaces Parakeet with Whisper for 99-language speech recognition, extends Kokoro to all 9 supported language codes, introduces a unified language preference, and adds language selection to both Settings and onboarding. v7.0 Pre-Launch replaces the fragile Python/JSONL IPC with HTTP hooks, expands the LCD from 4 to 8 states with proper input/permission differentiation, adds a permission mode spectrum with YOLO rabbit, and ships compact + menu-only view modes. v1.0 Public Launch is the first real public release: full functional audit, internal architecture overhaul, security hardening, IDE support, professional distribution, and GitHub release v1.0.

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

### v3.1 Polish & Fixes (Complete)

**Milestone Goal:** Erase all Claumagotchi traces (laptop-wide + in-repo), fix the broken auto-speak TTS flow, refresh GitHub presence with new cover art and rewritten copy, add a beeper-shaped menu bar icon.

- [x] **Phase 19: Cleanup** - Purge all Claumagotchi references from the laptop and the codebase (completed 2026-03-25)
- [x] **Phase 20: Fix Auto-Speak TTS** - Wire summary-hook into hook registration so TTS fires end-to-end (completed 2026-03-25)
- [x] **Phase 21: GitHub & Branding** - Rewrite README with new cover image, refreshed copy, updated metadata (completed 2026-03-26)

<details>
<summary>✅ v4.0 Offline Voice (Phases 23-26) - SHIPPED 2026-03-27</summary>

**Milestone Goal:** Replace all cloud voice APIs with on-device AI. FluidAudio delivers Parakeet TDT for transcription and Kokoro-82M for TTS — zero API keys, zero internet required, instant response. Apple native voices remain as fallback. All API key infrastructure (Keychain, Groq/OpenAI code paths, Settings key fields) is removed once local models are working.

- [x] **Phase 23: Foundation** - Switch to GPL-3.0 and add FluidAudio SPM dependency (unblocks offline voice) (completed 2026-03-27)
- [x] **Phase 24: Offline STT** - Replace VoiceService transcription with Parakeet TDT; SFSpeech as fallback (completed 2026-03-27)
- [x] **Phase 25: Offline TTS** - Replace TTSService with Kokoro-82M; Apple Ava as fallback (completed 2026-03-27)
- [x] **Phase 26: Cleanup** - Remove all Groq/OpenAI API paths, Keychain storage, and Settings key fields (completed 2026-03-27)

</details>

### v5.0 Polish & Distribution (Complete)

**Milestone Goal:** Fix voice reliability regressions introduced by the offline models (STT injection and TTS delays), rename "Auto-speak" to "VoiceOver" throughout the app.

- [x] **Phase 27: STT Reliability** - Diagnose and fix unreliable voice recording → Parakeet transcription → terminal injection (completed 2026-03-27)
- [x] **Phase 28: TTS Reliability + Rename** - Fix Kokoro TTS delays and silence; rename "Auto-speak" to "VoiceOver" across all UI and code (completed 2026-03-27)

<details>
<summary>✅ v6.0 Multilingual Voice (Phases 30-33) - SHIPPED 2026-03-29</summary>

**Milestone Goal:** Support multiple languages for both voice recording (STT) and voice reading (TTS). Whisper replaces Parakeet for 99-language speech recognition with auto-detection. Kokoro is extended to all 9 language codes. A unified language preference drives both subsystems. Language selection is surfaced in Settings and onboarding.

- [x] **Phase 30: Whisper STT** - Replace Parakeet with Whisper; model size picker in Settings; auto-detect spoken language (completed 2026-03-28)
- [x] **Phase 31: Kokoro Multilingual** - Kokoro server supports all 9 language codes; voice picker filters by language; TTS output matches chosen language (completed 2026-03-29)
- [x] **Phase 32: Language Preference System** - Single language preference drives both STT and TTS; defaults to macOS system language; per-language deps downloaded on demand; fallback picker for unsupported languages (completed 2026-03-29)
- [x] **Phase 33: Settings & Onboarding** - Unified Voice tab in Settings; onboarding detects and confirms language; deps downloaded during onboarding; voice preview available (completed 2026-03-29)

</details>

### v7.0 Pre-Launch (Complete)

**Milestone Goal:** Replace the fragile Python/JSONL IPC with HTTP hooks, expand the LCD from 4 to 8 states with proper input/permission differentiation, add a permission mode spectrum with YOLO rabbit, polish onboarding for the HTTP migration path, and overhaul the README for public launch.

- [x] **Phase 35: HTTP Hooks + Hook Improvements** - Replace Python JSONL IPC with NWListener HTTP server; hook commands use curl; all hooks async with timeout (completed 2026-03-29)
- [x] **Phase 36: LCD States + Input Classification + Animations** - 8-state LCD with tool/permission/input context; state priority enforcement; input vs permission differentiation; per-state animations (completed 2026-03-30)
- [x] **Phase 37: Permission Spectrum + YOLO Rabbit** - 4-mode segmented control in popover; atomic settings.json writes; rabbit icon in YOLO modes (completed 2026-03-30)
- [x] **Phase 38: Visibility Spectrum** - 3-mode visibility (Full beeper / Compact screen-only / Menu bar only); 10 small shell PNGs; hotkey-only control in compact+menu modes (completed 2026-03-31)

### 🚧 v1.0 Public Launch (In Progress)

**Milestone Goal:** Full functional audit, internal quality overhaul, security hardening, IDE support, professional distribution, and polish for the first real public release — GitHub release tagged v1.0.

- [ ] **Phase 39: Functional Audit & Bug Fixes** — Verify all 8 LCD states and fix correctness bugs before touching architecture
- [ ] **Phase 40: Fragility Fixes & Constant Consolidation** — Eliminate usleep, silent failures, and scattered hardcoded values
- [ ] **Phase 41: ClaudeMonitor Decomposition & Dead Code** — Extract 4 sub-components and remove dead code that creates noise
- [ ] **Phase 42: Security — HTTP Auth Token** — Add bearer token authentication to the hook server
- [ ] **Phase 43: Protocol DI & Test Coverage** — Define protocols for testable seams and cover the state machine, dispatcher, and permission logic
- [ ] **Phase 44: FocusService + IDE & Tab Focus** — Unified focus routing with tab-level terminal targeting and IDE support
- [ ] **Phase 45: Distribution** — Branded DMG drag-to-install and Homebrew cask on custom tap
- [ ] **Phase 46: Polish & Launch** — Onboarding enhancements, settings cleanup, README finalization, and GitHub release v1.0

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
**Plans**: 2 plans
**UI hint**: yes

Plans:
- [x] 28-01-PLAN.md — Pre-warm PocketTTS, reduce pre-buffer, wire manual summarize toggle
- [x] 28-02-PLAN.md — Rename autoSpeak to voiceOver across all code, UI, UserDefaults, README

### Phase 30: Whisper STT
**Goal**: Voice recording is transcribed by Whisper, supporting 99 languages with automatic language detection — Parakeet is fully replaced
**Depends on**: Phase 29
**Requirements**: STT-01, STT-02, STT-03
**Success Criteria** (what must be TRUE):
  1. Pressing the voice button records audio and transcribes it using Whisper (not Parakeet) — no API key required
  2. The transcription result is injected into the terminal identically to before — no regression in injection behavior
  3. User can select Whisper model size (small or medium) in Settings > Voice > Record, and the selected model is used on next transcription
  4. Speaking in a non-English language (e.g., French) produces a correctly transcribed result in that language without any configuration change
**Plans**: 2 plans

Plans:
- [x] 30-01-PLAN.md — Add WhisperKit SPM dependency, create WhisperService actor, replace Parakeet recording path in VoiceService
- [x] 30-02-PLAN.md — Whisper model picker in Settings, onboarding Whisper download, ClaudeMonitor pre-warm

### Phase 31: Kokoro Multilingual
**Goal**: Kokoro TTS speaks in all 9 supported language codes, and the voice picker in Settings shows only voices valid for the selected language
**Depends on**: Phase 29
**Requirements**: TTS-01, TTS-02, TTS-03
**Success Criteria** (what must be TRUE):
  1. Setting the language to French and triggering TTS plays back in French — the Kokoro server sends the correct lang_code ('f') and the audio is in French
  2. The voice picker in Settings > Voice > Reader filters to only show voices for the currently selected language — no English voices appear when French is selected
  3. All 9 language codes (EN-US, EN-UK, FR, ES, IT, PT, HI, JA, ZH) produce intelligible speech when set as the active language
  4. If the selected language has no available Kokoro voice, TTS falls back gracefully to the system voice with no crash or silence
**Plans**: 2 plans
**UI hint**: yes

Plans:
- [x] 31-01-PLAN.md — Kokoro server LANG: command + KModel sharing + voice catalog + deps installer + TTSService/ClaudeMonitor wiring
- [x] 31-02-PLAN.md — Settings language picker + filtered voice list + dep install UI + human verification

### Phase 32: Language Preference System
**Goal**: A single language preference setting drives both Whisper transcription and Kokoro TTS, defaults to the macOS system language, and triggers language-specific dependency downloads only when needed
**Depends on**: Phase 30, Phase 31
**Requirements**: LANG-01, LANG-02, LANG-03, LANG-04
**Success Criteria** (what must be TRUE):
  1. Changing the language preference in Settings updates both the Kokoro lang_code and the Whisper language hint in a single action — no separate STT and TTS language controls
  2. On first launch, the language preference is automatically set to match the macOS system language (e.g., French macOS → French preference)
  3. Selecting Japanese or Chinese triggers a one-time download of the required language dependencies (pyopenjtalk, ordered_set); selecting English or French does not
  4. On a macOS configured to an unsupported language, Settings or onboarding presents only the supported language options — no unsupported language appears in the picker
**Plans**: 2 plans

Plans:
- [x] 32-01-PLAN.md — Core wiring: language mappings, WhisperService hint, VoiceService propagation, ClaudeMonitor first-launch detection + dep flag
- [x] 32-02-PLAN.md — Human verification of unified language preference system (all 4 LANG requirements)

### Phase 33: Settings & Onboarding
**Goal**: Settings has a unified Voice tab with Language, Reader, and Record sections, and onboarding guides new users through language detection, confirmation, and dependency download
**Depends on**: Phase 32
**Requirements**: UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. Settings > Voice is a single tab containing three labeled sections — Language (picker), Reader (voice + preview), and Record (Whisper model size) — with no separate "Voice Record" or "Voice Reader" tabs
  2. On first launch, the onboarding flow presents the detected macOS language and asks the user to confirm or change it before proceeding
  3. After the user confirms their language in onboarding, any required language-specific dependencies download automatically before the done screen
  4. User can tap a preview button in both onboarding and Settings > Voice > Reader to hear the selected voice speak a sample phrase in the chosen language
**Plans**: TBD
**UI hint**: yes

---

### Phase 35: HTTP Hooks + Hook Improvements
**Goal**: CC-Beeper receives Claude Code events over HTTP instead of file-based JSONL — the Python hook script, JSONL watcher, and all file-IPC code are gone; hooks in settings.json use curl and are async with timeout
**Depends on**: Phase 33
**Requirements**: HTTP-01, HTTP-02, HTTP-03, HTTP-04, HTTP-05, HTTP-06, HOOK-01, HOOK-02, HOOK-03, HOOK-04
**Success Criteria** (what must be TRUE):
  1. Running a Claude Code session sends events to CC-Beeper via HTTP POST — the app receives PreToolUse, Stop, StopFailure, and Notification events without any JSONL file involved
  2. CC-Beeper writes its port to ~/.claude/cc-beeper/port on startup and the file is deleted when the app quits
  3. On launch, if a port file already exists, CC-Beeper pings the port — if another instance responds, it shows "Already running" and quits; if stale, it deletes the file and proceeds
  4. When Claude Code finishes, CC-Beeper extracts last_assistant_message from the Stop payload and speaks the TTS summary — no transcript file parsing or Python extraction involved
  5. A grep for cc-beeper-hook.py and events.jsonl in the Swift codebase returns zero matches — file-IPC code is fully removed
  6. Inspecting ~/.claude/settings.json shows CC-Beeper hooks with async: true, timeout: 5 (seconds), zero stdout output, and curl piping stdin JSON to the HTTP endpoint
**Plans**: 3 plans

Plans:
- [x] 35-01-PLAN.md — HTTP server (NWListener) + port file lifecycle + port-based instance detection
- [x] 35-02-PLAN.md — Wire HTTP to state machine + TTS from Stop + remove all file-based IPC + delete Python hook
- [ ] 35-03-PLAN.md — Rewrite HookInstaller for curl hooks + async/timeout/statusMessage/zero-stdout

### Phase 36: LCD States + Input Classification + Animations
**Goal**: The beeper LCD displays 7 distinct states with tool/permission/input context and per-state animations, enforces state priority so urgent states aren't overwritten, and correctly distinguishes input prompts from permission requests
**Depends on**: Phase 35
**Requirements**: LCD-01, LCD-02, LCD-03, LCD-04, LCD-05, LCD-06, LCD-07, INP-01, INP-02, INP-03, ANIM-01, ANIM-02
**Success Criteria** (what must be TRUE):
  1. Starting a Claude Code session cycles through IDLE → THINKING → WORKING (with tool name shown) → DONE and back to IDLE — all 7 states are reachable and display correct title text
  2. When Claude requests a permission, the LCD shows APPROVE? with the permission context truncated to 30 chars; when Claude asks a question, it shows NEEDS INPUT — never mixing the two
  3. In Guarded YOLO or Full YOLO mode, permission notifications are silently suppressed on the LCD, but input questions (GSD discuss, multiple choice, WCV, free-form) always surface as NEEDS INPUT
  4. A DONE state auto-transitions back to IDLE after 3 seconds without user interaction
  5. Triggering a low-priority event (e.g., THINKING) while in APPROVE? state does not overwrite APPROVE? — state priority is enforced
  6. Each state has a distinct animation: IDLE is static, THINKING pulses slowly, WORKING scrolls, APPROVE? blinks fast, NEEDS INPUT blinks slowly, ERROR flashes then holds, DONE flashes then fades — LCD color stays consistent with theme
  7. APPROVE? and NEEDS INPUT are distinguishable at a glance by different blink speeds and text
**Plans**: 2 plans

Plans:
- [ ] 36-01-PLAN.md — State machine expansion (4->6 states), priority enforcement, notification classification, YOLO suppression, tests
- [ ] 36-02-PLAN.md — LCD text/sprites/animations: per-state title/detail, 24 sprite frames, blink/pulse/glitch effects, auth flash

**UI hint**: yes
**Notes**: Phase 36 needs a lightweight `readPermissionMode()` utility to check current mode from settings.json for YOLO suppression logic. This is a read-only dependency — Phase 37 builds the write path + UI. Input classification must explicitly enumerate known input types (question, gsd, discuss, multiple_choice, wcv) and default unknown types to input (false positives over false negatives).

### Phase 37: Permission Spectrum + YOLO Rabbit
**Goal**: Users can select from 4 permission presets in the native MenuBarExtra menu; the beeper shows a rabbit pixel character in YOLO mode; settings.json is written atomically without reformatting
**Depends on**: Phase 35
**Requirements**: PERM-01, PERM-02, PERM-03, PERM-04, PERM-05, PERM-06, YOLO-01, YOLO-02
**Success Criteria** (what must be TRUE):
  1. The native MenuBarExtra menu contains 4 permission presets (Cautious, Relaxed, Trusted, YOLO) with inline descriptions and a checkmark on the current mode
  2. Selecting a preset writes permission_mode and allowedTools to settings.json atomically without reformatting other fields
  3. Switching to YOLO causes the beeper pixel character to become a rabbit; switching back swaps to the normal character (simple swap, no animation)
  4. If settings.json is malformed, the preset picker is visibly disabled with a warning
  5. On any mode change, the LCD shows "RESTART SESSION TO APPLY" as a toast overlay for 5 seconds
  6. The old YOLO toggle in MenuBarExtra and YOLO QuickActionButton in the popover are removed
**Plans**: 2 plans
**UI hint**: yes

Plans:
- [x] 37-01-PLAN.md — PermissionPreset enum, PermissionPresetWriter, HookInstaller prettyPrinted fix, AskUserQuestion bug fix, rabbit sprite, tests
- [x] 37-02-PLAN.md — MenuBarExtra inline picker, toast overlay, rabbit rendering, autoAccept removal, human verify

### Phase 38: Visibility Spectrum
**Goal**: Users choose between three visibility modes — Full (large beeper with all buttons), Compact (small shell with LCD only, hotkey control), and Menu (no widget, menu bar icon only) — with clean window transitions and hotkeys working in all modes
**Depends on**: Phase 37
**Requirements**: D-01, D-02, D-03, D-04, D-05, D-06, D-07, D-08, D-09, D-10, TTS-FIX, PERM-BUG
**Success Criteria** (what must be TRUE):
  1. Selecting "Compact" in the Size menu shows the small shell with LCD content (character, title, subtitle) — no buttons, LEDs, or speaker grille visible
  2. Selecting "Menu only" hides the widget window entirely — the menu bar icon remains and all hotkeys still work
  3. Selecting "Large" restores the full beeper with all buttons and controls
  4. Switching between Full and Compact resizes the window smoothly, anchored to the top-left corner — no jarring jumps or off-screen positioning
  5. All 10 small shell PNG colors match the existing large shell color set and the current theme selection
  6. When a PreToolUse event arrives while TTS is speaking, TTS stops immediately and the state transitions to working
  7. Accept/deny buttons successfully send HTTP responses for both Notification-based and PermissionRequest-based permission prompts
**Plans**: 2 plans
**UI hint**: yes

Plans:
- [ ] 38-01-PLAN.md — Copy 10 small shell PNGs, add ThemeManager.smallShellImageName, fix TTS interrupt on PreToolUse, fix HTTP permission connection for PermissionRequest
- [ ] 38-02-PLAN.md — Create CompactView, wire 3-mode view routing in CCBeeperApp, add window resize with top-left anchoring, human visual verification

---

### Phase 39: Functional Audit & Bug Fixes
**Goal**: All 8 LCD states trigger correctly from real Claude Code hook events and concurrent session priority resolves accurately — the state machine is verified correct before any structural changes
**Depends on**: Nothing (first phase of v1.0 — establishes correctness baseline before architecture work begins)
**Requirements**: AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04, AUDIT-05, AUDIT-06, AUDIT-07, AUDIT-08
**Success Criteria** (what must be TRUE):
  1. Sending a PreToolUse hook fires WORKING state, Stop fires DONE, StopFailure fires ERROR — no wrong-state display across all 8 states
  2. When two Claude sessions run simultaneously, the higher-priority state wins on the LCD and the lower-priority state is preserved until resolved
  3. The "Stewing/thinking" state from Claude Code displays as WORKING, not SNOOZING
  4. Two simultaneous permission requests from different sessions both appear in the pending queue without one overwriting the other
  5. A Kokoro subprocess crash triggers automatic fallback to Apple TTS and the next TTS request restarts the Kokoro process
**Plans**: 3 plans

Plans:
- [ ] 39-01-PLAN.md — State machine audit: register UserPromptSubmit hook, fix idle_prompt, extend 8-state tests
- [ ] 39-02-PLAN.md — Permission concurrency: replace single-slot with FIFO array, orphan cleanup, session-aware routing
- [ ] 39-03-PLAN.md — TTS crash recovery + voice injection safety: terminationHandler, restart logic, changeCount guard, frontmost app check

### Phase 40: Fragility Fixes & Constant Consolidation
**Goal**: All timing-sensitive code is event-driven, every silent failure surfaces a visible error, and every hardcoded value has exactly one canonical definition
**Depends on**: Phase 39 (audit confirms what is broken before replacing fragile patterns)
**Requirements**: FRAG-01, FRAG-02, FRAG-03, FRAG-04, FRAG-05, FRAG-06, FRAG-07, FRAG-08, FRAG-09
**Success Criteria** (what must be TRUE):
  1. Option-T triggers terminal focus without any usleep delay — activation waits for NSWorkspace.didActivateApplicationNotification
  2. Clipboard paste succeeds even when the user modifies clipboard contents between copy and paste (changeCount comparison prevents overwrite)
  3. A port file write failure, NWListener startup failure, or AppMover copy failure each produce a visible error (LCD error state or alert) instead of silently passing
  4. Terminal bundle IDs, LCD color hex values, and the Kokoro venv path each appear in exactly one place in the codebase
**Plans**: TBD

### Phase 41: ClaudeMonitor Decomposition & Dead Code
**Goal**: ClaudeMonitor is a thin orchestrator under 250 lines, four focused sub-components exist as separate files, and all dead code is removed
**Depends on**: Phase 40 (constants consolidated and fragility fixed before components are extracted to new files)
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04, ARCH-05, ARCH-06, ARCH-07, ARCH-08, ARCH-09
**Success Criteria** (what must be TRUE):
  1. SessionTracker, HookDispatcher, PermissionController, and HotkeyManager each exist as separate Swift files under Sources/Monitor/
  2. ClaudeMonitor.swift is under 250 lines and contains no state management logic, payload parsing, or hotkey registration
  3. PocketTTSService, the legacy cc-beeper-hook.py script, VoiceService.injectTextOnly, and all stale UserDefaults migration blocks are absent from the project
  4. The app builds with zero warnings and passes a full permission-flow smoke test (hook fires → LCD shows ALLOW? → user clicks approve → Claude Code receives response)
**Plans**: TBD

### Phase 42: Security — HTTP Auth Token
**Goal**: The CC-Beeper hook server rejects any request that does not carry the correct bearer token — unauthenticated curl calls from other processes are refused with a 401
**Depends on**: Phase 41 (HTTPHookServer interface is finalized during decomposition before the auth layer is added on top)
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04
**Success Criteria** (what must be TRUE):
  1. A raw curl POST to the hook endpoint without an Authorization header returns HTTP 401 and no state change occurs in the app
  2. The bearer token file exists at ~/.claude/cc-beeper/token with 0o600 permissions after first launch and is not world-readable
  3. Hook commands installed by HookInstaller include the Authorization: Bearer header and hook events continue to fire correctly end-to-end
**Plans**: TBD

### Phase 43: Protocol DI & Test Coverage
**Goal**: Core systems have protocol-based seams that enable injection in tests, and the state machine, hook dispatcher, and permission logic each have passing unit tests
**Depends on**: Phase 41 (extracted components must exist before protocols are defined for them and tests are written against them)
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05
**Success Criteria** (what must be TRUE):
  1. VoiceService, TTSService, and HTTPHookServer each have a corresponding Swift protocol used at their injection sites
  2. All 8 LCD states and the priority-resolution logic pass unit tests — no state can be triggered by the wrong input or overwritten by a lower-priority state
  3. All 6 hook event types route to the correct handler in HookDispatcher unit tests
  4. All 4 permission presets produce the expected auto-approve, auto-deny, or ask behavior in PermissionController unit tests
  5. A synthesized HTTP POST in a test harness produces the correct LCD state update, verifying the hook-to-LCD integration path end-to-end
**Plans**: TBD

### Phase 44: FocusService + IDE & Tab Focus
**Goal**: Option-T focuses the exact terminal tab containing the active Claude session, falls back gracefully when tab targeting is unavailable, and works when Claude Code runs inside a VS Code, Cursor, Zed, JetBrains, or Ghostty IDE
**Depends on**: Phase 41 (FocusService consolidates duplicated focus logic from VoiceService and ClaudeMonitor; those components must be extracted first)
**Requirements**: IDE-01, IDE-02, IDE-03, IDE-04, IDE-05, TAB-01, TAB-02, TAB-03, TAB-04
**Success Criteria** (what must be TRUE):
  1. Option-T in iTerm2 raises the exact tab running the Claude session matched by session PID via AppleScript — not just the iTerm2 window
  2. Option-T in Terminal.app raises the exact tab running the Claude session via AppleScript
  3. Option-T in Ghostty focuses the correct tab by matching the working directory of the Claude process
  4. When tab targeting is not possible (unsupported terminal or AppleScript failure), Option-T falls back to app-level activation with no error thrown
  5. Option-T when Claude Code runs in VS Code, Cursor, Zed, or a JetBrains IDE focuses the correct IDE application
  6. Voice recording injection works when an IDE terminal panel is focused — the IDE is activated, the terminal panel shortcut is sent, and text is injected
**Plans**: TBD
**UI hint**: yes

### Phase 45: Distribution
**Goal**: Users can install CC-Beeper with a single Homebrew command or by downloading a professional drag-to-install DMG from GitHub Releases
**Depends on**: Phase 39 (app must be functional and audited before packaging for public distribution)
**Requirements**: DIST-01, DIST-02, DIST-03, DIST-04
**Success Criteria** (what must be TRUE):
  1. The DMG mounts to show a branded background with the CC-Beeper app icon and an Applications folder alias positioned correctly for drag-to-install
  2. Running `brew install --cask cc-beeper` on a clean machine downloads and installs CC-Beeper from the GitHub Releases DMG without errors
**Plans**: TBD

### Phase 46: Polish & Launch
**Goal**: Onboarding introduces new users to personalization options, the Settings window is clean, the README and GitHub repo are launch-ready, and v1.0 is tagged
**Depends on**: Phase 45 (distribution must be ready before tagging the release), Phase 44 (IDE support must be complete for the README to document it accurately)
**Requirements**: POLISH-01, POLISH-02, POLISH-03, POLISH-04, POLISH-05, POLISH-06, POLISH-07, POLISH-08
**Success Criteria** (what must be TRUE):
  1. A new user completing onboarding has selected a beeper color/theme, a widget size, and a permission preset before reaching the Done screen
  2. Onboarding transitions are smooth and visuals are consistent — no layout jumps, mismatched button styles, or stale copy from prior milestones
  3. The Settings window tabs are clean — no options for removed features, no duplicate labels, no references to PocketTTS or legacy Python hook
  4. The GitHub README includes a hero GIF, feature screenshots, and copy-pasteable install instructions covering both Homebrew and DMG paths
  5. The GitHub repository has no stale files, an accurate description, and a published v1.0 release tag with a changelog
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order (v3.1):** 19 -> 20 (can parallel with 21) -> 21 -> 22

**Execution Order (v4.0):** 23 (LIC-01 + STT-01 together) -> 24 + 25 (can run in parallel) -> 26

Note (v4.0): Phase 24 (Offline STT) and Phase 25 (Offline TTS) both depend only on Phase 23 and can execute in parallel. Phase 26 (Cleanup) waits for both Phase 24 and Phase 25 to be complete — API paths must not be removed until local replacements are verified working.

**Execution Order (v5.0):** 27 + 28 (can run in parallel, both depend only on Phase 26) -> 29

Note (v5.0): Phase 27 (STT Reliability) and Phase 28 (TTS Reliability + Rename) both depend only on Phase 26 and touch independent subsystems (VoiceService/ParakeetService vs. TTSService/KokoroService). They can execute in parallel. Phase 29 (Distribution) is fully independent of voice work and can start any time after Phase 26.

**Execution Order (v6.0):** 30 + 31 (can run in parallel, both depend only on Phase 29) -> 32 -> 33

Note (v6.0): Phase 30 (Whisper STT) and Phase 31 (Kokoro Multilingual) both depend only on Phase 29 and touch independent subsystems. They can execute in parallel. Phase 32 (Language Preference System) depends on both 30 and 31 being complete — the unified language preference requires both engines to be multilingual. Phase 33 (Settings & Onboarding) depends on Phase 32, as it surfaces the language system in UI.

**Execution Order (v7.0):** 35 -> 36 + 37 (can run in parallel) -> 38

Note (v7.0): Phase 35 (HTTP Hooks) is the foundation — LCD states and onboarding both depend on its HTTP payload routing. Phase 36 (LCD States + Input Classification + Animations) and Phase 37 (Permission Spectrum + YOLO Rabbit) both depend only on Phase 35 and touch independent subsystems — they can execute in parallel. Phase 38 (Visibility Spectrum) depends on Phase 37 for the permission rendering integration.

**Execution Order (v1.0):** 39 -> 40 -> 41 -> 42 -> 43 -> 44 -> 45 -> 46

Note (v1.0): All phases are sequentially dependent. Phase 39 (Functional Audit) must run first — decomposing broken code makes bugs untraceable. Phase 40 (Fragility + Constants) consolidates scattered values before extraction moves them into new files. Phase 41 (Decomposition + Dead Code) creates the clean component boundaries that Phase 42 (Security), Phase 43 (Tests), and Phase 44 (FocusService) all depend on. Phase 45 (Distribution) requires a functionally audited app. Phase 46 (Polish + Launch) is last — it documents and tags a complete product.

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
| 23. Foundation | v4.0 Offline Voice | 0/1 | Complete | 2026-03-27 |
| 24. Offline STT | v4.0 Offline Voice | 2/2 | Complete | 2026-03-27 |
| 25. Offline TTS | v4.0 Offline Voice | 2/2 | Complete | 2026-03-27 |
| 26. Cleanup | v4.0 Offline Voice | 1/1 | Complete | 2026-03-27 |
| 27. STT Reliability | v5.0 Polish & Distribution | 2/2 | Complete | 2026-03-27 |
| 28. TTS Reliability + Rename | v5.0 Polish & Distribution | 2/2 | Complete | 2026-03-27 |
| 30. Whisper STT | v6.0 Multilingual Voice | 2/2 | Complete | 2026-03-28 |
| 31. Kokoro Multilingual | v6.0 Multilingual Voice | 2/2 | Complete | 2026-03-29 |
| 32. Language Preference System | v6.0 Multilingual Voice | 2/2 | Complete | 2026-03-29 |
| 33. Settings & Onboarding | v6.0 Multilingual Voice | 0/TBD | Not started | - |
| 35. HTTP Hooks + Hook Improvements | v7.0 Pre-Launch | 2/3 | Complete | 2026-03-29 |
| 36. LCD States + Input Classification + Animations | v7.0 Pre-Launch | 0/TBD | Not started | - |
| 37. Permission Spectrum + YOLO Rabbit | v7.0 Pre-Launch | 2/2 | Complete | 2026-03-30 |
| 38. Visibility Spectrum | v7.0 Pre-Launch | 0/2 | Complete | 2026-03-31 |
| 39. Functional Audit & Bug Fixes | v1.0 Public Launch | 0/3 | In progress | - |
| 40. Fragility Fixes & Constant Consolidation | v1.0 Public Launch | 0/TBD | Not started | - |
| 41. ClaudeMonitor Decomposition & Dead Code | v1.0 Public Launch | 0/TBD | Not started | - |
| 42. Security — HTTP Auth Token | v1.0 Public Launch | 0/TBD | Not started | - |
| 43. Protocol DI & Test Coverage | v1.0 Public Launch | 0/TBD | Not started | - |
| 44. FocusService + IDE & Tab Focus | v1.0 Public Launch | 0/TBD | Not started | - |
| 45. Distribution | v1.0 Public Launch | 0/TBD | Not started | - |
| 46. Polish & Launch | v1.0 Public Launch | 0/TBD | Not started | - |
