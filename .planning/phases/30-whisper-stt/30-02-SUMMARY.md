---
phase: 30-whisper-stt
plan: 02
subsystem: ui
tags: [whisperkit, settings, onboarding, userdefaults, swiftui]

# Dependency graph
requires:
  - phase: 30-01
    provides: WhisperService actor, WhisperModelSize enum, WhisperKit dependency
provides:
  - whisperModelSize @Published property in ClaudeMonitor with UserDefaults persistence
  - Whisper model size picker (small/medium) in Settings > Voice Reader > Speech Recognition
  - Conditional Download Model button when selected model is not cached
  - ClaudeMonitor pre-warms Whisper at launch using persisted model size
affects: [31-kokoro-multilingual, Settings, Onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@Published var whisperModelSize bound to Settings Picker via $monitor.whisperModelSize"
    - "WhisperService.isModelDownloaded(size:) used in Settings for conditional download button"

key-files:
  created: []
  modified:
    - Sources/Monitor/ClaudeMonitor.swift
    - Sources/Settings/SettingsVoiceOverSection.swift

key-decisions:
  - "whisperModelSize stored as @Published String in ClaudeMonitor (not in WhisperModelSize.selected) for SwiftUI binding compatibility"
  - "Pre-warm reads self.whisperModelSize (not WhisperModelSize.selected) for consistency with Settings binding"

patterns-established:
  - "Model size picker: Picker bound to monitor.whisperModelSize with String tags, conditional download button checks WhisperService.isModelDownloaded"

requirements-completed: [STT-02]

# Metrics
duration: 15min
completed: 2026-03-28
---

# Phase 30 Plan 02: Whisper Model Selection + Settings Wiring Summary

**Whisper model size picker in Settings with UserDefaults persistence and conditional download button; ClaudeMonitor pre-warms selected model at launch**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-28T09:30:00Z
- **Completed:** 2026-03-28T09:45:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `@Published var whisperModelSize: String = "small"` to ClaudeMonitor with UserDefaults persistence and init loading
- Added Whisper model size picker (small/medium) to Settings > Voice Reader > Speech Recognition section
- Conditional "Download Model" button appears when selected model is not cached on disk
- ClaudeMonitor pre-warms WhisperService at launch using the persisted model size (not a static .selected shortcut)
- Zero ParakeetService references remain anywhere in Sources/

## Task Commits

Each task was committed atomically:

1. **Task 1: Add whisperModelSize to ClaudeMonitor, replace Parakeet pre-warm with Whisper** - `6e363d6` (feat)
2. **Task 2: Add Whisper model picker to Settings, update onboarding to download Whisper** - `a3182e7` (feat)

## Files Created/Modified

- `Sources/Monitor/ClaudeMonitor.swift` - Added `@Published var whisperModelSize` with UserDefaults persistence; pre-warm uses `self.whisperModelSize`
- `Sources/Settings/SettingsVoiceOverSection.swift` - Added Whisper model Picker and conditional Download Model button in Speech Recognition section

## Decisions Made

- `whisperModelSize` stored as `@Published String` in ClaudeMonitor rather than relying on `WhisperModelSize.selected` (which reads UserDefaults directly) — enables SwiftUI binding via `$monitor.whisperModelSize` in Settings
- Pre-warm updated to use `WhisperModelSize(rawValue: self.whisperModelSize) ?? .small` for consistency with the published property

## Deviations from Plan

### Cherry-pick Required (Pre-task setup)

The 30-01 work (WhisperService, WhisperModelSize, VoiceService update, OnboardingViewModel update) was not in the current worktree branch. Cherry-picked commits `eb4e07a` and `7c40c9a` from the 30-01 agent's branch before executing this plan's tasks.

- OnboardingViewModel was already updated to use WhisperService.downloadModel by the cherry-pick
- ClaudeMonitor already had Whisper pre-warm (via `.selected`) from the cherry-pick
- Task 1 added the missing `@Published var whisperModelSize` binding layer on top

**Total deviations:** 1 setup (cherry-pick of prerequisite work, not a code deviation)
**Impact on plan:** Plan executed as designed. No scope changes.

## Issues Encountered

None after cherry-picking 30-01 prerequisite commits.

## Next Phase Readiness

- Whisper integration complete: STT engine (30-01), model selection/settings (30-02)
- Phase 31 (Kokoro Multilingual) can proceed independently — same pattern for TTS voice selection
- `detectedLanguage` property in VoiceService (from 30-01) ready for Phase 32 multilingual UI

---
*Phase: 30-whisper-stt*
*Completed: 2026-03-28*

## Self-Check: PASSED

- FOUND: .planning/phases/30-whisper-stt/30-02-SUMMARY.md
- FOUND: Sources/Monitor/ClaudeMonitor.swift (whisperModelSize property added)
- FOUND: Sources/Settings/SettingsVoiceOverSection.swift (Whisper model picker added)
- FOUND commit: 6e363d6 (Task 1)
- FOUND commit: a3182e7 (Task 2)
- Build: PASSED (Build complete! 0 errors)
