---
phase: 26-cleanup
plan: 01
subsystem: cleanup
tags: [swift, swiftui, macos, offline-voice, groq, openai, keychain, tts]

# Dependency graph
requires:
  - phase: 25-offline-tts
    provides: Kokoro TTS fully operational, Groq/OpenAI TTS paths no longer needed
  - phase: 24-offline-stt
    provides: Parakeet STT fully operational, Groq Whisper no longer needed
provides:
  - Zero Groq/OpenAI references in Swift source
  - Zero KeychainService references in Swift source
  - Settings has 3 tabs (Audio, Permissions, About) — Voice tab removed
  - TTSPlaybackDelegate class (renamed from OpenAITTSDelegate)
  - Clean build with zero errors
affects: [packaging, distribution, license]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dead code deletion: use rm directly, FileSystemSynchronizedRootGroup auto-detects"
    - "Class rename pattern: update property type, instantiation, and class declaration atomically"

key-files:
  created: []
  modified:
    - Sources/TTSService.swift
    - Sources/ClaudeMonitor.swift
    - Sources/OnboardingPermissionsStep.swift
    - Sources/SettingsView.swift

key-decisions:
  - "CLN2-03: TTSPlaybackDelegate is the permanent name for AVAudioPlayerDelegate wrapper — no OpenAI naming in codebase"
  - "CLN2-03: Migration block removed — legacy groq/openai UserDefaults values hit the default: branch in TTSService.speak() and fall through to Apple voice safely"
  - "CLN2-01: Settings > Voice tab fully removed — all voice controls live in Settings > Audio (SettingsAudioSection)"
  - "CLN2-02: KeychainService fully deleted — offline-first app has zero API keys to store"

patterns-established:
  - "All TTS playback delegation via TTSPlaybackDelegate (not named after any cloud provider)"

requirements-completed: [CLN2-01, CLN2-02, CLN2-03]

# Metrics
duration: 3min
completed: 2026-03-27
---

# Phase 26 Plan 01: Cleanup Summary

**Eliminated all Groq, OpenAI, and Keychain code: deleted 4 dead files, renamed OpenAITTSDelegate to TTSPlaybackDelegate, removed Settings > Voice tab — zero cloud API references remain, swift build passes cleanly.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-27T12:44:24Z
- **Completed:** 2026-03-27T12:46:27Z
- **Tasks:** 2
- **Files modified:** 4 updated, 4 deleted

## Accomplishments
- Deleted GroqTranscriptionService.swift, KeychainService.swift, SettingsVoiceSection.swift, KeychainServiceTests.swift (322 lines of dead code removed)
- Renamed OpenAITTSDelegate class to TTSPlaybackDelegate with all property and instantiation sites updated
- Removed groq/openai migration block from ClaudeMonitor (legacy UserDefaults now falls through to Apple voice safely)
- Removed "upgrading to Groq Whisper soon" text from onboarding permissions step
- Removed Settings > Voice tab and all SettingsVoiceSection references — Settings now has exactly 3 tabs: Audio, Permissions, About
- `swift build` completes with zero errors after all changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Delete dead service files and tests** - `40969f0` (chore)
2. **Task 2: Update remaining files to remove Groq/OpenAI references and fix Settings tab** - `f22803f` (chore)

**Plan metadata:** (docs commit below)

## Files Created/Modified

**Deleted:**
- `Sources/GroqTranscriptionService.swift` — Groq Whisper API client, replaced by Parakeet TDT
- `Sources/KeychainService.swift` — API key storage, not needed in offline-first app
- `Sources/SettingsVoiceSection.swift` — Groq/OpenAI API key fields UI
- `Tests/CC-BeeperTests/KeychainServiceTests.swift` — tests for deleted service

**Updated:**
- `Sources/TTSService.swift` — renamed OpenAITTSDelegate -> TTSPlaybackDelegate (comment, property type, instantiation, class declaration); updated default: comment
- `Sources/ClaudeMonitor.swift` — removed 4-line groq/openai migration block from init()
- `Sources/OnboardingPermissionsStep.swift` — removed "upgrading to Groq Whisper soon" from speech recognition description
- `Sources/SettingsView.swift` — removed .voice case from SettingsTab enum, removed icon mapping, removed switch branch for SettingsVoiceSection

## Decisions Made
- TTSPlaybackDelegate is the permanent name — no cloud provider branding in class names
- Migration block removed entirely: the `default:` branch in TTSService.speak() safely handles any lingering "groq"/"openai" UserDefaults values by falling through to Apple voice
- Settings > Voice tab removed completely; all useful voice controls (TTS provider picker, Kokoro voice picker, STT engine label) already live in SettingsAudioSection

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Codebase is clean: zero Groq/OpenAI/Keychain references in any Swift source file
- v4.0 Offline Voice milestone cleanup complete — app is fully offline with zero API key infrastructure
- Ready for Phase 26 plan 02 (GPL-3.0 license switch) if planned, or packaging/distribution

## Self-Check: PASSED

- Sources/TTSService.swift: FOUND
- Sources/SettingsView.swift: FOUND
- GroqTranscriptionService.swift: CONFIRMED DELETED
- KeychainService.swift: CONFIRMED DELETED
- Commit 40969f0: FOUND
- Commit f22803f: FOUND

---
*Phase: 26-cleanup*
*Completed: 2026-03-27*
