# Requirements: CC-Beeper

**Defined:** 2026-03-31
**Core Value:** Users can see what Claude is doing, respond to it, and give it instructions — without leaving their current workflow

## v1.0 Requirements

Requirements for public launch. Each maps to roadmap phases.

### Audit — Functional Audit & Bug Fixes

- [ ] **AUDIT-01**: All 8 LCD states trigger correctly from Claude Code hook events (idle, working, done, error, approveQuestion, needsInput, listening, speaking)
- [ ] **AUDIT-02**: State priority resolution works correctly when multiple sessions are active (higher priority wins)
- [ ] **AUDIT-03**: "Stewing" / thinking state from Claude Code displays as WORKING, not SNOOZING
- [ ] **AUDIT-04**: Permission requests tracked by session ID in a dictionary, concurrent requests don't overwrite each other
- [ ] **AUDIT-05**: Kokoro TTS subprocess crash detected via termination handler, automatic fallback to Apple TTS
- [ ] **AUDIT-06**: Kokoro subprocess automatically restarts on next TTS request after crash
- [ ] **AUDIT-07**: Clipboard paste uses NSPasteboard.changeCount to detect external changes before restoring
- [ ] **AUDIT-08**: Voice injection verifies terminal is actually frontmost before posting CGEvents

### FRAG — Fragility & Silent Failures

- [ ] **FRAG-01**: Terminal focus uses NSWorkspace.didActivateApplicationNotification instead of usleep for focus wait
- [ ] **FRAG-02**: Clipboard paste timing uses event-driven approach instead of usleep
- [ ] **FRAG-03**: Port file write failures logged with diagnostic message, not silently swallowed
- [ ] **FRAG-04**: NWListener creation failure surfaced to user via LCD error state
- [ ] **FRAG-05**: AppMover copy failure shows alert with error message instead of empty catch
- [ ] **FRAG-06**: Terminal bundle IDs consolidated into single shared constant (VoiceService + ClaudeMonitor)
- [ ] **FRAG-07**: LCD color hex values centralized in ThemeManager
- [ ] **FRAG-08**: Kokoro venv path defined once as shared constant
- [ ] **FRAG-09**: Dev-only desktop fallback paths removed from TTSService

### ARCH — Architecture & Decomposition

- [ ] **ARCH-01**: SessionTracker extracted from ClaudeMonitor (session state aggregation, pruning, idle timer)
- [ ] **ARCH-02**: HookDispatcher extracted (HTTP payload parsing and routing to components)
- [ ] **ARCH-03**: PermissionController extracted (permission flow, pending state, preset auto-approve)
- [ ] **ARCH-04**: HotkeyManager extracted (Carbon hotkey registration, layout resolution)
- [ ] **ARCH-05**: ClaudeMonitor reduced to thin orchestrator wiring components together
- [ ] **ARCH-06**: Dead PocketTTS code removed (PocketTTSService, onboarding download phase, pocketttsVoice property)
- [ ] **ARCH-07**: Legacy Python hook script removed (hooks/cc-beeper-hook.py)
- [ ] **ARCH-08**: VoiceService.injectTextOnly dead code removed
- [ ] **ARCH-09**: Stale migrations removed (permission_mode, Python hook cleanup, hotkey keyCode)

### TEST — Protocol DI & Test Coverage

- [ ] **TEST-01**: Protocols defined for VoiceService, TTSService, HTTPHookServer
- [ ] **TEST-02**: ClaudeMonitor / SessionTracker state machine tested (all 8 states, priority resolution)
- [ ] **TEST-03**: HookDispatcher payload routing tested (all 6 hook event types)
- [ ] **TEST-04**: PermissionController auto-approve logic tested (all 4 presets)
- [ ] **TEST-05**: Hook-to-LCD integration flow tested (HTTP POST → state update)

### SEC — Security

- [ ] **SEC-01**: Cryptographically random bearer token generated at HTTP server startup
- [ ] **SEC-02**: Token written to ~/.claude/cc-beeper/token with 0o600 permissions
- [ ] **SEC-03**: All incoming hook requests validated against token, 401 on mismatch
- [ ] **SEC-04**: HookInstaller curl commands include Authorization: Bearer header

### IDE — IDE Support

- [ ] **IDE-01**: VS Code, Cursor, Zed, Ghostty bundle IDs added to focus/activation lists
- [ ] **IDE-02**: JetBrains IDE family bundle IDs added (IntelliJ, WebStorm, GoLand, PyCharm, CLion, Rider)
- [ ] **IDE-03**: Option-T focuses correct IDE when Claude Code is running in an IDE
- [ ] **IDE-04**: Voice injection works when IDE terminal panel is focused (activate IDE + terminal panel shortcut + inject)
- [ ] **IDE-05**: Graceful degradation when IDE terminal shortcut doesn't work (fall back to app-level focus)

### TAB — Tab-Level Terminal Focus

- [ ] **TAB-01**: Option-T focuses exact iTerm2 tab via AppleScript session PID matching
- [ ] **TAB-02**: Option-T focuses exact Terminal.app tab via AppleScript
- [ ] **TAB-03**: Option-T focuses Ghostty tab via working directory matching
- [ ] **TAB-04**: Graceful degradation to app-level focus when tab targeting fails

### DIST — Distribution

- [ ] **DIST-01**: DMG includes branded background image with drag-to-install layout
- [ ] **DIST-02**: DMG has app icon + Applications folder alias positioned correctly
- [ ] **DIST-03**: Homebrew cask formula in custom tap (vecartier/cc-beeper)
- [ ] **DIST-04**: `brew install --cask cc-beeper` installs from GitHub Releases DMG

### POLISH — Onboarding, Settings & Launch

- [ ] **POLISH-01**: Onboarding includes beeper color/theme selection step
- [ ] **POLISH-02**: Onboarding includes widget size selection (Large/Compact/Menu-only)
- [ ] **POLISH-03**: Onboarding includes permission spectrum selection
- [ ] **POLISH-04**: Onboarding visuals polished (consistent styling, smooth transitions)
- [ ] **POLISH-05**: Settings tabs reviewed and cleaned up
- [ ] **POLISH-06**: README finalized with hero GIF, feature screenshots, install instructions
- [ ] **POLISH-07**: GitHub repo cleaned up (stale files, metadata, description)
- [ ] **POLISH-08**: GitHub release tagged v1.0 with changelog

## v1.1 Requirements

Deferred to post-launch. Tracked but not in current roadmap.

### Concurrency

- **CONC-01**: Swift 6 strict concurrency migration (remove @unchecked Sendable)
- **CONC-02**: VoiceService/TTSService converted to @MainActor with audited off-main access
- **CONC-03**: Whisper audio frame Task flooding replaced with lock-protected buffer

### Auto-Update

- **UPDATE-01**: Sparkle 2.9.1 integrated via SPM
- **UPDATE-02**: EdDSA key pair generated and backed up
- **UPDATE-03**: Appcast hosted on GitHub Pages
- **UPDATE-04**: Background update checks with "Check for Updates" menu item

### Optimization

- **OPT-01**: MarqueeText timer replaced with TimelineView

### IDE Deep Integration

- **IDETAB-01**: Tab-level targeting within VS Code integrated terminal
- **IDETAB-02**: Tab-level targeting within JetBrains integrated terminal

## Out of Scope

| Feature | Reason |
|---------|--------|
| iOS/iPad companion | macOS only |
| App Store distribution | GitHub + DMG + Homebrew cask |
| Per-project settings | Global settings for v1.0 |
| Official homebrew/homebrew-cask submission | Requires 75+ GitHub stars, premature at launch |
| Swift 6 strict concurrency | High regression risk, needs dedicated testing cycle post-launch |
| Sparkle auto-updater | EdDSA key management + appcast hosting needs proper setup post-launch |
| Switchboard / hooks management GUI | CC-Beeper is a monitoring layer, not a config manager |
| Guidelines editor | CLAUDE.md editing belongs in terminal/editor |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIT-01 | Phase 39 | Pending |
| AUDIT-02 | Phase 39 | Pending |
| AUDIT-03 | Phase 39 | Pending |
| AUDIT-04 | Phase 39 | Pending |
| AUDIT-05 | Phase 39 | Pending |
| AUDIT-06 | Phase 39 | Pending |
| AUDIT-07 | Phase 39 | Pending |
| AUDIT-08 | Phase 39 | Pending |
| FRAG-01 | Phase 40 | Pending |
| FRAG-02 | Phase 40 | Pending |
| FRAG-03 | Phase 40 | Pending |
| FRAG-04 | Phase 40 | Pending |
| FRAG-05 | Phase 40 | Pending |
| FRAG-06 | Phase 40 | Pending |
| FRAG-07 | Phase 40 | Pending |
| FRAG-08 | Phase 40 | Pending |
| FRAG-09 | Phase 40 | Pending |
| ARCH-01 | Phase 41 | Pending |
| ARCH-02 | Phase 41 | Pending |
| ARCH-03 | Phase 41 | Pending |
| ARCH-04 | Phase 41 | Pending |
| ARCH-05 | Phase 41 | Pending |
| ARCH-06 | Phase 41 | Pending |
| ARCH-07 | Phase 41 | Pending |
| ARCH-08 | Phase 41 | Pending |
| ARCH-09 | Phase 41 | Pending |
| TEST-01 | Phase 43 | Pending |
| TEST-02 | Phase 43 | Pending |
| TEST-03 | Phase 43 | Pending |
| TEST-04 | Phase 43 | Pending |
| TEST-05 | Phase 43 | Pending |
| SEC-01 | Phase 42 | Pending |
| SEC-02 | Phase 42 | Pending |
| SEC-03 | Phase 42 | Pending |
| SEC-04 | Phase 42 | Pending |
| IDE-01 | Phase 44 | Pending |
| IDE-02 | Phase 44 | Pending |
| IDE-03 | Phase 44 | Pending |
| IDE-04 | Phase 44 | Pending |
| IDE-05 | Phase 44 | Pending |
| TAB-01 | Phase 44 | Pending |
| TAB-02 | Phase 44 | Pending |
| TAB-03 | Phase 44 | Pending |
| TAB-04 | Phase 44 | Pending |
| DIST-01 | Phase 45 | Pending |
| DIST-02 | Phase 45 | Pending |
| DIST-03 | Phase 45 | Pending |
| DIST-04 | Phase 45 | Pending |
| POLISH-01 | Phase 46 | Pending |
| POLISH-02 | Phase 46 | Pending |
| POLISH-03 | Phase 46 | Pending |
| POLISH-04 | Phase 46 | Pending |
| POLISH-05 | Phase 46 | Pending |
| POLISH-06 | Phase 46 | Pending |
| POLISH-07 | Phase 46 | Pending |
| POLISH-08 | Phase 46 | Pending |

**Coverage:**
- v1.0 requirements: 56 total
- Mapped to phases: 56
- Unmapped: 0

---
*Requirements defined: 2026-03-31*
*Last updated: 2026-03-31 — roadmap created, all 56 requirements mapped to phases 39-46*
