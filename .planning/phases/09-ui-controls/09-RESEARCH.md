# Phase 9: UI + Controls - Research

**Researched:** 2026-03-22
**Domain:** SwiftUI macOS — skeuomorphic widget UI, button layout, state-driven LCD content, menu bar reorganization
**Confidence:** HIGH

## Summary

This phase upgrades an existing skeuomorphic macOS widget (the Claumagotchi egg) with a fourth button (Speak), state-specific LCD screen content, enhanced skeuomorphic visual quality, and a reorganized menu bar. All the foundational machinery is already in place — `ActionButton`, `PixelTitle`, `NoiseView`, `ClaudeMonitor` state machine, and `ThemeManager`. The work is primarily about extending and refining what exists, not building new systems.

The most technically demanding parts are: (1) restructuring the button row in `ContentView` from its current conditional 2-or-3-button layout to a fixed 4-button layout in two pairs; (2) replacing the free-form `displayLabel`/`displayDetail` logic in `ScreenView` with a fixed 3-row layout that never reflows; and (3) adding two new `@Published` properties to `ClaudeMonitor` to track elapsed time and widget visibility, plus hotkeys for the two new buttons.

The codebase currently violates the SwiftUI Pro rule of multiple types per file (ContentView.swift contains `ActionButton`, `NoiseView`, `PixelTitle`, `SeededRNG`, `Color` extension all in one file). Phase 9 introduces enough new view types that the planner should split them into separate files as part of the work — this aligns with the project's own CONVENTIONS.md statement about type-per-file.

**Primary recommendation:** Extend existing components in-place; extract `ActionButton` and `PixelTitle` into their own files; add two `@Published` properties to `ClaudeMonitor`; replace `displayLabel`/`displayDetail` with a fixed `ScreenContentView`; reorganize the menu bar with `Divider()` separators.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Four buttons in two pairs at the bottom of the egg shell (matching Figma reference)
- Left pair: Deny (outer-left) + Accept (inner-left); right pair: Speak (inner-right) + Terminal (outer-right)
- Gap between the two pairs for visual separation
- Accept/Deny buttons dimmed when no permission is pending (existing behavior preserved)
- Speak button shows recording state: icon swaps mic→stop, color changes to red, pulse animation — but recording logic is Phase 10
- Fixed 3-row screen layout: CLAUMAGOTCHI title (top) → character animation (middle) → status text (bottom); nothing moves between states
- Screen content per state: THINKING = "Editing auth.ts · 12s"; DONE = "Refactored auth, 3 files changed"; NEEDS YOU = "Write · auth.ts"; IDLE = "ZZZ..." or quiet message
- iOS 6-level skeuomorphism: deeper gradients, plastic grain, glass bezel, physical buttons, drop shadow under widget
- Noise texture opacity increased beyond current 0.08
- Rim bevel more dramatic
- Power off and hide are the same toggle — one action, widget disappears AND monitoring stops
- When toggled off: no sounds, no permissions processed
- Menu bar icon shows indicator (dot or tint) when hidden-but-running
- Menu bar grouped into 3 sections with Divider(): Status (session count + state) | Controls (YOLO, auto-speak, sounds) | App (show/hide, quit)
- Existing hotkeys preserved: Option+A = accept, Option+D = deny
- All 4 buttons have hotkeys; no remapping in v2.0
- Regular floating `Window` (not NSPanel) — existing window type preserved

### Claude's Discretion
- Exact gradient colors and shadow values for enhanced skeuomorphism
- Pressed button animation timing and spring values
- How to truncate long tool names and file paths on the LCD
- Elapsed time format (e.g., "12s" vs "0:12")
- Menu bar icon design for "hidden but active" state

### Deferred Ideas (OUT OF SCOPE)
- Hotkey remapping (QOL-04)
- Per-project settings (QOL-02)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UI-01 | Screen shows state-specific content: THINKING (tool + elapsed), DONE (1-line summary), NEEDS YOU (tool + file + risk label), IDLE (character) | Fixed 3-row `ScreenContentView` driven by `ClaudeMonitor.state`; elapsed time via new `@Published var thinkingStartTime: Date?` |
| UI-02 | Four buttons below screen: Deny, Accept, Speak, Go to terminal — same egg shell, same size | Restructure button `HStack` in `ContentView`; two fixed pairs with `Spacer()` gap |
| UI-03 | Mic button shows clear recording state (color change, pulse) when voice input is active | `ActionButton` already has `active` + `pulse` + `iconColor` params; add `isRecording: Bool` binding; color override to red when recording |
| CTRL-01 | Accept pending permission via button or hotkey | Existing `respondToPermission(allow: true)` wired to Accept button — keep; add hotkey if not already present |
| CTRL-02 | Deny pending permission via button or hotkey | Existing `respondToPermission(allow: false)` wired to Deny button — keep |
| CTRL-03 | Toggle YOLO mode from menu bar | Move existing `autoAccept` toggle from inline button to menu bar Controls section |
| CTRL-04 | Power off companion (no monitoring, no sounds, no permissions) and power back on | Add `@Published var isActive: Bool` to `ClaudeMonitor`; gate all event processing on this flag; hide/show window |
| CTRL-05 | Hide widget to menu bar, restore it; hidden mode still monitors | Separate from CTRL-04; `isActive=true` but window hidden; `toggleMainWindow()` already exists |
| INFRA-02 | Every button has a keyboard shortcut | Extend `handleHotKey` in ClaudeMonitor for Speak (Option+S) and Terminal (Option+G) |
| INFRA-03 | Menu bar provides all toggles: show/hide, sounds, auto-speak, YOLO, power on/off | Reorganize `MenuBarExtra` with grouped Divider sections; add autoSpeak toggle (stub for Phase 10) |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 14+ (bundled) | All UI layout, animations, button state | Already in use throughout |
| AppKit | macOS 14+ (bundled) | NSEvent hotkeys, NSWindow control, NSSound | Already in use for global hotkeys |
| Foundation | macOS 14+ (bundled) | Timer, UserDefaults, DispatchQueue | Already in use |

No new dependencies are needed. This phase is entirely SwiftUI + AppKit on the existing SPM target.

**Installation:** None required.

### Existing Components to Reuse
| Component | File | Role in Phase 9 |
|-----------|------|-----------------|
| `ActionButton` | `ContentView.swift` | All 4 buttons — reuse as-is, extract to own file |
| `PixelTitle` | `ContentView.swift` | Title row of screen — keep exactly as-is, extract to own file |
| `NoiseView` | `ContentView.swift` | Shell texture — keep logic, increase `.opacity` from 0.08 |
| `ClaudeMonitor.respondToPermission()` | `ClaudeMonitor.swift` | Accept/Deny wiring — no change |
| `ClaudeMonitor.goToConversation()` | `ClaudeMonitor.swift` | Terminal button — no change |
| `ClaudeMonitor.handleHotKey()` | `ClaudeMonitor.swift` | Add cases for Speak + Terminal hotkeys |
| `ThemeManager` | `ThemeManager.swift` | All color values — no change |
| `toggleMainWindow()` | `ClaumagotchiApp.swift` | Show/Hide — no change |

## Architecture Patterns

### Recommended File Structure After Phase 9
```
Sources/
├── ClaumagotchiApp.swift      # @main App, MenuBarExtra (reorganized), AppDelegate
├── ClaudeMonitor.swift        # State machine + new isActive, thinkingStartTime, autoSpeak
├── ContentView.swift          # Egg shell frame, layout spine only
├── ScreenView.swift           # LCD frame + pixel grid overlay
├── ScreenContentView.swift    # NEW: fixed 3-row state-specific content
├── ActionButton.swift         # EXTRACTED from ContentView.swift
├── PixelTitle.swift           # EXTRACTED from ContentView.swift
├── NoiseView.swift            # EXTRACTED from ContentView.swift (+ SeededRNG, Color hex)
└── ThemeManager.swift         # No change
```

**Why extract:** SwiftUI Pro skill mandates each type in its own file. ContentView.swift currently has 6 types. Phase 9 adds a 7th (`ScreenContentView`). This is the right moment to split.

### Pattern 1: Fixed 3-Row Screen Layout

The current `ScreenView` has a variable-height top status row (icon row) + character + label + detail, which causes layout shifts. Replace with a fixed 3-section `VStack` where each row has a fixed height:

```swift
// ScreenContentView.swift
struct ScreenContentView: View {
    @EnvironmentObject var monitor: ClaudeMonitor
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: fixed height — always PixelTitle
            PixelTitle()
                .frame(width: 104, height: 12)
                .padding(.top, 4)

            // Row 2: fixed height — always character animation
            PixelCharacterView(state: monitor.state, frame: animFrame,
                               onColor: themeManager.lcdOn,
                               isYolo: monitor.autoAccept)
                .frame(maxWidth: .infinity)
                .frame(height: 36)

            // Row 3: fixed height — state-specific status text, never jumps
            Text(statusText)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(themeManager.lcdOn)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20)
                .padding(.bottom, 3)
        }
    }

    private var statusText: String {
        switch monitor.state {
        case .thinking:
            let tool = monitor.currentTool ?? "Working"
            let elapsed = monitor.elapsedSeconds
            return "\(truncate(tool, to: 10)) · \(elapsed)s"
        case .finished:
            return monitor.lastSummary ?? "Done"
        case .needsYou:
            if let p = monitor.pendingPermission {
                return "\(p.tool) · \(truncateFilename(p.summary))"
            }
            return "NEEDS YOU!"
        case .idle:
            return "ZZZ..."
        }
    }

    private func truncate(_ s: String, to n: Int) -> String {
        s.count <= n ? s : String(s.prefix(n - 1)) + "…"
    }

    private func truncateFilename(_ s: String) -> String {
        // Keep last path component if it's a path
        let last = s.split(separator: "/").last.map(String.init) ?? s
        return truncate(last, to: 12)
    }
}
```

### Pattern 2: Fixed 4-Button Row

Current layout conditionally renders 2 or 3 buttons based on `autoAccept` state. Replace with a fixed 4-button `HStack` with a gap spacer:

```swift
// In ContentView.swift (button section)
HStack(alignment: .center, spacing: 0) {
    // Left pair
    ActionButton(symbol: "xmark", size: 11, iconColor: .white,
                 active: monitor.state.needsAttention) {
        monitor.respondToPermission(allow: false)
    }
    .accessibilityLabel("Deny permission")

    ActionButton(symbol: "checkmark", size: 11, iconColor: .white,
                 active: monitor.state.needsAttention,
                 pulse: monitor.state.needsAttention) {
        monitor.respondToPermission(allow: true)
    }
    .accessibilityLabel("Accept permission")

    Spacer().frame(width: 10) // visual gap between pairs

    // Right pair
    ActionButton(symbol: monitor.isRecording ? "stop.fill" : "mic.fill",
                 size: 11,
                 iconColor: monitor.isRecording ? .red : .white,
                 active: true,
                 pulse: monitor.isRecording) {
        // Phase 10 wires recording logic; stub here
    }
    .accessibilityLabel(monitor.isRecording ? "Stop recording" : "Speak")

    ActionButton(symbol: "arrow.up.forward", size: 11, iconColor: .white,
                 active: monitor.state.canGoToConvo || monitor.state.needsAttention) {
        monitor.goToConversation()
    }
    .accessibilityLabel("Go to terminal")
}
.frame(height: 36)
```

**Key change:** Remove the `if monitor.autoAccept` branch from button layout. YOLO mode affects _permission handling_ in `ClaudeMonitor`, not button visibility. All 4 buttons are always visible.

### Pattern 3: ClaudeMonitor New Properties

Three new `@Published` properties are needed:

```swift
// In ClaudeMonitor.swift

/// Controls whether the widget is active. False = hidden + monitoring stopped.
@Published var isActive: Bool = true {
    didSet {
        UserDefaults.standard.set(isActive, forKey: "isActive")
        if isActive {
            setupFileWatcher()
            setupGlobalHotkeys()
        } else {
            source?.cancel(); source = nil
            try? fileHandle?.close(); fileHandle = nil
            idleWork?.cancel()
            state = .idle
            pendingPermission = nil
        }
    }
}

/// When THINKING started — drives elapsed time display in UI-01.
@Published var thinkingStartTime: Date? = nil

/// Last summary text written by the stop hook (Phase 11 populates this;
/// Phase 9 reads it as optional, showing "Done" if nil).
@Published var lastSummary: String? = nil

/// Current tool name being used — populated from pre_tool events.
@Published var currentTool: String? = nil

/// Computed: seconds elapsed since thinking started.
var elapsedSeconds: Int {
    guard let start = thinkingStartTime else { return 0 }
    return Int(Date().timeIntervalSince(start))
}

/// Whether voice is recording (Phase 10 sets this; Phase 9 reads it for UI-03).
@Published var isRecording: Bool = false

/// Whether auto-speak is enabled (Phase 11 uses this).
@Published var autoSpeak: Bool = false {
    didSet { UserDefaults.standard.set(autoSpeak, forKey: "autoSpeak") }
}
```

**Timer for elapsed seconds:** `ScreenContentView` needs a 1-second timer to refresh the elapsed time display. Use `Timer.publish(every: 1, on: .main, in: .common).autoconnect()` in `ScreenContentView`, identical to the existing animation timer in `ScreenView`.

### Pattern 4: Menu Bar Reorganization

```swift
MenuBarExtra {
    // SECTION 1: Status
    Text("Sessions: \(monitor.sessionCount)")
    Text(monitor.autoAccept ? "YOLO MODE" : monitor.state.label)

    Divider()

    // SECTION 2: Controls
    Toggle("YOLO Mode", isOn: $monitor.autoAccept)
        .keyboardShortcut("y")
    Toggle("Auto-Speak", isOn: $monitor.autoSpeak)
        .keyboardShortcut("k")
    Toggle("Sound Effects", isOn: $monitor.soundEnabled)
        .keyboardShortcut("s")

    Divider()

    // SECTION 3: App
    Button(monitor.isActive ? "Power Off" : "Power On") {
        monitor.isActive.toggle()
        if !monitor.isActive {
            ClaumagotchiApp.hideMainWindow()
        } else {
            ClaumagotchiApp.showMainWindow()
        }
    }
    .keyboardShortcut("p")

    Button("Show / Hide Widget") { ClaumagotchiApp.toggleMainWindow() }
        .keyboardShortcut("h", modifiers: [.command, .shift])

    Divider()

    Button("Quit") { NSApp.terminate(nil) }
        .keyboardShortcut("q")
} label: {
    Image(nsImage: EggIcon.image(state: monitor.menuBarIconState))
}
```

**Note on Power Off vs Hide:** CTRL-04 (power off = monitoring stops) and CTRL-05 (hide = monitoring continues) are two different concepts. The menu needs two items: "Power Off / On" and "Show / Hide Widget". The CONTEXT.md says "Power off is just hidden" — meaning the widget UI hides, but the distinction from hide-only is that monitoring stops. Implement as: power-off hides window AND sets `isActive = false`; show/hide toggles window visibility with `isActive` unchanged.

### Pattern 5: Hotkey Extension

Current `handleHotKey` only acts when `pendingPermission != nil`. Expand scope:

```swift
private func handleHotKey(_ event: NSEvent) {
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard flags == .option else { return }
    switch event.keyCode {
    case 0:  // kVK_ANSI_A — Accept
        guard pendingPermission != nil else { return }
        DispatchQueue.main.async { self.respondToPermission(allow: true) }
    case 2:  // kVK_ANSI_D — Deny
        guard pendingPermission != nil else { return }
        DispatchQueue.main.async { self.respondToPermission(allow: false) }
    case 1:  // kVK_ANSI_S — Speak (stub; Phase 10 wires actual recording)
        DispatchQueue.main.async { self.isRecording.toggle() }
    case 5:  // kVK_ANSI_G — Go to terminal
        DispatchQueue.main.async { self.goToConversation() }
    default:
        break
    }
}
```

**Key codes verified:** `kVK_ANSI_S = 1`, `kVK_ANSI_G = 5` (Carbon/HIToolbox keycodes, not ASCII).

### Pattern 6: Skeuomorphism Enhancements

The existing `ContentView` has the right structure. Enhancements are value tweaks:

| Element | Current | Target |
|---------|---------|--------|
| Noise opacity | 0.08 | 0.14–0.18 |
| Drop shadow blur | `blur(radius: 20)`, opacity 0.3 | `blur(radius: 28)`, opacity 0.45, `offset(y: 10)` |
| Shell gradient stops | 4 stops | Keep 4 stops; increase contrast between top and bottom |
| Rim bevel line width | 1.5 | 2.0; increase white opacity at top-leading |
| Button well depth | `black.opacity(0.25)`, blur 1 | `black.opacity(0.35)`, blur 1.5 |
| Button specular | `white.opacity(0.4)` | `white.opacity(0.55)` |
| Screen inner shadow | Top stroke 0.6 opacity | Top stroke 0.7, also add outer bezel ring |

**Pressed state for ActionButton:** Currently `ActionButton` has no pressed visual. Add using `.buttonStyle` with `@Environment(\.isPressed)` or a `PressedButtonStyle`:

```swift
// In ActionButton or a new PressedButtonStyle.swift
struct SkeuomorphicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
```

Apply: `.buttonStyle(SkeuomorphicButtonStyle())` inside `ActionButton`.

### Anti-Patterns to Avoid

- **Conditional button visibility based on YOLO mode:** The current v1.1 layout swaps between 2 and 3 buttons when `autoAccept` changes. Phase 9 removes this — 4 buttons are always visible. YOLO affects behavior in `ClaudeMonitor`, not UI structure.
- **Layout-shifting status text:** Using a `.frame(height:)` without `minHeight:` lets text push adjacent elements. Always use `minHeight` + `maxHeight` fixed constraints on the status row.
- **Storing `isActive` window control in the view:** Window show/hide must go through `NSApp.windows` (as `toggleMainWindow()` already does), not a SwiftUI state bool. The `isActive` bool in `ClaudeMonitor` controls monitoring only; window visibility is a side effect triggered in the menu action.
- **Adding `globalKeyMonitor` when already set:** `setupGlobalHotkeys()` already guards with `guard globalKeyMonitor == nil`. Calling it from `isActive.didSet` is safe. But when `isActive = false`, also remove monitors to stop responding to hotkeys.
- **Using `animation(_:)` without value:** The existing code uses `.animation(.easeInOut(duration: 0.3), value: monitor.state)` — this is correct. Don't add bare `.animation(_:)` modifier without a value.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pressed button state | Custom `@State var isPressed` + gesture | `ButtonStyle` with `configuration.isPressed` | Built into SwiftUI, handles all edge cases |
| Elapsed time counter | A separate `Timer` manager class | `Timer.publish().autoconnect()` in `ScreenContentView` | Already the pattern used by the animation timer |
| Window show/hide | Modify `NSWindow` from view body | `NSApp.windows.first(where:)` in App-level static func | Already done in `toggleMainWindow()` |
| Hotkey key codes | Hardcoded integers | Use named Carbon constants or comments documenting the values | Maintainability |
| Text truncation | Third-party library | Swift's `String.prefix()` + `"…"` suffix | Simple problem, keep it inline |

**Key insight:** Every capability needed in this phase already exists in either SwiftUI standard library or the existing codebase. The risk of over-engineering is higher than the risk of under-building.

## Common Pitfalls

### Pitfall 1: Menu Bar Toggle Binding Requires `@Binding` Not Direct Property Access
**What goes wrong:** `Toggle("YOLO Mode", isOn: $monitor.autoAccept)` requires `monitor` to be a `@StateObject` or `@ObservedObject` at the `ClaumagotchiApp` level. Since the `App` struct uses `@StateObject`, `$monitor.autoAccept` should work. But if `monitor` is passed via environment or as a let, the `$` projection won't exist.
**Why it happens:** `MenuBarExtra` content in `App.body` has direct access to `@StateObject` bindings.
**How to avoid:** Use `Toggle("YOLO Mode", isOn: $monitor.autoAccept)` — valid because `monitor` is `@StateObject` in `ClaumagotchiApp`. For `ClaudeMonitor` which uses `@Published` + `ObservableObject`, `$monitor.property` binding works correctly.
**Warning signs:** Compiler error "value of type 'ClaudeMonitor' has no member '$autoAccept'"

### Pitfall 2: `isActive` didSet Calling `setupFileWatcher()` When File Handle Already Open
**What goes wrong:** If `isActive` is toggled on and `setupFileWatcher()` is called while a file handle is still open from a previous session, two watchers coexist.
**Why it happens:** `fileHandle` is only nil'd in the deactivation path.
**How to avoid:** In the `isActive = true` path, call `restartFileWatcher()` rather than `setupFileWatcher()` directly, or guard with `guard source == nil`.

### Pitfall 3: Button Layout Height Overflow Clipping Buttons
**What goes wrong:** The egg shell clips at `shellH: 224`. The current button row has `.offset(y: -8)`. Adding a 4th button without adjusting the overall layout can push buttons outside the clipping ellipse.
**Why it happens:** `Ellipse().clipShape()` is not used on the button area — the shell is a decorative background, not a clip path. But the 4-button row may need more horizontal space than 3 buttons at `buttonSize: 28`.
**How to avoid:** Calculate total button row width: 4 × 32px (frameSize) + 3 × 5px (spacing) + 10px (pair gap) = 153px. Shell width is 186px — fits comfortably. Verify with a build before finalizing spacing values.

### Pitfall 4: ScreenView Still Owns the PixelTitle (Layout Duplication)
**What goes wrong:** `ContentView` currently places `PixelTitle()` above the `ScreenView` ZStack. The CONTEXT says the fixed 3-row layout puts the title inside the LCD. Moving `PixelTitle` inside the screen means removing it from `ContentView` and placing it in `ScreenContentView`. If both are left in place, the title appears twice.
**Why it happens:** The CONTEXT's fixed layout description says "Top: CLAUMAGOTCHI pixel title" as the first of 3 rows inside the LCD — but current code has it outside the LCD entirely.
**How to avoid:** Decide definitively: keep title outside LCD (current position, simpler) or move it inside the LCD (matches CONTEXT description). The research recommendation is to keep it outside — it's already well-positioned and moving it inside reduces character animation space. Flag this for explicit planner decision.

### Pitfall 5: Elapsed Time Only Updates When View Re-renders
**What goes wrong:** `monitor.elapsedSeconds` is a computed property — it recalculates from `Date()` when read, but `ScreenContentView` won't re-render unless something `@Published` changes. A `Timer` in the view is required.
**Why it happens:** Computed properties don't trigger SwiftUI observation — only `@Published` changes do.
**How to avoid:** Add a `@State private var tick = 0` updated by a 1-second `onReceive(timer)` that forces a re-render. The actual value comes from `monitor.thinkingStartTime`. Do NOT make `elapsedSeconds` `@Published` (it would publish every second to all observers).

### Pitfall 6: Global Hotkey Monitor Must Be Removed When isActive = false
**What goes wrong:** If the widget is powered off but hotkeys remain active, pressing Option+A still calls `respondToPermission(allow: true)` which attempts to process a permission when monitoring is stopped.
**Why it happens:** `deinit` removes monitors, but `isActive = false` doesn't currently deinit the class.
**How to avoid:** In the `isActive = false` path of `didSet`, remove monitors explicitly: `if let m = globalKeyMonitor { NSEvent.removeMonitor(m); globalKeyMonitor = nil }`.

## Code Examples

### Elapsed Time Display (verified pattern — Timer.publish already used in ScreenView)
```swift
// In ScreenContentView.swift
private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
@State private var tick = 0

// In body:
.onReceive(ticker) { _ in tick += 1 }
// statusText computed property reads monitor.thinkingStartTime + Date() — always fresh
```

### ButtonStyle for Pressed State (SwiftUI built-in)
```swift
// In SkeuomorphicButtonStyle.swift
struct SkeuomorphicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
```

### Window Hide Without Quitting
```swift
// In ClaumagotchiApp.swift
static func hideMainWindow() {
    for window in NSApp.windows where window.identifier?.rawValue == "main" {
        window.orderOut(nil)
        return
    }
}
```

### Menu Bar Icon with "Hidden" Indicator
```swift
// Add new EggIconState case
enum EggIconState {
    case normal
    case attention
    case yolo
    case hidden    // NEW: app running but widget not visible
}

// In EggIcon.image():
case .hidden:
    // Render same egg but lighter / ghosted
    NSColor.gray.withAlphaComponent(0.5).setFill()
```

### ScreenContentView — thinkingStartTime Population
```swift
// In ClaudeMonitor.processEvent(), pre_tool case:
case "pre_tool", "post_tool":
    let tool = event["tool"] as? String
    if let tool { currentTool = tool }
    if sessionStates[sid] != .thinking {
        thinkingStartTime = Date()  // Only set when transitioning to thinking
    }
    sessionStates[sid] = .thinking
    updateAggregateState()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro + `@State`/`@Bindable` | Swift 5.9 / iOS 17 | The existing codebase uses the old approach; it works on macOS 14 and is lower risk to keep than migrate in this phase |
| `PreviewProvider` | `#Preview` macro | Swift 5.9 | Use `#Preview` for any new previews added |
| Conditional button layout (v1.1) | Fixed 4-button layout (v2.0) | This phase | Eliminates layout jump when YOLO mode toggles |

**Note on Observable migration:** The SwiftUI Pro skill strongly prefers `@Observable` over `ObservableObject`. However, migrating `ClaudeMonitor` and `ThemeManager` in this phase would be a large, risky refactor on top of UI work. The recommendation is to keep `ObservableObject`/`@Published` for this phase and migrate in a dedicated refactor phase if desired. Flag this as a known deviation from the skill guideline.

## Open Questions

1. **Pixel title inside vs outside the LCD screen**
   - What we know: CONTEXT says "Top: CLAUMAGOTCHI pixel title" as the first row of the fixed 3-row layout inside the LCD. Current code places it outside the LCD, above the screen frame.
   - What's unclear: Moving it inside the LCD significantly reduces character animation height (88px screen, minus title row, minus status row, leaves ~50px for character).
   - Recommendation: Keep title outside LCD (current position). Change the "3 rows" to mean: title (above screen, fixed) + character (inside screen) + status text (inside screen, bottom). This preserves character animation space. Planner should decide explicitly.

2. **`lastSummary` population timing**
   - What we know: Phase 11 adds the Python hook that writes `last_summary.txt`. Phase 9 needs to display it in the DONE state.
   - What's unclear: If Phase 9 ships before Phase 11, the DONE state will always show "Done" (the nil fallback).
   - Recommendation: Wire the file read in Phase 9 as a stub — `ClaudeMonitor` reads `~/.claude/claumagotchi/last_summary.txt` on each `stop` event. If file doesn't exist, shows "Done". This is safe and forward-compatible.

3. **Auto-speak toggle in Phase 9**
   - What we know: INFRA-03 requires the menu bar toggle for auto-speak. Phase 10 implements the actual recording logic.
   - What's unclear: Should the toggle do anything in Phase 9 besides persist the preference?
   - Recommendation: Add `autoSpeak: Bool` to `ClaudeMonitor` with UserDefaults persistence. Show it in the menu bar. It will be wired to actual behavior in Phase 11. This is standard "build the plumbing now."

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no Swift test target in Package.swift |
| Config file | None — Wave 0 must add a test target |
| Quick run command | `swift test --filter ClaumagotchiTests` (after Wave 0 setup) |
| Full suite command | `swift test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-01 | `statusText` returns correct string per state | unit | `swift test --filter ScreenContentTests` | Wave 0 |
| UI-02 | 4 buttons always rendered regardless of YOLO state | manual-only | Visual inspection on build | N/A |
| UI-03 | Speak button color/icon changes when `isRecording = true` | manual-only | Visual inspection | N/A |
| CTRL-01 | `respondToPermission(allow: true)` clears pending permission | unit | `swift test --filter MonitorTests/testAccept` | Wave 0 |
| CTRL-02 | `respondToPermission(allow: false)` clears pending permission | unit | `swift test --filter MonitorTests/testDeny` | Wave 0 |
| CTRL-03 | `autoAccept` persists to UserDefaults | unit | `swift test --filter MonitorTests/testYOLOPersistence` | Wave 0 |
| CTRL-04 | `isActive = false` cancels file watcher and clears state | unit | `swift test --filter MonitorTests/testPowerOff` | Wave 0 |
| CTRL-05 | Window hide/show does not change `isActive` | manual-only | Visual inspection | N/A |
| INFRA-02 | Option+S toggles `isRecording`; Option+G calls `goToConversation` | unit | `swift test --filter HotkeyTests` | Wave 0 |
| INFRA-03 | Menu bar renders all 5 toggles/sections | manual-only | Visual inspection | N/A |

### Sampling Rate
- **Per task commit:** Build succeeds (`swift build`)
- **Per wave merge:** `swift test` (after Wave 0 adds test target)
- **Phase gate:** All manual-only checks pass + build clean before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Add Swift test target to `Package.swift`
- [ ] `Tests/ClaumagotchiTests/MonitorTests.swift` — covers CTRL-01 through CTRL-04, INFRA-02
- [ ] `Tests/ClaumagotchiTests/ScreenContentTests.swift` — covers UI-01 statusText logic
- [ ] No shared fixtures needed (pure logic tests on ClaudeMonitor)

## Sources

### Primary (HIGH confidence)
- Direct codebase read: `ContentView.swift`, `ScreenView.swift`, `ClaudeMonitor.swift`, `ClaumagotchiApp.swift`, `ThemeManager.swift` — all findings based on actual source
- `Package.swift` — verified macOS 14 target, Swift 5.10, no test target
- `.planning/codebase/CONVENTIONS.md` — verified conventions
- `.planning/phases/09-ui-controls/09-CONTEXT.md` — locked decisions and discretion areas
- SwiftUI Pro skill (`~/.claude/skills/swiftui-pro/references/views.md`, `data.md`, `accessibility.md`) — coding standards

### Secondary (MEDIUM confidence)
- Carbon key code values (kVK_ANSI_S = 1, kVK_ANSI_G = 5) — from training data; validate in HIToolbox.h if in doubt
- `ButtonStyle.configuration.isPressed` availability on macOS 14 — standard SwiftUI API, well established

### Tertiary (LOW confidence)
- Specific shadow/gradient numeric values for "iOS 6 skeuomorphism" target aesthetic — subjective, left to Claude's discretion per CONTEXT

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; existing codebase fully read
- Architecture: HIGH — all patterns derived directly from existing code; no speculation
- Pitfalls: HIGH — derived from reading actual code paths (e.g., the `globalKeyMonitor == nil` guard, the `autoAccept` button layout branch)
- Aesthetic values (gradient/shadow numbers): LOW — subjective, left to discretion

**Research date:** 2026-03-22
**Valid until:** 2026-04-22 (stable SwiftUI macOS APIs; 30-day window)
