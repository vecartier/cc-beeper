---
phase: 27-stt-reliability
plan: 01
subsystem: voice
tags: [swift, avfoundation, cgevent, parakeet, stt, terminal-injection, appkit]

# Dependency graph
requires:
  - phase: 24-offline-stt
    provides: ParakeetService with streaming callbacks and finish() method
  - phase: 25-offline-tts
    provides: KokoroService replacing Groq TTS
  - phase: 26-cleanup
    provides: Clean codebase with zero Groq/OpenAI references
provides:
  - VoiceService with all six reliability bugs fixed
  - Synchronous isRecording state before async recording setup
  - NSRunningApplication.activate() terminal focus (synchronous, no sleep)
  - Ctrl+U terminal input clearing (readline kill-line, universal shell support)
  - finish() completes before engine replacement in Parakeet manual stop
  - @Published recordingError for visible error state on mic failure
affects:
  - 27-stt-reliability-02 (hook permission mode fix)
  - Any phase that touches VoiceService

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Set published state synchronously before entering async Task to prevent rapid double-press races
    - Terminal focus acquired once at session start via NSRunningApplication.activate(), not per-inject
    - Engine replaced only AFTER finish() completes to avoid orphaned transcript data

key-files:
  created: []
  modified:
    - Sources/VoiceService.swift

key-decisions:
  - "isRecording set synchronously before async Task in startRecording() — prevents double-press race at source"
  - "focusTerminal() called once at Parakeet session start, not on every partial callback"
  - "NSRunningApplication.activate() replaces open -a Process — synchronous activation, no sleep needed"
  - "clearTerminalInput() uses Ctrl+U (kVK_ANSI_U + maskControl) — readline kill-line, universal across bash/zsh/fish"
  - "finish() awaited before audioEngine = AVAudioEngine() in manual stop — engine replaced only after finalization"
  - "stopRecordingEngine() deleted — each stop path does inline cleanup with correct ordering"

patterns-established:
  - "VoiceService state mutation pattern: set @Published booleans synchronously before async Task blocks"
  - "Terminal focus pattern: acquire once at session start, not per injection call"

requirements-completed: [FIX2-01, FIX2-02]

# Metrics
duration: 4min
completed: 2026-03-27
---

# Phase 27 Plan 01: STT Reliability Summary

**Six VoiceService reliability bugs fixed — synchronous recording state, synchronous terminal focus, Ctrl+U clear, and finish()-before-engine-replacement for reliable Parakeet transcription injection**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-27T15:48:34Z
- **Completed:** 2026-03-27T15:52:53Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Fixed isRecording race condition: state set synchronously before async Task blocks out rapid double-press double-tap
- Replaced `open -a` Process with `NSRunningApplication.activate()` — synchronous terminal focus, no sleep guessing required
- Fixed clearTerminalInput: Cmd+A + Delete replaced with Ctrl+U (readline kill-line) — actually clears input in all shells
- Removed 500ms usleep from injectTextOnly — moved focusTerminal to session start, no per-partial sleep blocking main thread
- Fixed finish() race: engine replaced only after Parakeet finalization completes, not before
- Added @Published recordingError for visible error state when microphone permission denied

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix recording race condition, terminal focus, and clearTerminalInput** - `1019a30` (fix)
2. **Task 2: Fix finish() race condition and remove usleep from submitTerminal** - `68f9309` (fix)

**Plan metadata:** (docs commit — created after SUMMARY)

## Files Created/Modified

- `Sources/VoiceService.swift` - All six VoiceService reliability bugs fixed

## Decisions Made

- Set `isRecording = true`, `hasSubmitted = false`, and `lastInjectedText = ""` synchronously at top of `startRecording()` before any async work — prevents rapid double-press from installing two taps on the same inputNode
- `focusTerminal()` called once in `startRecordingParakeet()` before tap installation; removed from `injectTextOnly()` and `submitTerminal()` — terminal stays focused during the entire recording session
- `NSRunningApplication.activate(options: [.activateIgnoringOtherApps])` is synchronous — no sleep needed after focus call
- `clearTerminalInput()` now uses Ctrl+U (virtualKey 32 = kVK_ANSI_U, flags = .maskControl) — standard readline kill-line shortcut, works in bash/zsh/fish/all readline shells
- `stopRecordingEngine()` helper deleted — EOU callback does inline cleanup, manual stop path does inline cleanup with correct finish()-first ordering
- `isRecording` stays `true` during `finish()` await to prevent concurrent recording start race

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reduced injectAndSubmit usleep from 500ms to 100ms in Task 1**
- **Found during:** Task 1 (acceptance criteria check — usleep(500_000) count must be 0)
- **Issue:** Task 2 described reducing this to 100ms but Task 1 acceptance criteria required 0 count of usleep(500_000) across whole file
- **Fix:** Applied the 100ms reduction in Task 1 to satisfy Task 1 acceptance criteria without waiting for Task 2
- **Files modified:** Sources/VoiceService.swift
- **Verification:** grep -c "usleep(500_000)" returns 0; build succeeds
- **Committed in:** 1019a30 (Task 1 commit)

**2. [Rule 1 - Bug] Added isRecording = false on SFSpeech early-exit paths**
- **Found during:** Task 1 (implementation review)
- **Issue:** After setting isRecording = true synchronously, SFSpeech auth-denied early returns left isRecording = true with no recording started
- **Fix:** Added `isRecording = false` to all early-return guards in startRecordingSFSpeech() (no recognizer, speech not authorized, mic not authorized)
- **Files modified:** Sources/VoiceService.swift
- **Verification:** Build succeeds; logic verified by code review
- **Committed in:** 1019a30 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered

None — all six bugs identified in Phase 27 research were applied exactly as specified. Build succeeded on first attempt after each task.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- VoiceService reliability fixes complete — ready for plan 27-02 (Python hook permission_mode fast-path fix)
- All six voice recording bugs from the Phase 27 research audit are addressed
- Manual testing required to confirm end-to-end voice injection works (requires microphone + terminal + Parakeet model loaded)

---
*Phase: 27-stt-reliability*
*Completed: 2026-03-27*
