# Requirements: CC-Beeper

**Defined:** 2026-03-24 | **Updated:** 2026-03-28
**Core Value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow

## Milestone v6.0 — Multilingual Voice

### STT — Speech-to-Text (Recording)
- [x] **STT-01**: User can record voice input transcribed by Whisper (replacing Parakeet)
- [x] **STT-02**: User can choose Whisper model size in Settings (small default, medium optional)
- [x] **STT-03**: Whisper auto-detects spoken language for transcription

### TTS — Text-to-Speech (Reading)
- [x] **TTS-01**: Kokoro server supports all 9 language codes (EN-US, EN-UK, FR, ES, IT, PT, HI, JA, ZH)
- [ ] **TTS-02**: Voice picker in Settings filters voices by selected language
- [x] **TTS-03**: TTS reads Claude's responses in the user's chosen language

### LANG — Language Management
- [ ] **LANG-01**: User has a single language preference that drives both TTS voice and Kokoro lang_code
- [ ] **LANG-02**: Language preference defaults to macOS system language on first launch
- [ ] **LANG-03**: Language-specific dependencies (pyopenjtalk, ordered_set) are downloaded only when needed
- [ ] **LANG-04**: If macOS language is unsupported, onboarding shows available languages to pick from

### UX — Settings & Onboarding
- [ ] **UX-01**: Settings has a unified "Voice" tab with sections: Language, Reader, Record
- [ ] **UX-02**: Onboarding detects macOS language and presents it for confirmation/change
- [ ] **UX-03**: Onboarding downloads language-specific deps after user confirms language
- [ ] **UX-04**: Voice preview available during onboarding and in Settings

## Out of Scope
- Streaming STT (Whisper is batch — acceptable for push-to-talk)
- Training custom voices
- Offline translation
- Per-message language switching (auto-match STT detection to TTS)

## Traceability

| REQ | Phase |
|-----|-------|
| STT-01 | Phase 30 |
| STT-02 | Phase 30 |
| STT-03 | Phase 30 |
| TTS-01 | Phase 31 |
| TTS-02 | Phase 31 |
| TTS-03 | Phase 31 |
| LANG-01 | Phase 32 |
| LANG-02 | Phase 32 |
| LANG-03 | Phase 32 |
| LANG-04 | Phase 32 |
| UX-01 | Phase 33 |
| UX-02 | Phase 33 |
| UX-03 | Phase 33 |
| UX-04 | Phase 33 |
