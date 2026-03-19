# Requirements: Claumagotchi

**Defined:** 2026-03-19
**Core Value:** Users can see what Claude is doing and respond to permission requests without leaving their workflow

## v1.1 Requirements

Requirements for the polish and hardening milestone. Each maps to roadmap phases.

### Bug Fixes

- [ ] **BUG-01**: YOLO mode shows a distinct visual indicator in the menu bar icon
- [ ] **BUG-02**: Window lookup uses a stable identifier instead of matching by title string
- [ ] **BUG-03**: Malformed or empty permission response defaults to deny, not allow

### Security

- [ ] **SEC-01**: Permission response file defaults to deny when decision key is missing or malformed
- [ ] **SEC-02**: Event JSON is validated against expected schema before processing
- [ ] **SEC-03**: Response file is checked for freshness (timestamp) to prevent stale/pre-written responses

### Reliability

- [ ] **REL-01**: File watcher recovers automatically when events.jsonl is deleted and recreated
- [ ] **REL-02**: Sprite animation timer pauses when the app window is not visible
- [ ] **REL-03**: Idle timer and state are managed without manual Timer objects where possible

### Performance

- [ ] **PERF-01**: Noise texture is rendered once and cached as an image, not re-rendered per frame
- [ ] **PERF-02**: Aggregate state updates avoid reading sessions.json from disk on every event
- [ ] **PERF-03**: Duplicate hex color parsing logic is unified into a single implementation

### UX

- [ ] **UX-01**: Active session count is displayed on the LCD screen
- [ ] **UX-02**: Character plays a sleeping/idle animation after a period of inactivity
- [ ] **UX-03**: Permission prompt shows the full file path or command, not just the tool name
- [ ] **UX-04**: Global hotkeys (Option+A to allow, Option+D to deny) respond to permissions system-wide

### Notifications

- [ ] **NOTIF-01**: macOS Notification Center alert fires when a permission request arrives
- [ ] **NOTIF-02**: Notification fires when a Claude session finishes
- [ ] **NOTIF-03**: Notification fires on tool errors or permission timeouts
- [ ] **NOTIF-04**: User can enable/disable notifications via menu bar toggle

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Testing

- **TEST-01**: Unit tests for ClaudeState transitions and aggregate state logic
- **TEST-02**: Integration tests for IPC round-trip (hook writes, app reads)
- **TEST-03**: Python hook tests for event mapping and permission flow

### Modernization

- **MOD-01**: Migrate to Swift Concurrency (async/await) replacing GCD patterns
- **MOD-02**: Replace JSONSerialization with Codable models

## Out of Scope

| Feature | Reason |
|---------|--------|
| Actionable notification buttons | App is always floating — buttons in notifications are redundant |
| iOS/iPad companion | macOS-only tool, no cross-platform need |
| Third-party dependencies | Self-contained distribution, minimal attack surface |
| Claude Code protocol changes | Hook protocol must remain backward compatible |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUG-01 | Phase 1 | Pending |
| BUG-02 | Phase 1 | Pending |
| BUG-03 | Phase 1 | Pending |
| SEC-01 | Phase 1 | Pending |
| SEC-02 | Phase 1 | Pending |
| SEC-03 | Phase 1 | Pending |
| REL-01 | Phase 2 | Pending |
| REL-02 | Phase 2 | Pending |
| REL-03 | Phase 2 | Pending |
| PERF-01 | Phase 2 | Pending |
| PERF-02 | Phase 2 | Pending |
| PERF-03 | Phase 2 | Pending |
| UX-01 | Phase 3 | Pending |
| UX-02 | Phase 3 | Pending |
| UX-03 | Phase 3 | Pending |
| UX-04 | Phase 3 | Pending |
| NOTIF-01 | Phase 4 | Pending |
| NOTIF-02 | Phase 4 | Pending |
| NOTIF-03 | Phase 4 | Pending |
| NOTIF-04 | Phase 4 | Pending |

**Coverage:**
- v1.1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-03-19*
*Last updated: 2026-03-19 after roadmap creation*
