# Phase 11: Auto-Speak + Summary Hook - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning
**Source:** VoiceLoop prototype (validated 2026-03-21)

<domain>
## Phase Boundary

When Claude finishes and auto-speak is enabled, the last response is summarized and spoken aloud. A Python hook fires on Claude stop events, extracts the last assistant text from the session JSONL, and writes it to a known file. The app watches that file and speaks when it changes. Completing the hands-free loop.

</domain>

<decisions>
## Implementation Decisions

### Summary Hook (Python)
- Fires on Claude Code `stop` event via `~/.claude/settings.json` hooks
- Reads the most recently modified JSONL in `~/.claude/projects/`
- Walks the JSONL backwards to find the last `type: "assistant"` entry with text content
- Writes the text to `~/.claude/claumagotchi/last_summary.txt`
- Already wired in settings.json (added during VoiceLoop prototype)
- Hook script location: `~/Desktop/VoiceLoop/hooks/summary-hook.py` — needs to be moved to Claumagotchi

### File Watcher
- ClaudeMonitor watches `~/.claude/claumagotchi/last_summary.txt` using DispatchSource (same pattern as events.jsonl watcher)
- Detects changes via hash comparison (avoid re-speaking same content)
- Never fires during active recording (recording has absolute priority)

### Apple Intelligence Summarization
- Use FoundationModels framework (macOS 26+) to summarize long responses
- Short responses (<200 chars) spoken directly, no summarization
- System prompt: extract final conclusion in 1-2 sentences, first person
- Fallback when Apple Intelligence unavailable: speak last paragraph

### TTS
- AVSpeechSynthesizer with Ava Premium voice (`com.apple.voice.premium.en-US.Ava`)
- Fallback to default en-US voice if premium not downloaded
- Rate: 0.9x default, pitch: 1.05
- Pressing Speak (mic) while TTS is playing: immediately cut TTS, start recording
- Auto-speak is off by default, toggled from menu bar (autoSpeak property already exists from Phase 9)

### Screen Content
- DONE state shows the summary text (same text that gets spoken)
- `lastSummary` property already exists on ClaudeMonitor (Phase 9 stub)

### Claude's Discretion
- Exact Apple Intelligence prompt wording refinement
- Whether to show "Summarizing..." on screen while AI processes
- TTS error handling UX

</decisions>

<canonical_refs>
## Canonical References

### Working prototype
- `/Users/vcartier/Desktop/VoiceLoop/Sources/LoopEngine.swift` — File watcher, summarization, TTS code (validated)
- `/Users/vcartier/Desktop/VoiceLoop/hooks/summary-hook.py` — Working hook script

### Existing code
- `Sources/ClaudeMonitor.swift` — lastSummary, autoSpeak properties (Phase 9 stubs), file watcher pattern
- `Sources/ScreenContentView.swift` — DONE state shows lastSummary
- `~/.claude/settings.json` — Hook already registered in Stop section

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClaudeMonitor.lastSummary: String?` — already @Published, drives screen DONE state
- `ClaudeMonitor.autoSpeak: Bool` — already @Published, persisted in UserDefaults
- File watcher pattern in `setupFileWatcher()` — reuse for summary file
- VoiceLoop's `LoopEngine` has complete working TTS + summarization code

### Integration Points
- `ClaudeMonitor` needs: summary file watcher, TTS service, Apple Intelligence summarization
- `onSummaryChanged()` triggers: summarize → speak → update lastSummary
- `VoiceService.toggle()` must cut TTS before recording (already handles this in VoiceLoop)
- Menu bar autoSpeak toggle already exists (Phase 9)

</code_context>

<specifics>
## Specific Ideas

- "Auto-speak is off by default with easy toggle"
- "Recording has absolute priority — incoming summaries never interrupt active recording"
- "If I press speak it interrupts and overrides" — TTS cuts immediately when mic pressed

</specifics>

<deferred>
## Deferred Ideas

- Custom TTS voice selection (QOL-01)
- Better TTS quality (free open source options explored but deferred)

</deferred>

---

*Phase: 11-auto-speak-summary-hook*
*Context gathered: 2026-03-22*
