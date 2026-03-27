---
phase: 24-offline-stt
plan: 02
subsystem: onboarding, settings
tags: [offline-stt, parakeet, onboarding, settings, swift]
dependency_graph:
  requires: [24-01]
  provides: [onboarding-model-download-step, settings-stt-engine-indicator]
  affects: [OnboardingViewModel, OnboardingView, SettingsAudioSection]
tech_stack:
  added: []
  patterns: [actor-singleton-via-shared, published-state-for-download-progress]
key_files:
  created:
    - Sources/OnboardingModelDownloadStep.swift
  modified:
    - Sources/OnboardingViewModel.swift
    - Sources/OnboardingView.swift
    - Sources/SettingsAudioSection.swift
  deleted:
    - Sources/OnboardingAPIKeysStep.swift
key_decisions:
  - "Auto-start model download on step appear — user doesn't have to tap a button; Skip always available for SFSpeech fallback"
  - "downloadParakeetModel() uses ParakeetService.shared (not local instance) so the initialized manager is shared with VoiceService"
  - "Step.modelDownload replaces Step.apiKeys at same raw value 4 — step count stays 6, progress math unchanged"
  - "STT engine indicator is read-only (no selector) — Parakeet is always preferred if available per D-05"
metrics:
  duration: "~7 minutes"
  completed: "2026-03-27"
  tasks: 2
  files: 5
---

# Phase 24 Plan 02: Onboarding Model Download + Settings STT Indicator Summary

**One-liner:** Onboarding model download step with progress bar replaces API keys step; Settings > Voice shows active STT engine (Parakeet TDT or SFSpeech fallback).

## What Was Built

### Task 1: Replace apiKeys step with modelDownload (commit: a607204)

Replaced the `OnboardingAPIKeysStep` (API key input for Groq/OpenAI) with `OnboardingModelDownloadStep` (Parakeet TDT model download with progress). Changes:

- **OnboardingViewModel.swift**: Renamed `Step.apiKeys` to `Step.modelDownload` (raw value 4 unchanged, total count stays 6). Added `@Published` properties for download state (`modelDownloadProgress`, `modelDownloadPhase`, `isModelDownloading`, `isModelReady`). Added `init()` that checks `ParakeetService.modelsDownloaded` at creation. Added `downloadParakeetModel()` that calls `ParakeetService.shared.downloadModels()` with progress callbacks dispatched to MainActor.

- **OnboardingModelDownloadStep.swift** (new): SwiftUI view matching existing onboarding step style. Auto-starts download on `.onAppear` if model not already present. Shows progress bar with phase label during download, "Model Ready" checkmark when done, "Download (~600 MB)" button if download didn't auto-start. Skip button always visible; Continue button appears only when model is ready. If model was already downloaded, shows ready state immediately.

- **OnboardingView.swift**: Updated step routing from `.apiKeys: OnboardingAPIKeysStep` to `.modelDownload: OnboardingModelDownloadStep`.

- **OnboardingAPIKeysStep.swift**: Deleted entirely.

### Task 2: STT engine indicator in Settings + full build verification (commit: f5be73b)

- **SettingsAudioSection.swift**: Added an `HStack` row with `Label("STT Engine", systemImage: "waveform.and.mic")` and `Text(monitor.voiceService.sttEngineLabel)` positioned before the TTS Provider picker. Read-only display — no selector needed since Parakeet is always preferred if available (D-05). Accesses `VoiceService.sttEngineLabel` via `monitor.voiceService` (ClaudeMonitor exposes it as a `let` property).

- **swift build**: Full Phase 24 (ParakeetService + VoiceService + OnboardingViewModel + OnboardingModelDownloadStep + SettingsAudioSection) compiles cleanly — "Build complete!" with no warnings.

## Decisions Made

1. **Auto-start download on step appear**: Users should not need to find and press a download button. The step auto-starts on `.onAppear`, with Skip always available. Consistent with onboarding UX where permission steps auto-detect state.

2. **ParakeetService.shared throughout**: The `downloadParakeetModel()` method in OnboardingViewModel uses `ParakeetService.shared`, not a locally created instance. This ensures the `StreamingEouAsrManager` initialized during download is the same instance VoiceService uses for recording — no re-initialization needed.

3. **Step.modelDownload replaces Step.apiKeys at raw value 4**: Direct replacement keeps the 6-step total, preserves progress math (`Double(currentStep.rawValue) / Double(totalSteps - 1)`), and requires no other enum-dependent code changes.

4. **Read-only STT Engine row**: The Settings indicator is informational only. Per D-05, Parakeet is always preferred when the model is downloaded — there is no user-selectable engine. The row confirms which path is active.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data is live. `sttEngineLabel` reads the actual `ParakeetService.modelsDownloaded` disk check. `isModelReady` is initialized from the same disk check and updated by the real download flow.

## Self-Check: PASSED
