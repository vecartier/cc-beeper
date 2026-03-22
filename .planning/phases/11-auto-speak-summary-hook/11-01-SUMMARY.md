---
phase: 11-auto-speak-summary-hook
plan: "01"
subsystem: hooks-tts
tags: [tts, apple-intelligence, summary-hook, avfoundation, swift6]
dependency_graph:
  requires: []
  provides: [summary-hook, TTSService]
  affects: [ClaudeMonitor]
tech_stack:
  added: [FoundationModels, AVFoundation]
  patterns: [MainActor-isolated ObservableObject, LanguageModelSession, AVSpeechSynthesizer]
key_files:
  created:
    - hooks/summary-hook.py
    - Sources/TTSService.swift
  modified:
    - Package.swift
    - Sources/ClaudeMonitor.swift
    - Sources/VoiceService.swift
    - Sources/ClaumagotchiApp.swift
    - ~/.claude/settings.json (outside repo)
decisions:
  - Marked ClaudeMonitor and VoiceService @MainActor instead of @unchecked Sendable — Swift 6 idiomatic pattern for ObservableObject
  - Package.swift upgraded to swift-tools-version 6.2 and macOS .v26 for FoundationModels support
  - TTSSpeechDelegate renamed from SpeechDelegate to avoid collision with any future shared types
  - deinit in ClaudeMonitor simplified — idleWork/keyMonitor cleanup already handled in isActive.didSet
metrics:
  duration_seconds: 225
  completed_date: "2026-03-22"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 5
---

# Phase 11 Plan 01: Summary Hook + TTSService Summary

**One-liner:** Python stop-hook writes last assistant text to last_summary.txt; TTSService wraps AVSpeechSynthesizer with Ava Premium voice and Apple Intelligence summarization via LanguageModelSession.

## What Was Built

### Task 1: Summary Hook Script
Copied the validated VoiceLoop `summary-hook.py` verbatim into `hooks/summary-hook.py`. The script:
- Reads hook input JSON from stdin (session_id)
- Finds session JSONL by session_id, falls back to most-recently-modified JSONL
- Walks all lines for the last `type: "assistant"` entry with text content blocks
- Writes extracted text to `~/.claude/claumagotchi/last_summary.txt`
- Exits cleanly on empty/missing input (no crash)

Updated `~/.claude/settings.json` Stop hook to point from VoiceLoop path to Claumagotchi path.

### Task 2: TTSService
Created `Sources/TTSService.swift` — `@MainActor` `ObservableObject`:

- `speakSummary(_ text: String) async -> String` — summarizes (if > 200 chars) then speaks, returns summary
- `stopSpeaking()` — immediate stop with 100ms audio session release delay
- `speak(_ text: String)` — internal, Ava Premium voice, 0.9x rate, 1.05 pitch
- `summarize(_ text: String) async -> String` — Apple Intelligence via `LanguageModelSession` when available; `lastParagraph` fallback otherwise
- `TTSSpeechDelegate` — NSObject, AVSpeechSynthesizerDelegate, `onFinish` on didFinish + didCancel

Upgraded `Package.swift` to `swift-tools-version: 6.2` and `macOS .v26` to enable `FoundationModels` framework.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Swift 6 concurrency errors from macOS version bump**
- **Found during:** Task 2 build verification
- **Issue:** Upgrading from macOS .v14 to .v26 exposed Swift 6 strict concurrency violations in ClaudeMonitor.swift, VoiceService.swift, and ClaumagotchiApp.swift — all `DispatchQueue.main.async { self.X }` patterns flagged as `sending 'self' risks causing data races`
- **Fix:** Marked `ClaudeMonitor` and `VoiceService` as `@MainActor` (Swift 6 idiomatic pattern for ObservableObject). Replaced `DispatchQueue.main.async` with `Task { @MainActor in }` in callback contexts. Fixed `kAXTrustedCheckOptionPrompt` with literal string key to avoid `nonisolated` mutable state error. Simplified deinit (cleanup already handled in `isActive.didSet`).
- **Files modified:** Sources/ClaudeMonitor.swift, Sources/VoiceService.swift, Sources/ClaumagotchiApp.swift
- **Commits:** 6606d6a

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 717067d | feat(11-01): add summary hook script + update settings.json |
| Task 2 | 6606d6a | feat(11-01): add TTSService + upgrade to macOS 26 / swift-tools 6.2 |

## Self-Check: PASSED
