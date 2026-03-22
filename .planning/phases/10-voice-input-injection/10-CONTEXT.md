# Phase 10: Voice Input + Injection - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning
**Source:** VoiceLoop prototype (validated 2026-03-21)

<domain>
## Phase Boundary

Wire real voice recording into Claumagotchi's Speak button. When user presses Speak (or Option+S), record via SFSpeechRecognizer, transcribe on-device, inject into terminal via CGEvent HID, press Enter, and refocus the previous app. User never sees the terminal switch.

</domain>

<decisions>
## Implementation Decisions

### Recording approach
- SFSpeechRecognizer with `requiresOnDeviceRecognition = true`
- `shouldReportPartialResults = true` — accumulate partials, inject latest on stop
- `format: nil` in `installTap` — lets system pick optimal format (handles headphones)
- Recreate AVAudioEngine each session (don't reuse — `reset()` is unreliable)
- Buffer size 4096

### Text injection
- CGEvent with `nil` event source (not `CGEventSource(stateID:)`)
- `keyboardSetUnicodeString` on BOTH keyDown AND keyUp events
- Post via `.cghidEventTap` (not `.cgSessionEventTap`)
- Chunk limit: 200 UTF-16 units. Longer text → clipboard paste fallback (Cmd+V)
- Press Enter (keyCode 0x24) after injection to submit

### Terminal focus + refocus
- Focus terminal via `open -a Terminal` (Process + /usr/bin/open) — most reliable method
- Capture previous app PID before focusing terminal
- After injection + Enter, refocus previous app via `NSRunningApplication(processIdentifier:).activate()`
- Total switch time target: <500ms

### Priority rules
- Record button has absolute priority — immediately stops TTS if speaking
- Incoming summaries never interrupt active recording
- If TTS is playing and user presses Speak: cut TTS → start recording (no delay)

### Error handling
- If audio engine fails to start: log error, don't crash
- If SFSpeechRecognizer returns empty: show "No speech" status, don't inject
- Audio engine corruption from rapid start/stop: recreate engine each time
- Mic permission: request on first use, check before each recording

### Integration with Phase 9
- ClaudeMonitor.isRecording already exists (Phase 9 stub) — wire to real VoiceService
- Option+S hotkey already registered (Phase 9) — wire to toggle recording
- Speak button visual state already works (Phase 9) — icon swap + red + pulse

### Claude's Discretion
- Exact usleep durations for terminal focus/refocus timing
- Whether to show "Recording..." status on screen during capture
- Error recovery UX (retry button vs auto-retry)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Working prototype
- `/Users/vcartier/Desktop/VoiceLoop/Sources/LoopEngine.swift` — Complete working recording + injection code (validated)
- `/Users/vcartier/Desktop/VoiceProto/Sources/Recorder.swift` — Earlier prototype with injection strategies

### Existing code
- `Sources/ClaudeMonitor.swift` — isRecording, Option+S hotkey, goToConversation (terminal list)
- `Sources/ContentView.swift` — Speak button UI (already wired to isRecording toggle)

### Key lessons from prototype
- NSPanel breaks SwiftUI button taps — using regular floating window (already fixed in Phase 9)
- `format: nil` in installTap required for headphone compatibility
- Apple Development signing required for Accessibility persistence
- `sudo killall coreaudiod` recovers corrupted audio — but app should prevent corruption by recreating engine

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClaudeMonitor.isRecording: Bool` — already @Published, drives Speak button UI
- `ClaudeMonitor.goToConversation()` — has terminal bundle ID list, activates terminal
- `handleHotKey` case 9 (Option+S) — already registered, currently just toggles isRecording

### Established Patterns
- ObservableObject + @Published for state changes
- DispatchQueue.main.async for UI updates from callbacks
- try? for silent failure on I/O operations
- @unchecked Sendable for classes with manual thread safety

### Integration Points
- `ClaudeMonitor.isRecording` — replace stub toggle with real VoiceService start/stop
- `handleHotKey` case 9 — call VoiceService.toggle() instead of simple bool toggle
- Speak button action in ContentView — already calls `monitor.isRecording.toggle()`
- Need new `VoiceService.swift` file following codebase convention (PascalCase, final class)

</code_context>

<specifics>
## Specific Ideas

- "I'm in Figma or Google Docs or whatever, I press speak, it sends my message without ever seeing the terminal"
- Toggle mode: tap to start, tap to stop (not hold-to-talk)
- Must work with headphones plugged in
- Recording captures everything from press to stop — pauses in speech don't end recording

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-voice-input-injection*
*Context gathered: 2026-03-22*
