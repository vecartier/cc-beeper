---
phase: 1
slug: hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no test framework — out of scope for v1.1) |
| **Config file** | none |
| **Quick run command** | `swift build -c release 2>&1 | tail -5` |
| **Full suite command** | `swift build -c release && python3 -c "import hooks.claumagotchi_hook" 2>/dev/null; echo $?` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift build -c release 2>&1 | tail -5`
- **After every plan wave:** Run full build + syntax check
- **Before `/gsd:verify-work`:** Full build must succeed
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01 | 01 | 1 | BUG-01 | build + manual | `swift build -c release` | N/A | pending |
| 01-02 | 01 | 1 | BUG-02 | build + grep | `grep -c 'identifier' Sources/ClaumagotchiApp.swift` | N/A | pending |
| 01-03 | 01 | 1 | BUG-03 | grep | `grep 'deny' hooks/claumagotchi-hook.py` | N/A | pending |
| 01-04 | 01 | 1 | SEC-01 | grep | `grep -c 'decision.*deny' hooks/claumagotchi-hook.py` | N/A | pending |
| 01-05 | 01 | 1 | SEC-02 | build + grep | `grep -c 'is String' Sources/ClaudeMonitor.swift` | N/A | pending |
| 01-06 | 01 | 1 | SEC-03 | grep | `grep -c 'getmtime\|pending_ts' hooks/claumagotchi-hook.py` | N/A | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed — changes are verifiable via build success + grep patterns.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| YOLO icon is visually distinct | BUG-01 | Visual appearance in menu bar | Enable YOLO mode, verify menu bar icon differs from normal/attention states |
| Window toggle works after title change | BUG-02 | Window management behavior | Rename window title in code, verify toggle still works |
| Permission denied on malformed response | BUG-03/SEC-01 | End-to-end IPC flow | Write malformed JSON to response.json, verify hook returns deny |
| Stale response ignored | SEC-03 | Timing-dependent behavior | Pre-write response.json before triggering permission, verify it's ignored |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
