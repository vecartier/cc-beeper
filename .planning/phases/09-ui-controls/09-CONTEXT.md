# Phase 9: UI + Controls - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a 4th button (Speak) to the existing egg shell, upgrade screen content to show state-specific information, wire up menu bar controls (YOLO, auto-speak, sounds, show/hide), and push the skeuomorphic visual quality to iOS 6–level realism. Same shell shape and size — no form factor change.

</domain>

<decisions>
## Implementation Decisions

### Button Layout
- Four buttons arranged in two pairs at the bottom of the egg (matching Figma reference screenshot)
- Left pair (outer): Deny (left) + Accept (right) — for permission handling
- Right pair (inner): Speak (left) + Go to terminal (right) — for voice and navigation
- Gap between the two pairs for visual separation
- Accept/Deny buttons dimmed when no permission is pending (existing v1.1 behavior preserved)
- Speak button shows recording state: icon swaps mic→stop, color changes to red, pulse animation active
- All buttons use existing `ActionButton` component style

### Screen Layout
- Fixed 3-row layout inside the LCD — nothing moves between states:
  1. **Top**: CLAUMAGOTCHI pixel title (fixed position)
  2. **Middle**: Character animation (fixed size, centered)
  3. **Bottom**: Status text (1-2 lines, centered)
- All three elements always present, always same alignment — only content changes per state
- Content per state:
  - **THINKING**: "Editing auth.ts · 12s" (tool name + elapsed time)
  - **DONE**: "Refactored auth, 3 files changed" (1-line AI summary — same as spoken)
  - **NEEDS YOU**: "Write · auth.ts" (tool type + truncated filename)
  - **IDLE**: "ZZZ..." or equivalent quiet message

### Skeuomorphic Quality
- Target: iOS 6–level skeuomorphism — stylized physical, not photorealistic
- Shell: deeper gradients, more realistic plastic grain, visible light reflection
- Buttons: proper 3D with shadow underneath, highlight on top, pressed state that looks pushed in
- Screen: real LCD look — slight green tint, pixel grid overlay, inner shadow like glass in a bezel, subtle backlight glow
- Drop shadow under the whole widget — it should look like a physical object sitting on the desktop
- Noise texture stays but should be more pronounced (current is 0.08 opacity — push higher)
- Rim bevel should be more dramatic
- Current v1.1 has the bones — this is about cranking depth, shadows, and texture

### Power/Hide
- Power off and hide are the same thing — one toggle, not two
- When toggled off in menu: widget disappears, monitoring stops, no sounds, no permissions
- When toggled on: widget reappears, monitoring resumes
- Menu bar icon shows a subtle indicator (dot or tint) when widget is hidden but app is running

### Menu Bar
- Grouped sections with separator lines:
  1. **Status**: session count, current state
  2. **Controls**: YOLO toggle, auto-speak toggle, sound effects toggle
  3. **App**: show/hide widget, quit
- Existing v1.1 menu items preserved and reorganized into groups

### Hotkeys
- Every button has a hotkey: Accept, Deny, Speak, Go to terminal
- Hotkey assignments are fixed (no remapping in v2.0 — deferred to future)
- Existing hotkeys (Option+A for accept, Option+D for deny) preserved

### Claude's Discretion
- Exact gradient colors and shadow values for enhanced skeuomorphism
- Pressed button animation timing and spring values
- How to truncate long tool names and file paths on the LCD
- Elapsed time format (seconds vs "12s" vs "0:12")
- Menu bar icon design for "hidden but active" state

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing UI code
- `Sources/ContentView.swift` — Current egg shell, ActionButton component, PixelTitle, NoiseView, button layout
- `Sources/ScreenView.swift` — LCD screen, pixel character sprites, displayLabel, status icons
- `Sources/ThemeManager.swift` — 9 color themes, dark mode, computed color properties
- `Sources/ClaumagotchiApp.swift` — MenuBarExtra, AppDelegate, window configuration

### Codebase maps
- `.planning/codebase/STRUCTURE.md` — File layout and responsibilities
- `.planning/codebase/CONVENTIONS.md` — Naming patterns, code style, concurrency patterns

### Design reference
- User's Figma screenshot shows target button layout: two pairs (large outer + small inner) at bottom of egg shell

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ActionButton`: Fully styled skeuomorphic button with well, face gradient, specular highlight, rim, pulse animation. Supports `active`, `pulse`, `symbol`, `iconColor` params. **Reuse directly for all 4 buttons.**
- `PixelTitle`: Canvas-drawn pixel font rendering "CLAUMAGOTCHI". Fixed position above screen. **Keep as-is.**
- `NoiseView`: Static cached NSImage noise texture (seeded RNG). **Increase opacity for more realism.**
- `Color.hexComponents`: Unified hex color parsing. **Reuse for any new colors.**

### Established Patterns
- `@EnvironmentObject` for ClaudeMonitor and ThemeManager injection
- `@Published` properties on ClaudeMonitor drive all UI updates
- UserDefaults for persistent toggles (soundEnabled, autoAccept, notificationsEnabled)
- `// MARK: -` sections for code organization
- `try?` for silent failure on file I/O

### Integration Points
- `ClaudeMonitor.state` — drives screen content (thinking/finished/needsYou/idle)
- `ClaudeMonitor.pendingPermission` — has `.tool` and `.summary` for permission details
- `ClaudeMonitor.autoAccept` — existing YOLO toggle, move to menu
- `ClaudeMonitor.soundEnabled` — existing sound toggle, move to menu
- `ClaudeMonitor.sessionCount` — for multi-session display
- `tamagotchiShell` @ViewBuilder in ContentView — isolates shell layout, good extension point
- `displayLabel` in ScreenView — replace with state-specific content logic

</code_context>

<specifics>
## Specific Ideas

- "Like my screenshot" — user provided a Figma reference showing 4 buttons in two pairs at the bottom of the egg shell. Left pair larger/outer, right pair smaller/inner.
- "Super realistic" — iOS 6 skeuomorphism level. Plastic grain, glass bezel, deep shadows, physical object feel.
- "Keep the animation, title and little description and you adapt. Ideally they're all the same size and alignment vertically, and centered so it doesn't jump" — fixed layout, content swaps per state.
- "Power off is just hidden" — no separate power state, just show/hide.

</specifics>

<deferred>
## Deferred Ideas

- Hotkey remapping — future milestone (QOL-04)
- Per-project settings — future milestone (QOL-02)

</deferred>

---

*Phase: 09-ui-controls*
*Context gathered: 2026-03-22*
