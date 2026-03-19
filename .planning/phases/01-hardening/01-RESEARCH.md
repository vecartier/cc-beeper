# Phase 1: Hardening - Research

**Researched:** 2026-03-19
**Domain:** macOS SwiftUI app bug fixes + Python IPC security hardening
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **BUG-01:** Claude's discretion on visual treatment — YOLO mode must be visually distinct in menu bar (not orange like `needsYou`)
- **BUG-02:** Replace `window.title == "Claumagotchi"` with a stable identifier — `Window("Claumagotchi", id: "main")` already sets the id; use `id` not `title`
- **BUG-03 / SEC-01:** Change `resp.get("decision", "allow")` to `resp.get("decision", "deny")` at `hooks/claumagotchi-hook.py:236`
- **SEC-02:** Validate expected keys (`event`, `sid`, `ts`) before processing; silent drop is acceptable
- **SEC-03:** Check timestamp in response.json against the pending request timestamp; reject stale responses

### Claude's Discretion
- Exact YOLO icon visual treatment (color, shape, or badge)
- Staleness threshold for response.json freshness check
- Whether to log rejected events/responses for debugging
- Window lookup implementation approach (as long as it's not title-based)

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BUG-01 | YOLO mode shows a distinct visual indicator in the menu bar icon | EggIcon refactor: 2-state Bool → 3-state enum; `isTemplate` behavior documented below |
| BUG-02 | Window lookup uses a stable identifier instead of matching by title string | NSWindow.identifier pattern confirmed: `$0.identifier?.rawValue == "main"` |
| BUG-03 | Malformed or empty permission response defaults to deny, not allow | Single-line change at hook:236 documented below |
| SEC-01 | Permission response file defaults to deny when decision key is missing or malformed | Same fix as BUG-03 — identical code location |
| SEC-02 | Event JSON is validated against expected schema before processing | Guard clause extension in `processEvent()` documented below |
| SEC-03 | Response file is checked for freshness (timestamp) to prevent stale/pre-written responses | Two implementation options documented; mtime approach preferred (no Swift changes needed) |
</phase_requirements>

---

## Summary

Phase 1 is a surgical hardening pass: five distinct code changes across three files, zero new features, zero new dependencies. The changes are self-contained and low-regression risk because each fix is isolated to a single function. The most complex change is BUG-01 (YOLO icon), which requires refactoring `EggIcon` from a 2-state `Bool` parameter to a 3-state enum and updating the single call site.

The IPC security fixes (BUG-03/SEC-01, SEC-02, SEC-03) all follow the same philosophical shift: fail closed rather than silently passing bad data. Python's `resp.get("decision", "allow")` default and Swift's lack of schema validation are the two structural gaps. The freshness check for SEC-03 is best implemented entirely in Python using file mtime comparison — it requires no changes to the Swift response format.

The window lookup fix (BUG-02) relies on AppKit's `NSWindow.identifier` property, which SwiftUI's `Window("...", id: "main")` scene populates automatically. This is well-established community practice with multiple corroborating sources.

**Primary recommendation:** Implement all six requirements as five atomic changes (BUG-03 and SEC-01 are the same line). Each change is independently testable and deployable within a single wave.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 14+ (Sonoma) | UI + scene management | Already in use; `Window(id:)` API available since macOS 13 |
| AppKit | macOS 14+ | `NSWindow`, `NSImage`, `NSColor` | Required for menu bar icon rendering and window manipulation |
| Foundation | Swift stdlib | `UserDefaults`, `FileManager`, JSON | Already in use throughout |
| Python stdlib | 3.x (system) | `json`, `os`, `time`, `secrets` | Hook is pure stdlib — no third-party deps by design |

### No New Dependencies
This phase requires zero new packages. All fixes use existing infrastructure.

---

## Architecture Patterns

### Relevant Project Structure
```
Sources/
├── ClaumagotchiApp.swift   # EggIcon (BUG-01), window lookup (BUG-02)
├── ClaudeMonitor.swift     # Event validation (SEC-02), response freshness (SEC-03)
└── ...
hooks/
└── claumagotchi-hook.py    # Default-deny (BUG-03/SEC-01), freshness check (SEC-03 option B)
```

### Pattern 1: EggIcon Three-State Enum (BUG-01)

**What:** Replace `EggIcon.image(attention: Bool)` with a 3-state approach. The current `isTemplate = !attention` behavior must be preserved for normal state (template = adapts to dark/light mode) and non-template for colored states.

**When to use:** Whenever `monitor.state.needsAttention` OR `monitor.autoAccept` is true, the icon should be non-template with a distinct color.

**Color choice:** Use `.systemPurple` for YOLO (autoAccept) and `.systemOrange` for `needsYou`. Normal state stays `.black` with `isTemplate = true`.

**Call site (ClaumagotchiApp.swift:62):**
```swift
// BEFORE
Image(nsImage: EggIcon.image(attention: monitor.state.needsAttention))

// AFTER
Image(nsImage: EggIcon.image(state: monitor.yoloIconState))
```

**New computed property on ClaudeMonitor (or inline at call site):**
```swift
// In ClaudeMonitor or at call site:
var yoloIconState: EggIconState {
    if autoAccept { return .yolo }
    if state.needsAttention { return .attention }
    return .normal
}
```

**Refactored EggIcon:**
```swift
enum EggIconState { case normal, attention, yolo }

enum EggIcon {
    static func image(state: EggIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor = switch state {
            case .normal:    .black
            case .attention: .systemOrange
            case .yolo:      .systemPurple
        }
        let img = NSImage(size: size, flipped: true) { _ in
            // ... same drawing code ...
            return true
        }
        img.isTemplate = (state == .normal)
        return img
    }
}
```

**Confidence:** HIGH — drawing code is unchanged; only parameterization changes.

---

### Pattern 2: Window Lookup by Identifier (BUG-02)

**What:** SwiftUI's `Window("Claumagotchi", id: "main")` sets `NSWindow.identifier` to `NSUserInterfaceItemIdentifier(rawValue: "main")`. Use this instead of `.title`.

**Why title matching breaks:** Window title can change (localization, OS version behavior, other windows with same title). The `id` is developer-controlled and stable.

**Verified pattern (MEDIUM confidence — confirmed by community, consistent with Apple's documented behavior that `id` derives the window identifier):**
```swift
// BEFORE
for window in NSApp.windows where window.title == "Claumagotchi" { ... }

// AFTER
for window in NSApp.windows where window.identifier?.rawValue == "main" { ... }
```

**Both `toggleMainWindow()` (line 68) and `showMainWindow()` (line 76) need this change.**

**Note:** The `identifier` property is of type `NSUserInterfaceItemIdentifier?`, so `.rawValue` gives the underlying `String`. Comparing `.rawValue == "main"` is safe and non-optional because the outer `where` clause short-circuits.

---

### Pattern 3: Default-Deny (BUG-03 / SEC-01)

**What:** A single-character change in the Python hook.

**Location:** `hooks/claumagotchi-hook.py:236`

```python
# BEFORE
decision = resp.get("decision", "allow")

# AFTER
decision = resp.get("decision", "deny")
```

**Also harden against non-string or unexpected values:**
```python
decision = resp.get("decision", "deny")
if decision not in ("allow", "deny"):
    decision = "deny"
```

**Why the second guard matters:** A malformed JSON value (e.g., `True`, `1`, `null`) would pass `resp.get()` but wouldn't be `"allow"` — normalizing to `"deny"` closes this case too.

**Confidence:** HIGH — direct fix of the documented vulnerability at the exact line.

---

### Pattern 4: Event Schema Validation (SEC-02)

**What:** Extend the existing guard in `ClaudeMonitor.processEvent()` to require `sid` and `ts`.

**Location:** `Sources/ClaudeMonitor.swift:170-175`

```swift
// BEFORE
private func processEvent(_ json: String) {
    guard let data = json.data(using: .utf8),
          let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let type = event["event"] as? String else { return }

    let sid = event["sid"] as? String ?? ""

// AFTER
private func processEvent(_ json: String) {
    guard let data = json.data(using: .utf8),
          let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let type = event["event"] as? String,
          event["sid"] is String,         // required field
          event["ts"] is Int else { return }   // required field

    let sid = event["sid"] as? String ?? ""
```

**Why `is` not `as?`:** We're validating presence and type, not extracting. The existing `sid` extraction line below can stay as-is.

**Note:** The hook always writes `sid` (may be empty string) and `ts` (always an Int). Legitimate events from the hook always have these fields. Events from other sources (or corrupted lines) should be rejected.

**Confidence:** HIGH — direct extension of the existing guard pattern.

---

### Pattern 5: Response Freshness Check (SEC-03)

**What:** Reject `response.json` files written before the current permission request was issued.

**Two implementation options — prefer Option A:**

#### Option A: mtime comparison in Python (RECOMMENDED)
No changes to Swift needed. Check file modification time against `pending["ts"]`.

```python
# In handle_permission(), after reading resp successfully:
if resp.get("id") == req_id:
    # Freshness check: response must have been written after pending was issued
    resp_mtime = os.path.getmtime(RESPONSE_FILE)
    if resp_mtime < pending_ts - 2:   # 2-second tolerance for clock skew
        try:
            os.remove(RESPONSE_FILE)
        except OSError:
            pass
        time.sleep(0.3)
        continue   # keep polling; treat as stale
    # ... proceed with normal decision handling ...
```

**Where to get `pending_ts`:** It's already in the `pending` dict written at line 214. Add a local variable:
```python
pending_ts = int(time.time())   # capture before writing pending.json
pending = {
    "id": req_id,
    "tool": tool,
    "summary": summarize_input(tool, tool_input),
    "ts": pending_ts,   # already there
}
```
Then use `pending_ts` in the freshness check.

**Staleness threshold:** 2 seconds is conservative but sufficient. The response must have been written after the pending file — any pre-written response file would have mtime before `pending_ts`.

#### Option B: ts field in response.json
Add `"ts": int(time.time())` to the Swift `respondToPermission()` response dict, then compare in Python. More explicit but requires coordinated Swift + Python changes.

**Why Option A is preferred:** No Swift changes, no response format version bump, uses OS-level timestamps that can't be spoofed by writing JSON content.

**Confidence:** HIGH for Option A logic — `os.path.getmtime()` is stdlib, reliable on macOS.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic file writes | Custom file write with seek | `safe_write()` already in hook | Symlink protection already implemented |
| Window finding | String title search | `identifier?.rawValue` | Title is mutable; identifier is stable |
| Icon state | Ad-hoc Bool flags | Enum with 3 cases | Exhaustive switch prevents missed states at compile time |

**Key insight:** The existing `safe_write` / `safe_append` pattern in the hook is a good model — apply the same "validate before acting" discipline to the decision parsing.

---

## Common Pitfalls

### Pitfall 1: NSImage isTemplate and Color Rendering
**What goes wrong:** If `isTemplate = true` on a colored icon, macOS ignores the color and renders it as a silhouette in the menu bar accent color.
**Why it happens:** Template images are recolored by the system.
**How to avoid:** Set `isTemplate = false` for any state with a custom color. Only the "normal" (black) state should be `isTemplate = true`.
**Warning signs:** YOLO/orange icon appears gray or wrong color in menu bar.

### Pitfall 2: NSWindow.identifier May Be Nil
**What goes wrong:** Some NSWindow instances (e.g., the MenuBarExtra's internal window) have `nil` identifier.
**Why it happens:** Not all AppKit windows created by SwiftUI have a developer-controlled identifier.
**How to avoid:** The `where window.identifier?.rawValue == "main"` clause safely skips nil identifiers via optional chaining — no crash risk.
**Warning signs:** If the main window is never found, check if SwiftUI assigns the identifier at a different lifecycle point.

### Pitfall 3: EggIconState Computed Property Location
**What goes wrong:** Adding `yoloIconState` directly to `ClaudeMonitor` creates a non-`@Published` computed property dependency — SwiftUI won't observe `autoAccept` AND `state` changes automatically unless both are `@Published`.
**Why it happens:** SwiftUI observes `@Published` properties directly; computed properties based on them are re-evaluated when the view body runs, which is triggered by any `@Published` change.
**How to avoid:** Because both `autoAccept` and `state` are already `@Published`, a computed property `yoloIconState` on `ClaudeMonitor` will work correctly — the menu bar label re-evaluates when either changes.

### Pitfall 4: Freshness Check Off-by-One
**What goes wrong:** If `pending_ts` is captured after `safe_write(PENDING_FILE, ...)` rather than before, and the response file was written during that brief window, it passes the check incorrectly.
**Why it happens:** Timing — capture `pending_ts` before writing pending.json so the baseline is conservative.
**How to avoid:** Capture `pending_ts = int(time.time())` before the `safe_write` call.

### Pitfall 5: Python decision validation whitelist vs. blacklist
**What goes wrong:** Checking `if decision != "allow": decision = "deny"` is correct — but checking for unexpected values separately avoids passing a non-string (e.g. `True`) to Claude Code's hook output.
**How to avoid:** Use the explicit whitelist check: `if decision not in ("allow", "deny"): decision = "deny"`.

---

## Code Examples

### Complete EggIcon refactor
```swift
// Sources/ClaumagotchiApp.swift

enum EggIconState {
    case normal
    case attention   // needsYou — orange
    case yolo        // autoAccept — purple
}

enum EggIcon {
    static func image(state: EggIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let color: NSColor = switch state {
        case .normal:    .black
        case .attention: .systemOrange
        case .yolo:      .systemPurple
        }

        let img = NSImage(size: size, flipped: true) { _ in
            let eggRect = NSRect(x: 2, y: 1, width: 14, height: 16)
            let egg = NSBezierPath(ovalIn: eggRect)
            color.setFill()
            egg.fill()

            let screen = NSRect(x: 5, y: 4, width: 8, height: 6)
            let screenPath = NSBezierPath(roundedRect: screen, xRadius: 1, yRadius: 1)
            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            screenPath.fill()

            NSGraphicsContext.current?.compositingOperation = .sourceOver
            color.setFill()
            NSRect(x: 7, y: 6, width: 1.5, height: 1.5).fill()
            NSRect(x: 10, y: 6, width: 1.5, height: 1.5).fill()
            NSRect(x: 8, y: 8, width: 3, height: 1).fill()

            NSGraphicsContext.current?.compositingOperation = .copy
            NSColor.clear.setFill()
            for dx: CGFloat in [5.5, 8.5, 11.5] {
                NSBezierPath(ovalIn: NSRect(x: dx, y: 12, width: 1.5, height: 1.5)).fill()
            }
            return true
        }
        img.isTemplate = (state == .normal)
        return img
    }
}
```

### Call site update (ClaumagotchiApp.swift:62)
```swift
// In MenuBarExtra label:
Image(nsImage: EggIcon.image(state: monitor.yoloIconState))
```

### yoloIconState computed property (ClaudeMonitor.swift)
```swift
// Add to ClaudeMonitor, no @Published needed — derived from @Published properties
var yoloIconState: EggIconState {
    if autoAccept { return .yolo }
    if state.needsAttention { return .attention }
    return .normal
}
```

### Window lookup (ClaumagotchiApp.swift:68, 76)
```swift
static func toggleMainWindow() {
    for window in NSApp.windows where window.identifier?.rawValue == "main" {
        window.isVisible ? window.orderOut(nil) : window.makeKeyAndOrderFront(nil)
        return
    }
}

static func showMainWindow() {
    for window in NSApp.windows where window.identifier?.rawValue == "main" {
        if !window.isVisible {
            window.makeKeyAndOrderFront(nil)
        }
        return
    }
}
```

### Default-deny + whitelist (claumagotchi-hook.py:236)
```python
decision = resp.get("decision", "deny")
if decision not in ("allow", "deny"):
    decision = "deny"
```

### Event schema validation (ClaudeMonitor.swift:170-175)
```swift
private func processEvent(_ json: String) {
    guard let data = json.data(using: .utf8),
          let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let type = event["event"] as? String,
          event["sid"] is String,
          event["ts"] is Int else { return }

    let sid = event["sid"] as? String ?? ""
    // ... rest unchanged
```

### Response freshness check (claumagotchi-hook.py, in handle_permission)
```python
def handle_permission(data, session_id=""):
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})
    req_id = secrets.token_hex(16)
    pending_ts = int(time.time())   # capture BEFORE writing pending.json

    pending = {
        "id": req_id,
        "tool": tool,
        "summary": summarize_input(tool, tool_input),
        "ts": pending_ts,
    }
    safe_write(PENDING_FILE, json.dumps(pending))
    write_event("permission", tool=tool, sid=session_id)

    start = time.time()
    while time.time() - start < PERMISSION_TIMEOUT:
        if os.path.exists(RESPONSE_FILE):
            try:
                with open(RESPONSE_FILE) as f:
                    resp = json.load(f)
                if resp.get("id") == req_id:
                    # Freshness: response must have been written after pending was issued
                    resp_mtime = os.path.getmtime(RESPONSE_FILE)
                    if resp_mtime < pending_ts - 2:
                        try:
                            os.remove(RESPONSE_FILE)
                        except OSError:
                            pass
                        time.sleep(0.3)
                        continue
                    try:
                        os.remove(RESPONSE_FILE)
                    except OSError:
                        pass
                    try:
                        os.remove(PENDING_FILE)
                    except OSError:
                        pass

                    decision = resp.get("decision", "deny")
                    if decision not in ("allow", "deny"):
                        decision = "deny"
                    output = {
                        "hookSpecificOutput": {
                            "hookEventName": "PermissionRequest",
                            "decision": {
                                "behavior": decision,
                                "message": f"{'Approved' if decision == 'allow' else 'Denied'} via Claumagotchi",
                            },
                        }
                    }
                    print(json.dumps(output))
                    return
            except (json.JSONDecodeError, KeyError, IOError):
                pass
        time.sleep(0.3)

    try:
        os.remove(PENDING_FILE)
    except OSError:
        pass
    write_event("permission_timeout", sid=session_id)
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `window.title == "..."` title matching | `window.identifier?.rawValue == "main"` | Stable, title-change resistant |
| `resp.get("decision", "allow")` | `resp.get("decision", "deny")` + whitelist | Fail-closed security |
| 2-state `EggIcon.image(attention: Bool)` | 3-state `EggIcon.image(state: EggIconState)` | Exhaustive enum, compile-time safe |

---

## Open Questions

1. **NSWindow.identifier timing**
   - What we know: SwiftUI's `Window(id:)` sets `NSWindow.identifier` at window creation time
   - What's unclear: Whether the identifier is set before `applicationDidFinishLaunching` completes or only after the first window render
   - Recommendation: The window lookup functions are only called on user interaction (menu tap), so the identifier is guaranteed to be set by then — no timing concern in practice

2. **EggIconState placement**
   - What we know: `EggIconState` is a new type; project convention is separate types in separate files
   - What's unclear: Whether it belongs in `ClaumagotchiApp.swift` (used there) or a new `EggIcon.swift` file
   - Recommendation: Keep it in `ClaumagotchiApp.swift` alongside `EggIcon` enum — both are purely UI/presentation types for the menu bar; splitting would be over-engineering for 2 small enums

3. **SEC-03 edge case: response.json from previous session**
   - What we know: Response file is deleted after each permission flow; but a crash could leave a stale file
   - What's unclear: Whether `resp.get("id") == req_id` already handles this (yes — the ID won't match a stale response from a previous session)
   - Recommendation: The existing ID-match guard already prevents cross-session confusion; SEC-03's freshness check is defense-in-depth for within-session attacks (e.g., race-writing a response before the prompt appears). Both guards are needed.

---

## Validation Architecture

No test infrastructure exists in this project (no `tests/` directory, no test config files, no Swift test targets). The project is a macOS app with no automated test suite — consistent with the v2 deferred requirement for TEST-01, TEST-02, TEST-03.

**Manual verification plan per requirement:**

| ID | Behavior | Verification Method |
|----|----------|---------------------|
| BUG-01 | YOLO icon is purple in menu bar when autoAccept=true | Toggle YOLO mode; visually confirm icon color changes |
| BUG-01 | Permission-pending icon is orange (unchanged) | Trigger a permission request; visually confirm orange icon |
| BUG-01 | Normal idle icon is black/template (unchanged) | Verify icon adapts to dark/light menu bar in normal state |
| BUG-02 | Show/Hide menu item opens window | Click "Show / Hide" from menu bar; confirm window toggles |
| BUG-02 | Window opens even if app was restarted | Quit + relaunch; confirm Show/Hide still works |
| BUG-03/SEC-01 | Empty response.json results in deny | Write `{}` to response.json during pending request; confirm Claude Code gets deny |
| BUG-03/SEC-01 | Missing decision key results in deny | Write `{"id": "...", "other": "x"}` to response.json; confirm deny |
| SEC-02 | Event missing `ts` is silently dropped | Append malformed JSONL line without `ts`; confirm no crash, no state change |
| SEC-02 | Event missing `sid` is silently dropped | Same with missing `sid` field |
| SEC-03 | Pre-written response.json is ignored | Write response.json before triggering permission; confirm it's treated as stale |

**Build command:** `make` (from project root via `build.sh`)

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `Sources/ClaumagotchiApp.swift` — EggIcon implementation, window lookup functions, call sites
- Direct code inspection: `Sources/ClaudeMonitor.swift` — processEvent(), guard clause, respondToPermission()
- Direct code inspection: `hooks/claumagotchi-hook.py` — handle_permission(), default at line 236
- `.planning/codebase/CONCERNS.md` — authoritative bug descriptions with exact line numbers

### Secondary (MEDIUM confidence)
- Community pattern via WebSearch: `NSApp.windows.first(where: { $0.identifier?.rawValue == "main" })` — confirmed working pattern for SwiftUI Window id → NSWindow.identifier mapping
- Apple documentation pattern: `NSWindow.identifier` is `NSUserInterfaceItemIdentifier?` — standard AppKit property

### Tertiary (LOW confidence)
- None — all critical claims verified against source code or established AppKit documentation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — project has no new dependencies; uses existing Swift/AppKit/Python stdlib
- Architecture: HIGH — all patterns derived from direct source code analysis
- Pitfalls: HIGH — identified from actual code reading (isTemplate behavior, nil identifier handling)
- SEC-03 freshness implementation: HIGH — `os.path.getmtime()` is reliable macOS stdlib behavior

**Research date:** 2026-03-19
**Valid until:** 2026-06-19 (stable domain; no external API dependencies)
