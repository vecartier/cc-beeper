# Phase 1: Hardening - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix known bugs and close security gaps in the IPC permission flow. The app should fail closed (deny) on any ambiguous or malformed data. No new features — just correctness.

</domain>

<decisions>
## Implementation Decisions

### YOLO mode indicator (BUG-01)
- Claude's discretion on the visual treatment — just make YOLO mode visually distinct in the menu bar
- Current: `EggIcon.image(attention:)` only has two states (normal/attention) — YOLO needs a third

### Window lookup (BUG-02)
- Replace `window.title == "Claumagotchi"` with a stable identifier
- Window ID from SwiftUI's `Window("Claumagotchi", id: "main")` is already set — use `id` not `title`

### Default-deny (BUG-03 / SEC-01)
- `hooks/claumagotchi-hook.py:236` — change `resp.get("decision", "allow")` to `resp.get("decision", "deny")`
- Both requirements are the same fix

### Event validation (SEC-02)
- Validate expected keys (`event`, `sid`, `ts`) before processing
- Reject events missing required fields — silent drop is fine (no user-facing error needed)

### Response freshness (SEC-03)
- Check timestamp in response.json against the pending request timestamp
- Reject responses that predate the current pending request
- Claude's discretion on the staleness window — a few seconds tolerance is fine

### Claude's Discretion
- Exact YOLO icon visual treatment (color, shape, or badge)
- Staleness threshold for response.json freshness check
- Whether to log rejected events/responses for debugging
- Window lookup implementation approach (as long as it's not title-based)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Source files to modify
- `Sources/ClaumagotchiApp.swift` — EggIcon (BUG-01), window lookup (BUG-02), AppDelegate
- `Sources/ClaudeMonitor.swift` — event processing (SEC-02), response validation (SEC-03)
- `hooks/claumagotchi-hook.py` — default-deny (BUG-03/SEC-01), response handling

### Codebase analysis
- `.planning/codebase/CONCERNS.md` — detailed bug descriptions with line numbers
- `.planning/codebase/ARCHITECTURE.md` — IPC data flow and layer descriptions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EggIcon.image(attention:)` — already parameterized with Bool, needs extension for YOLO state
- `ClaudeMonitor.processEvent()` — central event handler, all SEC-02 validation goes here
- `safe_write` / `safe_append` in Python hook — already handles symlink rejection, good pattern to follow

### Established Patterns
- `try?` for all file I/O — silent failure is the convention, maintain it
- `UserDefaults` for preferences — YOLO state already persisted via `autoAccept`
- MARK comments for section organization

### Integration Points
- `ClaumagotchiApp.swift:62` — `EggIcon.image(attention:)` call in MenuBarExtra label
- `ClaumagotchiApp.swift:68,76` — `toggleMainWindow()` and `showMainWindow()` window lookups
- `hooks/claumagotchi-hook.py:236` — permission decision default value
- `ClaudeMonitor.swift:170-173` — event JSON parsing entry point

</code_context>

<specifics>
## Specific Ideas

No specific requirements — all fixes are clear from the bug descriptions and security analysis. User deferred all gray areas to Claude's discretion.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-hardening*
*Context gathered: 2026-03-19*
