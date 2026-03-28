---
phase: 30-whisper-stt
plan: "01"
subsystem: voice-stt
tags: [whisper, stt, batch-transcription, multilingual, whisperkit, spm]
dependency_graph:
  requires: []
  provides: [WhisperService, WhisperModelSize, whisper-batch-recording-path]
  affects: [VoiceService, OnboardingViewModel, ClaudeMonitor]
tech_stack:
  added:
    - "WhisperKit 0.17.0 (argmaxinc/WhisperKit) — CoreML Whisper on Apple Neural Engine"
    - "FluidAudio pinned to 0.12.4 (was 0.13.2) to resolve swift-transformers conflict"
  patterns:
    - "Batch recording: accumulate [Float] frames during tap, transcribe on stop"
    - "AVAudioConverter: single-stage 16kHz mono float32 resampling in tap callback"
    - "Singleton actor pattern matching ParakeetService shape"
key_files:
  created:
    - Sources/Voice/WhisperService.swift
    - Sources/Voice/WhisperModelSize.swift
  modified:
    - Package.swift
    - Package.resolved
    - Sources/Voice/VoiceService.swift
    - Sources/Monitor/ClaudeMonitor.swift
    - Sources/Onboarding/OnboardingViewModel.swift
  deleted:
    - Sources/Voice/ParakeetService.swift
decisions:
  - "Pinned FluidAudio to 0.12.4: FluidAudio 0.13.x requires swift-transformers 1.2+; WhisperKit 0.17.0 requires 1.1.x only — 0.12.4 uses 1.1.x and has full PocketTTS + StreamingEouAsrManager API"
  - "transcribe() returns [TranscriptionResult] in WhisperKit 0.17.0 — not TranscriptionResult? as in research pattern; used .first"
  - "Thread safety: audio tap dispatches frame chunks via Task @MainActor to avoid data race on whisperAudioFrames"
metrics:
  duration: "9 minutes"
  completed: "2026-03-28T09:22:35Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 5
  files_deleted: 1
---

# Phase 30 Plan 01: Whisper STT Summary

WhisperKit batch transcription replaces Parakeet streaming STT, enabling 99-language auto-detection via CoreML on Apple Neural Engine.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add WhisperKit dependency, create WhisperService actor and WhisperModelSize enum | eb4e07a | Package.swift, Package.resolved, WhisperService.swift, WhisperModelSize.swift |
| 2 | Replace Parakeet recording path with Whisper batch path in VoiceService, delete ParakeetService | 7c40c9a | VoiceService.swift, ParakeetService.swift (deleted), ClaudeMonitor.swift, OnboardingViewModel.swift |

## What Was Built

### WhisperModelSize enum (WhisperModelSize.swift)
Enum with `small` and `medium` cases, `modelName` identifiers, `displayLabel` strings, and `selected` computed property backed by UserDefaults. `Sendable` conformance for Swift 6.

### WhisperService actor (WhisperService.swift)
Singleton actor wrapping WhisperKit for batch transcription:
- `downloadModel(size:onProgress:)` — downloads CoreML model from HuggingFace with progress
- `initialize(size:)` — loads from cache at launch (pre-warm, no download)
- `transcribe([Float])` — batch transcribe with `DecodingOptions(detectLanguage: true)`, returns `(text, language)` tuple
- `modelsDownloaded` / `isModelDownloaded(size:)` — cheap disk stat checking `AudioEncoder.mlmodelc`
- `modelFolder(for:)` — `~/Library/Application Support/CC-Beeper/whisper/{modelName}/`
- `isReady` — `pipe != nil`
- `reset()` — no-op (Whisper is stateless between calls)
- `WhisperError.notLoaded` for pre-load guard

### VoiceService.swift (Whisper batch path)
- `startRecordingWhisper(inputNode:)` — installs AVAudioEngine tap, converts to 16kHz mono float32 via AVAudioConverter, accumulates frames in `whisperAudioFrames` via `Task @MainActor` for thread safety
- `stopRecording()` Whisper path — shows "Processing...", captures frames, calls `whisperService.transcribe(frames)`, injects result via `injectAndSubmit`
- `detectedLanguage` property (for Phase 32)
- `sttEngineLabel` returns `"Whisper (local)"`
- Fallback to SFSpeech if Whisper not ready or converter init fails
- `isRecording` stays `true` during transcription (prevents double-recording, Pitfall 6)

### ParakeetService.swift deleted (D-05)
Whisper is now the sole on-device STT engine.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] FluidAudio 0.13.x / WhisperKit 0.17.0 swift-transformers version conflict**
- **Found during:** Task 1 (swift package resolve)
- **Issue:** FluidAudio 0.13.2 requires swift-transformers `from: "1.2.0"` (actually `from: "1.3.0"` in latest 0.13.2.6); WhisperKit 0.17.0 requires `.upToNextMinor(from: "1.1.6")` (1.1.x only). SPM cannot resolve both simultaneously.
- **Fix:** Pinned FluidAudio to `exact: "0.12.4"` — the latest 0.12.x version that uses swift-transformers `from: "1.1.6"`. Version 0.12.4 has full PocketTtsManager (Kokoro TTS) and StreamingEouAsrManager APIs. All resolved at swift-transformers 1.1.9.
- **Files modified:** Package.swift, Package.resolved
- **Commit:** eb4e07a

**2. [Rule 1 - API] WhisperKit transcribe() returns [TranscriptionResult], not TranscriptionResult?**
- **Found during:** Task 1 (swift build)
- **Issue:** Research pattern used `guard let result = try await pipe.transcribe(...)` expecting `TranscriptionResult?`, but WhisperKit 0.17.0 `transcribe(audioArray:)` returns `[TranscriptionResult]` (the optional-returning overload is deprecated)
- **Fix:** Updated `transcribe()` in WhisperService to use `[TranscriptionResult]` return type and call `.first`
- **Files modified:** Sources/Voice/WhisperService.swift
- **Commit:** eb4e07a

**3. [Rule 2 - Missing] ClaudeMonitor and OnboardingViewModel referenced deleted ParakeetService**
- **Found during:** Task 2 (swift build after deletion)
- **Issue:** ClaudeMonitor pre-warmed `ParakeetService.shared.initialize()` at launch; OnboardingViewModel called `ParakeetService.shared.downloadModels()` and checked `ParakeetService.modelsDownloaded`
- **Fix:** Updated both to use WhisperService equivalents (pre-warm + download + modelsDownloaded check)
- **Files modified:** Sources/Monitor/ClaudeMonitor.swift, Sources/Onboarding/OnboardingViewModel.swift
- **Commit:** 7c40c9a

**4. [Rule 2 - Thread Safety] whisperAudioFrames race condition in audio tap**
- **Found during:** Task 2 (code review, Pitfall 2 from research)
- **Issue:** AVAudioEngine tap fires on real-time audio thread; appending directly to `whisperAudioFrames` (a `VoiceService` property) would be a Swift 6 data race
- **Fix:** Capture frame chunk locally in tap callback, dispatch to `@MainActor` via `Task { @MainActor [weak self] in self?.whisperAudioFrames.append(contentsOf: chunk) }` — matches research recommendation (Pattern 2, Pitfall 2 approach 2)
- **Files modified:** Sources/Voice/VoiceService.swift
- **Commit:** 7c40c9a

## Known Stubs

None. Whisper model download and transcription are fully wired. The `detectedLanguage` property is set but not consumed (intentional — Phase 32 is the consumer per D-12).

## Self-Check: PASSED

- Sources/Voice/WhisperService.swift: FOUND
- Sources/Voice/WhisperModelSize.swift: FOUND
- Sources/Voice/ParakeetService.swift: DELETED (correct)
- .planning/phases/30-whisper-stt/30-01-SUMMARY.md: FOUND
- Commit eb4e07a: FOUND
- Commit 7c40c9a: FOUND
- swift build: Build complete!
