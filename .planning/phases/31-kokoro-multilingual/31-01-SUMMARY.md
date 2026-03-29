---
phase: 31-kokoro-multilingual
plan: 01
subsystem: Voice/TTS
tags: [kokoro, tts, multilingual, python, swift]
dependency_graph:
  requires: []
  provides: [kokoro-multilingual-backend, kokoro-voice-catalog, kokoro-deps-installer]
  affects: [TTSService, ClaudeMonitor, kokoro-tts-server]
tech_stack:
  added: [KokoroVoiceCatalog, KokoroDepsInstaller]
  patterns: [KModel-sharing, LANG-command, on-demand-pip-install]
key_files:
  created:
    - Sources/Voice/KokoroVoiceCatalog.swift
    - Sources/Voice/KokoroDepsInstaller.swift
  modified:
    - Sources/kokoro-tts-server.py
    - Sources/Voice/TTSService.swift
    - Sources/Monitor/ClaudeMonitor.swift
decisions:
  - "KModel shared across language switches for sub-1s latency (0.77s measured vs 1.75s full reload)"
  - "LANG: command follows same stdin protocol as existing VOICE: command"
  - "kokoroLangCode defaults to 'a' (American English) until Phase 32 sets it from system language"
  - "Japanese requires two-phase install: misaki[ja] pip + unidic download (~502MB)"
metrics:
  duration: 127s
  completed: "2026-03-29"
  tasks: 2
  files: 5
---

# Phase 31 Plan 01: Kokoro Multilingual Backend Summary

**One-liner:** Kokoro TTS extended to 9 languages via LANG: command with KModel sharing, static 54-voice catalog, and on-demand pip installer for Japanese/Chinese deps.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Kokoro server LANG: command + voice catalog + deps installer | 5d53791 | kokoro-tts-server.py, KokoroVoiceCatalog.swift, KokoroDepsInstaller.swift |
| 2 | TTSService.setKokoroLangCode + ClaudeMonitor.kokoroLangCode property | 8b2e1e6 | TTSService.swift, ClaudeMonitor.swift |

## What Was Built

### kokoro-tts-server.py
- Added `import importlib.util` for dep detection
- Added `lang_deps_installed(lang_code)` function checking pyopenjtalk (Japanese) and jieba (Chinese) via `find_spec`
- Added `shared_model = pipeline.model` after initial KPipeline load to prevent GC on pipeline reassignment
- Added `lang_code = 'a'` local variable tracking alongside `voice`
- Added `LANG:` command handler: checks deps, recreates KPipeline with `model=shared_model`, catches `ImportError` and `AssertionError` with appropriate log messages

### KokoroVoiceCatalog.swift (new)
- Static `voicesByLang: [String: [Voice]]` dictionary with all 54 voices across 9 language codes
- `languageNames: [String: String]` mapping codes to human-readable names
- `langCodesRequiringDeps: Set<String> = ["j", "z"]` for gating dep install
- Helper functions: `defaultVoice(for:)` and `isVoiceValid(_:for:)`

### KokoroDepsInstaller.swift (new)
- `@MainActor` class with `@Published` install state (`isInstalling`, `installProgress`, `installError`)
- `areDepsInstalled(for:)` — async, runs `python -c "import module"` and checks exit code
- `installDeps(for:)` — async two-phase for Japanese (pip + unidic download), one-phase for Chinese
- stderr streaming to `installProgress` for real-time UI feedback

### TTSService.swift
- Added `setKokoroLangCode(_ code: String)` — mirrors `setKokoroVoice` exactly, sends `LANG:{code}\n` to subprocess stdin

### ClaudeMonitor.swift
- Added `@Published var kokoroLangCode: String = "a"` with UserDefaults persistence
- `didSet` sends lang code to `ttsService.setKokoroLangCode()` and auto-selects first valid voice if current voice is invalid for new language
- `init()` loads persisted value: `kokoroLangCode = UserDefaults.standard.string(forKey: "kokoroLangCode") ?? "a"`

## Verification

All 7 verification checks pass:
1. `swift build` succeeds with zero errors
2. `grep "LANG:" Sources/kokoro-tts-server.py` shows command handler
3. `grep "shared_model" Sources/kokoro-tts-server.py` shows KModel sharing
4. `grep "setKokoroLangCode" Sources/Voice/TTSService.swift` shows new method
5. `grep "kokoroLangCode" Sources/Monitor/ClaudeMonitor.swift` shows property
6. `KokoroVoiceCatalog.swift` contains all 9 language keys
7. `KokoroDepsInstaller.swift` contains both `installDeps` and `areDepsInstalled`

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all functionality is wired. Phase 32 will use `kokoroLangCode` to derive the initial language from the system locale.

## Self-Check: PASSED

- `/Users/vcartier/Desktop/CC-Beeper/Sources/kokoro-tts-server.py` — FOUND, contains LANG:, shared_model, importlib.util, lang_deps_installed
- `/Users/vcartier/Desktop/CC-Beeper/Sources/Voice/KokoroVoiceCatalog.swift` — FOUND, contains voicesByLang with 9 keys
- `/Users/vcartier/Desktop/CC-Beeper/Sources/Voice/KokoroDepsInstaller.swift` — FOUND, contains installDeps and areDepsInstalled
- `/Users/vcartier/Desktop/CC-Beeper/Sources/Voice/TTSService.swift` — FOUND, contains setKokoroLangCode
- `/Users/vcartier/Desktop/CC-Beeper/Sources/Monitor/ClaudeMonitor.swift` — FOUND, contains kokoroLangCode @Published property
- Commits 5d53791 and 8b2e1e6 — FOUND in git log
