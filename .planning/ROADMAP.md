# Roadmap: Claumagotchi

## Milestones

- ✅ **v1.1 Polish + Hardening** - Phases 1-4 (shipped 2026-03-20)
- ❌ **v2.0 Voice & Intelligence** - Phases 5-8 (reverted 2026-03-21)
- ✅ **v2.0 Voice Loop** - Phases 9-11 (shipped 2026-03-22)
- 🚧 **v3.0 Public Launch** - Phases 12-18 (in progress)

## Overview

v1.1 hardened the foundation. v2.0 Voice Loop added hands-free voice I/O and auto-speak summaries. v3.0 Public Launch makes CC-Beeper ready for strangers: code cleanup removes all hardcoded paths, onboarding guides first-time users through permissions and setup, a rich menu bar popover replaces the old dropdown, voice recording is upgraded to Groq Whisper, visual polish completes the Code Beeper aesthetic, DMG packaging enables one-click distribution, and a landing-style GitHub README drives discovery on HN/Reddit/Twitter.

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

### 🚧 v3.0 Public Launch (In Progress)

**Milestone Goal:** Make CC-Beeper ready for strangers — first-launch onboarding, clean code, rich menu popover, Groq voice, visual polish, DMG distribution, and a landing-style GitHub README for the HN/Reddit/Twitter launch.

- [x] **Phase 12: Code Quality** - Remove hardcoded paths, delete dead assets, fix warnings, extract BuzzService (completed 2026-03-24)
- [ ] **Phase 13: Onboarding** - First-launch wizard guiding users through CLI detection, permissions, hooks, and voice setup
- [ ] **Phase 14: Menu Bar Popover** - Replace dropdown with rich popover panel (toggles, settings, permissions, about)
- [ ] **Phase 15: Voice Fixes** - Upgrade voice recording to Groq Whisper, store API key in Keychain, add manual summary trigger
- [ ] **Phase 16: Visual Polish** - Smooth LCD transitions, dark mode shell variants, consistent button press feedback
- [ ] **Phase 17: Distribution** - DMG packaging, code signing, notarization, auto-install to /Applications
- [ ] **Phase 18: GitHub README** - Landing-style README with hero GIF, feature grid, install command, theme screenshots

## Phase Details

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
**Plans**: 2 plans
Plans:
- [ ] 12-01-PLAN.md — Remove hardcoded paths, delete dead shell assets, fix compiler warnings
- [ ] 12-02-PLAN.md — Extract BuzzService, split multi-type files into one-type-per-file

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
**Plans**: 3 plans
Plans:
- [ ] 13-01-PLAN.md — Create ClaudeDetector, HookInstaller, AppMover services + bundle hook script
- [ ] 13-02-PLAN.md — Build OnboardingViewModel, container view, and all 5 step screens + remove NotificationManager
- [ ] 13-03-PLAN.md — Wire onboarding into app lifecycle, add menu bar Setup entry, verify flow

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
**Plans**: TBD

### Phase 15: Voice Fixes
**Goal**: Voice recording is reliable and uses Groq Whisper; the API key is stored securely; summary playback has a manual trigger
**Depends on**: Phase 12
**Requirements**: VOICE-05, VOICE-06, VOICE-07
**Success Criteria** (what must be TRUE):
  1. Pressing Speak records audio to a WAV file and sends it to Groq Whisper API — not SFSpeechRecognizer
  2. The Groq API key is stored in macOS Keychain and prompted for (with explanation) if not yet set
  3. A "Summarize" button appears when Claude finishes — user can trigger summary on demand, not only automatically
  4. Auto-speak and manual summarize can coexist: auto-speak fires if enabled, manual button always present
**Plans**: TBD

### Phase 16: Visual Polish
**Goal**: The Code Beeper looks and feels finished — smooth LCD transitions, correct dark mode rendering, tactile button feedback
**Depends on**: Phase 14
**Requirements**: VFX-01, VFX-02, VFX-03
**Success Criteria** (what must be TRUE):
  1. LCD content fades smoothly between states (thinking → done → idle) instead of snapping instantly
  2. Dark mode shell variants display correctly with the LCD overlay — no tinting artifacts or misalignment
  3. Every button (Accept, Deny, Speak, Terminal, mute) produces the same press-feedback animation on tap
**Plans**: TBD

### Phase 17: Distribution
**Goal**: Anyone can download and install CC-Beeper in under 60 seconds — no Gatekeeper warnings, no manual drag-to-Applications
**Depends on**: Phase 16
**Requirements**: DIST-01, DIST-02, DIST-03, DIST-04
**Success Criteria** (what must be TRUE):
  1. Running `make dmg` produces a signed DMG with the app icon and an /Applications symlink
  2. The DMG artifact is attached to a GitHub Release automatically via the release workflow
  3. Opening the app on a clean Mac with no developer tools passes Gatekeeper — no "unidentified developer" warning
  4. On first launch from the DMG, the app copies itself to /Applications without user having to drag it manually
**Plans**: TBD

### Phase 18: GitHub README
**Goal**: The GitHub repository looks like a product landing page — a stranger visiting it immediately understands what CC-Beeper is and wants to install it
**Depends on**: Phase 17
**Requirements**: GH-01, GH-02, GH-03, GH-04, GH-05
**Success Criteria** (what must be TRUE):
  1. README opens with a hero GIF showing the beeper reacting to a live Claude Code session
  2. A feature grid with icons covers the four pillars: monitoring, voice, permissions, themes
  3. A one-liner install command and a DMG download link are prominently placed above the fold
  4. Screenshots of all 8 shell color themes are displayed in the README
  5. A contributing guide and license section are present at the bottom
**Plans**: TBD

## Progress

**Execution Order:** 12 → 13 → 14 → 15 (parallel with 13-14) → 16 → 17 → 18

Note: Phase 15 (Voice Fixes) depends only on Phase 12 and can be executed in parallel with Phases 13-14. Phase 16 waits for both 14 and 15 to be complete.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 9. UI + Controls | v2.0 Voice Loop | 3/3 | Complete | 2026-03-22 |
| 10. Voice Input + Injection | v2.0 Voice Loop | 1/1 | Complete | 2026-03-22 |
| 11. Auto-Speak + Summary Hook | v2.0 Voice Loop | 2/2 | Complete | 2026-03-22 |
| 12. Code Quality | 2/2 | Complete    | 2026-03-24 | - |
| 13. Onboarding | 2/4 | In Progress|  | - |
| 14. Menu Bar Popover | v3.0 Public Launch | 0/TBD | Not started | - |
| 15. Voice Fixes | v3.0 Public Launch | 0/TBD | Not started | - |
| 16. Visual Polish | v3.0 Public Launch | 0/TBD | Not started | - |
| 17. Distribution | v3.0 Public Launch | 0/TBD | Not started | - |
| 18. GitHub README | v3.0 Public Launch | 0/TBD | Not started | - |
