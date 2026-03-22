---
phase: 11-auto-speak-summary-hook
plan: 02
subsystem: voice
tags: [swift, avfoundation, tts, file-watcher, dispatch-source, combine, recording]

# Dependency graph
requires:
  - phase: 11-01
    provides: TTSService with speakSummary() and Apple Intelligence summarization
  - phase: 10-voice-input-injection
    provides: VoiceService with recording toggle and audio injection
provides:
  - ClaudeMonitor summary file watcher (DispatchSource on last_summary.txt)
  - Auto-speak end-to-end: file write -> watcher fires -> summarize -> speak
  - Recording priority: TTS cut immediately when recording starts
  - isSpeaking mirrored from TTSService to ClaudeMonitor via Combine
affects: [any UI that displays TTS state, future voice loop phases]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DispatchSource O_EVTONLY file watcher for IPC signal files"
    - "Recording priority: guard !isRecording in both watcher and startRecording()"
    - "Dual TTS cutoff: toggle() checks isSpeaking, startRecording() checks again as safety net"
    - "Combine assign(to:) for mirroring @Published from child service into parent ObservableObject"

key-files:
  created: []
  modified:
    - Sources/ClaudeMonitor.swift
    - Sources/VoiceService.swift

key-decisions:
  - "Tasks 1 and 2 committed together — VoiceService.ttsService property required for Task 1 to compile, making them atomically dependent"
  - "300ms total TTS release time split as: 100ms in stopSpeaking() + 200ms in startRecording() — matches VoiceLoop prototype pattern"
  - "lastSummary only updated after successful speakSummary() call and after re-checking !isRecording — avoids stale UI state"
  - "summarySource cancelled and re-created on isActive toggle — prevents duplicate watchers"

patterns-established:
  - "Summary watcher: setupSummaryWatcher() + onSummaryFileChanged() + DispatchSource on O_EVTONLY fd"
  - "Auto-speak guard: guard autoSpeak, !isRecording at watcher entry + Task re-check after async summarization"

requirements-completed: [VOICE-03, VOICE-04]

# Metrics
duration: 15min
completed: 2026-03-22
---

# Phase 11 Plan 02: Auto-Speak Wiring Summary

**DispatchSource file watcher on last_summary.txt wired into ClaudeMonitor + TTSService, with recording-priority TTS cutoff in VoiceService toggle and startRecording paths**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-22T22:00:00Z
- **Completed:** 2026-03-22T22:15:00Z
- **Tasks:** 2 auto (Tasks 1-2 committed together; Task 3 is checkpoint:human-verify, pending)
- **Files modified:** 2

## Accomplishments
- ClaudeMonitor: TTSService instantiated, summary file watcher established via DispatchSource
- ClaudeMonitor: onSummaryFileChanged() guards autoSpeak + !isRecording, calls speakSummary(), updates lastSummary
- ClaudeMonitor: isSpeaking mirrored from TTSService via Combine (assign(to:))
- ClaudeMonitor: summary watcher starts/stops with isActive toggle; ttsService.stopSpeaking() on deactivation
- VoiceService: ttsService property added; toggle() and startRecording() cut TTS with 300ms total audio release

## Task Commits

Each task was committed atomically:

1. **Task 1: Add summary file watcher and TTSService wiring to ClaudeMonitor** - `424babb` (feat)
2. **Task 2: VoiceService cuts TTS before recording starts** - `424babb` (feat — committed together with Task 1, mutually dependent)
3. **Task 3: Verify auto-speak end-to-end** - CHECKPOINT:HUMAN-VERIFY (pending)

## Files Created/Modified
- `Sources/ClaudeMonitor.swift` - Added: ttsService, isSpeaking, summaryFile, summarySource, lastSummaryHash, setupSummaryWatcher(), onSummaryFileChanged(); wired into init, isActive, deinit
- `Sources/VoiceService.swift` - Added: ttsService property, TTS cutoff in toggle() and startRecording()

## Decisions Made
- Tasks 1 and 2 committed together because VoiceService.ttsService property is referenced in ClaudeMonitor.init() — project won't compile until both changes land
- 300ms total audio release: stopSpeaking() has 100ms usleep, startRecording() adds 200ms — matches VoiceLoop prototype's 300ms total
- Re-check !isRecording after async Task.speakSummary() to handle race where user starts recording during AI summarization

## Deviations from Plan

None - plan executed exactly as written. Tasks 1 and 2 were committed atomically due to cross-file dependency, which is acceptable given they are designed to work together.

## Issues Encountered
- Task 1 alone fails to compile (VoiceService.ttsService doesn't exist yet) — resolved by completing Task 2 before committing, aligning with plan's own note: "Also update ClaudeMonitor.init() to wire ttsService into voiceService"

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Auto-speak code complete and compiling
- Task 3 (human-verify checkpoint) required to confirm end-to-end flow works in the running app
- Once verified: Phase 11 is complete, v2.0 Voice Loop milestone ready

---
*Phase: 11-auto-speak-summary-hook*
*Completed: 2026-03-22*
