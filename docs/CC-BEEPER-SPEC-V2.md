# CC-Beeper Pre-Launch Spec v2

**Version target:** v4.0
**Scope:** 9 items. No Switchboard, no bundled hooks, no separate products.
**Principle:** CC-Beeper is a monitoring layer with one config feature (permission mode). It does not manage hooks, edit CLAUDE.md, or own Claude Code's behavior.

---

## 1. Permission Spectrum in Popover

### What
A segmented control in the popover that lets users switch Claude Code's permission mode without editing JSON.

### Four positions

| Mode | Behavior | settings.json value |
|------|----------|-------------------|
| **Cautious** | Approve everything manually | `"permission_mode": "default"` |
| **Guided** | Claude auto-proceeds on safe operations | `"permission_mode": "plan"` |
| **Guarded YOLO** | Auto-approve everything, but deny-list still applies | `"permission_mode": "bypass"` + deny rules preserved |
| **Full YOLO** | Auto-approve everything, no restrictions | `"permission_mode": "bypass"` + deny rules cleared |

### Behavior

- Reads current mode from `~/.claude/settings.json` on popover open.
- Writes `permission_mode` on user selection. For Guarded YOLO vs Full YOLO, the difference is whether existing `deny` rules in settings.json are preserved or cleared.
- On mode change, LCD shows a toast: **"RESTART SESSION TO APPLY"** for 5 seconds, then returns to current state.
- **Preview before commit:** When the user selects a new mode, show a brief summary of what changes before writing. Example: "This will set permission_mode to bypass and preserve your deny rules."

### Guided mode availability

There is no reliable way for CC-Beeper to detect whether the user is on a Teams/Enterprise plan. `~/.claude/settings.json` does not contain plan information, and there is no local API to check.

**Approach:** Always show Guided as selectable. When the user selects it, show an info note: "Guided mode requires a Teams or Enterprise plan. If you're not on one, Claude Code will fall back to default behavior." Write the setting regardless — Claude Code itself will handle the fallback if the plan doesn't support it. CC-Beeper does not gatekeep.

### YOLO sunglasses

- When mode is Guarded YOLO or Full YOLO, the beeper character renders with pixel sunglasses over its eyes.
- Sunglasses appear/disappear with a brief slide-down animation on mode change.
- Persist across all LCD states while in YOLO mode.
- Pixel art style consistent with the beeper's existing aesthetic.

### settings.json read/write details

**Reading:**
```
1. Check if ~/.claude/settings.json exists
2. If missing → default to Cautious, do not create the file
3. If exists → parse JSON
4. If parse fails (malformed JSON) → show warning in popover: "settings.json is malformed — fix it manually before changing modes." Disable the segmented control.
5. Read "permission_mode" field:
   - "default" or missing → Cautious
   - "plan" → Guided
   - "bypass" → check deny rules to determine Guarded vs Full YOLO
6. If "permission_mode" has an unrecognized value → show as-is with a note: "Unknown mode: {value}. Changing will overwrite it."
```

**Writing:**
```
1. Read current file contents
2. Parse JSON
3. Modify only the "permission_mode" field (and deny rules for Full YOLO)
4. Preserve all other fields exactly as they are
5. Write atomically: write to ~/.claude/settings.json.tmp, then rename to settings.json
6. Do NOT pretty-print or reformat — preserve the user's formatting if possible (use a JSON library that supports round-trip editing, or read/write as string with targeted replacement)
```

**Guarded YOLO vs Full YOLO — deny rule handling:**
- Guarded YOLO: set `permission_mode` to `"bypass"`, leave `deny` array untouched.
- Full YOLO: set `permission_mode` to `"bypass"`, clear `deny` array. Before clearing, cache the previous deny rules in `~/.cc-beeper/cached-deny-rules.json` so they can be restored when switching back to a non-YOLO mode.
- Switching from Full YOLO to Cautious/Guided/Guarded: restore deny rules from cache if available.

---

## 2. Input vs Permission Differentiation

### The problem

Claude Code surfaces different kinds of prompts that require user attention. In YOLO/bypass mode, tool permission prompts are auto-approved — but other prompt types (questions, discussions, multiple choice) are NOT permissions and must always be surfaced to the user.

If CC-Beeper treats all prompts the same, YOLO users either see false NEEDS INPUT signals for auto-approved permissions, or miss actual questions from Claude.

### Claude Code prompt types — full classification

**Permission prompts (suppressible in YOLO mode):**

These are tool approval requests. In bypass mode, Claude Code auto-approves them. CC-Beeper should NOT show these as NEEDS INPUT when in Guarded YOLO or Full YOLO.

| Prompt type | Example | Hook event |
|-------------|---------|------------|
| Tool approval | "Allow Claude to run `npm test`?" | Notification with tool permission context |
| File write approval | "Allow Claude to write to `src/index.ts`?" | Notification with write permission context |
| Bash command approval | "Allow Claude to execute `rm -rf dist`?" | Notification with bash permission context |

**Input prompts (NEVER suppressible, regardless of mode):**

These are Claude asking the user a question. They are not permissions. CC-Beeper must always show NEEDS INPUT for these.

| Prompt type | What it is | Example |
|-------------|-----------|---------|
| `gsd` | Claude asking whether to proceed with an approach | "Should I refactor the auth module or patch the existing code?" |
| `discuss` | Claude presenting analysis and asking for direction | "I found three potential issues. Which should I prioritize?" |
| `multiple_choice` | Claude offering discrete options | "A) Add a new endpoint, B) Modify the existing one, C) Both" |
| `wcv` | "Would you like me to continue/verify" prompts | "Would you like me to continue with the remaining files?" |
| Free-form question | Claude needs information it doesn't have | "Which database should I connect to?", "What's the API key name?" |

### Detection logic

Claude Code Notification events are delivered as JSON via the HTTP hook. The payload structure for notifications:

```json
{
  "event": "Notification",
  "data": {
    "type": "...",
    "title": "...",
    "message": "...",
    "options": [...]
  }
}
```

CC-Beeper must examine the `data.type` field (and potentially `data.title` or `data.message` as fallback) to classify the notification.

**IMPORTANT: The exact field names and type values depend on Claude Code's actual Notification payload schema, which may change between versions. Before implementing, inspect real Notification payloads by logging the full JSON body from the HTTP hook during a test session. The classification logic below uses assumed type values — replace with actual values from payload inspection.**

### Classification logic (pseudocode)

```
function classifyNotification(payload):
    type = payload.data.type

    // Known permission types — suppressible in YOLO
    if type in ["permission", "permissionRequest", "tool_approval"]:
        return .permission

    // Known input types — never suppressible
    if type in ["question", "input", "gsd", "discuss", "multiple_choice", "wcv"]:
        return .input

    // Auth events — transient LCD flash, not a state
    if type in ["authSuccess", "auth_success"]:
        return .authSuccess
    if type in ["authError", "auth_error"]:
        return .authError

    // UNKNOWN TYPE — default to showing it
    // Safe default: assume it needs user attention
    return .input
```

### Key rule: unknown types default to visible

If Claude Code introduces a new notification type that CC-Beeper doesn't recognize, CC-Beeper must show it as NEEDS INPUT. Suppressing an unknown type risks hiding something the user needs to see. False positives (showing something that didn't need attention) are annoying. False negatives (hiding something that needed attention) break trust.

### LCD display rules by mode

| Mode | Permission notification | Input notification | Unknown notification |
|------|------------------------|-------------------|---------------------|
| Cautious | Show **APPROVE?** | Show **NEEDS INPUT** | Show **NEEDS INPUT** |
| Guided | Show **APPROVE?** (non-safe ops) | Show **NEEDS INPUT** | Show **NEEDS INPUT** |
| Guarded YOLO | Suppress | Show **NEEDS INPUT** | Show **NEEDS INPUT** |
| Full YOLO | Suppress | Show **NEEDS INPUT** | Show **NEEDS INPUT** |

---

## 3. HTTP Hooks Migration

### What
Replace the current IPC pipeline (Python script → writes JSONL file → kqueue file watcher picks up changes) with a direct HTTP connection (Claude Code → HTTP POST → CC-Beeper's local server).

### Why
- Eliminates three moving parts (Python runtime, JSONL file, file watcher).
- Lower latency — no filesystem round-trip.
- Cleaner error handling — HTTP status codes vs file parse failures.
- Aligns with Anthropic's preferred direction for hook communication.

### Architecture

```
Claude Code hook fires
        │
        ▼
Hook script reads JSON from stdin, POSTs to CC-Beeper
        │
        ▼
CC-Beeper HTTP server (localhost only)
        │
        ▼
Route by event type → update LCD state machine
```

### HTTP Server

**Framework:** Use `Network.framework` `NWListener` — it's lightweight, built into macOS, no dependencies. Do not use Vapor or Swifter — too heavy for a menu bar app that handles ~1-5 requests per second.

**Port selection:**
1. Attempt to bind to fixed port `19222`.
2. If port is taken (another CC-Beeper instance, or unrelated service), try ports `19223` through `19230`.
3. If all fail, bind to port `0` (OS assigns a random available port).
4. Write the active port to `~/.cc-beeper/port` (plain text, just the number).
5. On app quit, delete `~/.cc-beeper/port`.

**Multiple instances:** If CC-Beeper detects `~/.cc-beeper/port` already exists on launch, attempt to ping that port. If it responds, show: "Another CC-Beeper instance is already running." and quit. If it doesn't respond (stale file from a crash), delete the file and proceed.

**Endpoints:**

Single endpoint: `POST /hook`

The event type is determined from the JSON body, not the URL path. Rationale: the hook command in settings.json is simpler (one URL for all hooks), and routing by URL would require different hook commands per event type, adding complexity to settings.json management.

**Request handling:**
```
1. Accept POST to /hook
2. Read body as UTF-8 string
3. Parse JSON
4. Extract event type from top-level "event" field (or equivalent — see §3 Payload Schemas)
5. Route to LCD state machine
6. Return 200 OK with empty body (CC-Beeper never sends instructions back to Claude Code)
7. If parse fails → log error, return 400, do nothing to LCD
8. If unknown event type → log it, return 200, do nothing to LCD
```

**Security:** Bound to `localhost` only (`NWParameters` with `requiredLocalEndpoint` set to `127.0.0.1`). No authentication needed — localhost traffic only.

### Hook command — fixing the stdin piping issue

The v1 spec used `$(cat)` inside double quotes in the `-d` flag, which breaks on payloads containing quotes, newlines, backslashes, or dollar signs. Real Claude Code payloads will contain all of these.

**Correct approach — pipe stdin directly to curl:**

```bash
cat | curl -s -o /dev/null -X POST "http://localhost:$(cat ~/.cc-beeper/port)/hook" \
  -H "Content-Type: application/json" \
  -d @- \
  --max-time 3 || true
```

**Problem:** This uses `cat` twice — once for piping stdin and once for reading the port file. They'll conflict.

**Correct approach — read port first, then pipe:**

```bash
#!/bin/bash
PORT=$(cat ~/.cc-beeper/port 2>/dev/null || echo "19222")
curl -s -o /dev/null -X POST "http://localhost:${PORT}/hook" \
  -H "Content-Type: application/json" \
  -d @- \
  --max-time 3 || true
```

Here `curl -d @-` reads the JSON body from stdin (which is the hook payload from Claude Code). The port file is read separately into a variable first.

**`-o /dev/null`** suppresses all curl output to stdout, preventing the false "Hook Error" labels described in §5e.

**`|| true`** ensures the hook script always exits 0, even if curl fails (CC-Beeper not running, port file missing, timeout). Claude Code sees a successful hook and continues.

### Hook Payload Schemas

These are the JSON structures CC-Beeper receives on `POST /hook`. Each hook type wraps the payload differently.

**IMPORTANT: These schemas are based on Claude Code's documented hook behavior as of March 2026. Field names may change. Log raw payloads during development to verify.**

**PreToolUse:**
```json
{
  "hook_type": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  },
  "session_id": "...",
  "transcript_path": "..."
}
```

**PostToolUse:**
```json
{
  "hook_type": "PostToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  },
  "tool_output": "...",
  "session_id": "...",
  "transcript_path": "..."
}
```

**Notification:**
```json
{
  "hook_type": "Notification",
  "notification": {
    "type": "permissionRequest | question | ...",
    "title": "...",
    "message": "...",
    "options": ["..."]
  },
  "session_id": "..."
}
```

**Stop:**
```json
{
  "hook_type": "Stop",
  "stop_reason": "completed",
  "session_id": "...",
  "transcript_path": "..."
}
```

**StopFailure:**
```json
{
  "hook_type": "StopFailure",
  "error": "rate_limit | connection_error | ...",
  "message": "...",
  "session_id": "..."
}
```

**Routing logic in CC-Beeper's HTTP handler:**
```
switch payload.hook_type:
  "PreToolUse"   → LCD state = WORKING, context = payload.tool_name
  "PostToolUse"  → (optional: log tool result, keep LCD on WORKING)
  "Notification" → classify per §2, set LCD to APPROVE? or NEEDS INPUT
  "Stop"         → LCD state = DONE, auto-transition to IDLE after 3s
  "StopFailure"  → LCD state = ERROR, persist until next event
  unknown        → log warning, ignore
```

### Hook registration in settings.json

CC-Beeper writes these hook entries during onboarding (§7):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "command": "PORT=$(cat ~/.cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true",
        "async": true,
        "timeout": 5000,
        "statusMessage": "CC-Beeper monitoring…"
      }
    ],
    "PostToolUse": [
      {
        "command": "PORT=$(cat ~/.cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true",
        "async": true,
        "timeout": 5000
      }
    ],
    "Notification": [
      {
        "command": "PORT=$(cat ~/.cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true",
        "async": true,
        "timeout": 5000
      }
    ],
    "Stop": [
      {
        "command": "PORT=$(cat ~/.cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true",
        "async": true,
        "timeout": 5000
      }
    ],
    "StopFailure": [
      {
        "command": "PORT=$(cat ~/.cc-beeper/port 2>/dev/null || echo 19222) && curl -s -o /dev/null -X POST http://localhost:${PORT}/hook -H 'Content-Type: application/json' -d @- --max-time 3 || true",
        "async": true,
        "timeout": 5000
      }
    ]
  }
}
```

### Identifying CC-Beeper hooks in settings.json

CC-Beeper needs to distinguish its own hooks from user-written hooks (to update/migrate its hooks without touching user hooks).

**Approach:** CC-Beeper identifies its hooks by matching the command string pattern. Specifically, any hook command containing `cc-beeper/port` is a CC-Beeper hook. This is simpler and more robust than adding a comment field (JSON doesn't support comments) or a custom metadata field (Claude Code might reject unknown fields).

### Migration path
- v4.0 ships with HTTP hooks as default.
- On first launch after update, CC-Beeper scans settings.json for hooks containing the old Python/JSONL pattern (e.g., matching on the old script filename or JSONL path).
- If found: prompt "CC-Beeper now uses HTTP hooks (faster, more reliable). Migrate now?" → replace old hook entries with new HTTP entries.
- If not found but CC-Beeper HTTP hooks also missing: treat as fresh install, go through onboarding.
- Old Python script and JSONL watcher code are removed from the codebase.

### Uninstall / cleanup

If a user removes CC-Beeper without cleaning up, the hook entries in settings.json will still fire `curl` commands to a non-running server. These will:
- Timeout after 3 seconds (the `--max-time 3` flag)
- Exit silently due to `|| true`
- Produce no stdout (due to `-o /dev/null`)
- Be marked `async: true` so Claude Code doesn't wait

**Impact of orphaned hooks:** Each hook type fires a curl that times out after 3s. With 5 hook types, worst case is 5 background curl processes timing out per tool use. This is not great but not catastrophic — no user-visible effect, no Claude Code slowdown (async), no error messages.

**Mitigation:** Add an "Uninstall CC-Beeper Hooks" button in the app's Preferences/About section. This removes all CC-Beeper hook entries from settings.json. The README should also document manual cleanup:

```bash
# Remove CC-Beeper hooks from settings.json
# Open ~/.claude/settings.json and remove all hook entries containing "cc-beeper/port"
```

---

## 4. LCD State Expansion

### Current states (v3.1)
- IDLE
- THINKING
- WORKING
- NEEDS YOU

### New states (v4.0)

| State | Trigger | LCD text | Timeout |
|-------|---------|----------|---------|
| **IDLE** | No active session / app just launched | `IDLE` | None — persists until event |
| **THINKING** | Session active but no tool use event received | `THINKING…` | None — persists until tool use or notification |
| **WORKING** | PreToolUse event received | `WORKING` + optional tool context | Clears on Stop/StopFailure/Notification |
| **APPROVE?** | Permission notification (see §2) | `APPROVE?` + brief context | None — persists until next event |
| **NEEDS INPUT** | Input notification (see §2) | `NEEDS INPUT` | None — persists until next event |
| **ERROR** | StopFailure event received | `ERROR` + brief reason | Persists until next session event |
| **DONE** | Stop event received (successful) | `DONE` | Auto-transitions to IDLE after 3 seconds |

### State priority

When events arrive in rapid succession, the LCD must show the most important state. Priority order (highest first):

```
ERROR > APPROVE? > NEEDS INPUT > WORKING > THINKING > DONE > IDLE
```

Rule: an incoming event only changes the LCD state if its priority is >= the current state's priority, OR if the current state has timed out.

Example scenarios:
- WORKING + StopFailure arrives → show ERROR (higher priority)
- APPROVE? + PreToolUse arrives → stay on APPROVE? (APPROVE? is higher priority than WORKING)
- ERROR + PreToolUse arrives → show WORKING (new session activity clears stale error)

Exception: any event from a NEW session always resets the state machine regardless of priority (the previous session's state is stale).

### WORKING context

If the PreToolUse payload includes `tool_name` and/or `tool_input`, show it as scrolling text on the LCD:
- Bash command: `WORKING: npm test`
- File read: `WORKING: Reading auth.ts`
- File write: `WORKING: Writing index.ts`
- If tool_input is too long, truncate to first 30 characters + "…"
- If tool_name/tool_input are missing, just show `WORKING`

### APPROVE? context

If the Notification payload includes `message` or `title`, show a brief excerpt:
- `APPROVE? rm -rf dist`
- `APPROVE? Write to .env`
- Truncate to 30 characters + "…"

### ERROR context

If the StopFailure payload includes `error` or `message`:
- `ERROR: Rate limited`
- `ERROR: Connection lost`
- If missing, just show `ERROR`

### Notification sub-types (transient flashes)

These are NOT LCD states — they're brief overlays that flash and return to the previous state:

| Notification type | LCD behavior | Duration |
|-------------------|-------------|----------|
| `authSuccess` | Flash "AUTH OK" over current state | 2 seconds, then restore previous state |
| `authError` | Flash "AUTH FAIL" over current state | 3 seconds, then restore previous state |

### Toast overlay

The restart warning toast from §1 is a separate overlay layer, not an LCD state. It appears on top of whatever state the LCD is currently in and dismisses after 5 seconds. Only one toast at a time.

---

## 5. Hook Improvements

These are invisible to users but critical for reliability.

### 5a. `if` fields — decision: do NOT use for monitoring hooks

CC-Beeper needs to receive ALL events to maintain accurate LCD state. Filtering with `if` would cause CC-Beeper to miss events and show stale states.

Example of what goes wrong: if PreToolUse has `"if": "tool_name == 'Bash'"`, CC-Beeper never sees Write or Read tool uses → LCD stays on THINKING when Claude is actually WORKING on file edits.

**Decision:** No `if` fields on any CC-Beeper monitoring hooks. All five hook types fire on every event. The overhead is minimal because the hooks are async curl calls that return in <100ms.

**When `if` fields WOULD make sense:** Only if CC-Beeper later ships guard hooks (blocking, synchronous) that target specific tool types. That's out of scope for v4.0.

### 5b. `async: true`

All CC-Beeper hooks must have `"async": true`. CC-Beeper is a monitoring layer — it must never block Claude Code's execution. This is already enforced in the hook registration (§3) but repeating for emphasis: **if a hook is missing `async: true`, it's a bug.**

### 5c. Timeout fields

All hooks get `"timeout": 5000` (5 seconds). This is a safety net: if CC-Beeper is crashed, frozen, or slow, Claude Code kills the hook process after 5 seconds and continues. Combined with `async: true`, this means a CC-Beeper failure has zero impact on Claude Code.

### 5d. `statusMessage`

Add `"statusMessage": "CC-Beeper monitoring…"` to the PreToolUse hook only. This shows a subtle status line in Claude Code's terminal UI so users know CC-Beeper is connected.

Only on PreToolUse because:
- It fires frequently (every tool use), giving regular confirmation CC-Beeper is active.
- Adding it to all 5 hooks would spam the Claude Code UI with redundant messages.

### 5e. Fix stderr/stdout pattern

**The bug:** If a hook outputs JSON to stdout without wrapping it in `hookSpecificOutput`, Claude Code interprets it as a malformed hook response and shows "Hook Error" labels in the transcript. These labels consume context tokens and confuse users.

**The fix:** All CC-Beeper hooks use `-o /dev/null` on curl, ensuring zero stdout output. This is already in the hook commands in §3. Verify during testing that NO output reaches stdout under any condition:
- Successful POST → curl output suppressed by `-o /dev/null`
- Failed POST (CC-Beeper not running) → curl error suppressed by `-o /dev/null` + `|| true`
- Port file missing → `2>/dev/null` on the cat command, fallback to default port

**Testing checklist for §5e:**
1. Start Claude Code with CC-Beeper running → no "Hook Error" in transcript
2. Start Claude Code with CC-Beeper NOT running → no "Hook Error" in transcript
3. Start Claude Code, then quit CC-Beeper mid-session → no "Hook Error" in transcript
4. Delete `~/.cc-beeper/port` while Claude Code is running → no "Hook Error", falls back to 19222

---

## 6. README Overhaul

### Structure

1. **Hero GIF** — Full-width animated GIF at the top showing CC-Beeper reacting to a live Claude Code session. Must show at least: IDLE → THINKING → WORKING → APPROVE? → DONE cycle. 10-15 seconds max.

2. **One-liner** — "Native macOS companion for Claude Code. Know what Claude is doing without leaving your workflow."

3. **Feature highlights** — 3-4 items with inline screenshots or GIF clips:
   - LCD status that follows Claude's activity in real time
   - Permission mode quick-toggle (show the segmented control)
   - YOLO sunglasses (this will get shared — make it prominent)
   - Menu bar presence — always visible, never in your way

4. **Install** — Must take under 60 seconds.
   - Primary: Homebrew cask if possible (`brew install --cask cc-beeper`)
   - Fallback: DMG download link from GitHub Releases → drag to Applications
   - State minimum requirements: macOS version, Claude Code version

5. **Setup** — What happens after install:
   - First launch walks you through permissions and hook installation
   - CC-Beeper detects Claude Code automatically
   - Show that it works out of the box with zero configuration

6. **How it works** — Brief technical paragraph:
   - CC-Beeper registers lightweight async hooks with Claude Code
   - Claude Code POSTs events to CC-Beeper's local HTTP server
   - CC-Beeper displays status on the LCD — it never blocks or slows Claude
   - What it does NOT do: manage hooks, edit config files, control Claude's behavior

7. **Uninstall** — How to cleanly remove:
   - Use "Remove Hooks" in CC-Beeper preferences before deleting the app
   - Or manually: remove hook entries containing `cc-beeper/port` from `~/.claude/settings.json`

8. **Requirements** — macOS version, Claude Code minimum version (must support HTTP hooks, `async` field, `timeout` field, `StopFailure` event type, `statusMessage` field).

### Tone
Developer-friendly, concise, no marketing fluff. Reference style: Raycast, Ice (menu bar manager), or Bartender READMEs. Show, don't tell.

---

## 7. Onboarding Polish

### First launch flow

**Step 1: Welcome**
- Single screen: beeper character animation + "CC-Beeper watches Claude Code so you don't have to."
- One button: "Set Up"

**Step 2: Claude Code detection**
- Check if `~/.claude/` directory exists.
- If exists → proceed to Step 3.
- If missing → show: "Claude Code doesn't seem to be installed. CC-Beeper needs Claude Code to work. Install it first, then relaunch CC-Beeper." Link to Claude Code install docs. Button: "Check Again" (re-checks) or "Quit."
- Do NOT create `~/.claude/` — that's Claude Code's job.

**Step 3: Permissions**
- Request Accessibility permission (needed for menu bar interaction).
- Show one-line explanation: "CC-Beeper needs Accessibility access to display status in your menu bar."
- If denied → CC-Beeper can still function but note any limitations. Do not block onboarding on optional permissions.
- Skip permissions that aren't immediately required (Microphone, Speech Recognition — these are future features).

**Step 4: Hook Installation**
- CC-Beeper checks `~/.claude/settings.json` for existing hooks.
- **Case A — No settings.json exists:** Create it with just the CC-Beeper hook entries. Show: "CC-Beeper will create a settings file for Claude Code with monitoring hooks."
- **Case B — settings.json exists, no CC-Beeper hooks:** Add CC-Beeper hook entries alongside existing content. Show: "CC-Beeper will add monitoring hooks to your Claude Code settings. Your existing settings won't be changed."
- **Case C — Old CC-Beeper hooks found (JSONL-based):** Show: "CC-Beeper has upgraded to HTTP hooks (faster, more reliable). Migrate now?" → Replace old entries with new HTTP entries.
- **Case D — Current CC-Beeper HTTP hooks already present:** Skip this step, show: "Hooks already installed."
- In all cases, show a "What this changes" expandable section with the exact JSON entries being added.

**Step 5: Start HTTP Server**
- CC-Beeper starts its local HTTP server.
- Confirm it's listening: show port number briefly.
- If port binding fails → show error with troubleshooting: "Port 19222 is in use. Check if another CC-Beeper instance is running."

**Step 6: Confirm**
- "You're all set. Start a Claude Code session and watch the beeper."
- Show the LCD in IDLE state.
- If a Claude Code session is already running: "Restart your Claude Code session to activate CC-Beeper's hooks."
- Button: "Done"

### Target: under 60 seconds from launch to working beeper.

### Edge cases
- **User cancels mid-flow:** Any hooks already written remain in settings.json. Next launch detects them (Case D) and skips hook installation.
- **settings.json is malformed:** Show: "Your Claude Code settings file has a syntax error. Fix it manually, then relaunch CC-Beeper." Do not attempt to write to a malformed file.
- **~/.claude/ exists but settings.json doesn't:** This is normal for fresh Claude Code installs. Create settings.json with CC-Beeper hooks only (Case A).

---

## 8. LCD Animation Polish

### Design principles
- Each state must be distinguishable at menu bar size (~22x22pt icon area + LCD text).
- A glance from across the room should tell you: idle, busy, waiting for you, or broken — without reading text.
- Animations must be lightweight — no high-FPS rendering. Target 15-30 FPS max, prefer CSS-style property animations over frame-by-frame.
- Battery impact must be negligible. IDLE state should use zero animation cycles.

### State animation specs

| State | Animation | Color/Tone | Speed | Feel |
|-------|-----------|------------|-------|------|
| **IDLE** | Static display, no animation | Grey/muted, dim backlight | 0 FPS | Nothing happening |
| **THINKING** | Slow opacity pulse (breathe) | Warm amber | ~1.5s cycle | Patient, processing |
| **WORKING** | Horizontal scanner bar OR marquee scroll of context text | Green/active | ~1s cycle or scroll speed | Actively doing something |
| **APPROVE?** | Fast blink cycle | Yellow/orange, bright | ~0.8s cycle | Urgent — go approve now |
| **NEEDS INPUT** | Slow steady blink | Blue/cyan, medium brightness | ~2s cycle | Not urgent — answer when ready |
| **ERROR** | Single red flash, then static hold | Red, bright | Flash once, then hold | Something broke |
| **DONE** | Brief green flash, then fade to IDLE | Green → grey | Flash 0.5s, hold 2.5s, fade | Task complete |

### Critical distinction: APPROVE? vs NEEDS INPUT

These are the two "go check your terminal" states. They must be immediately distinguishable:

- **APPROVE?** = Claude is BLOCKED and WAITING. Fast blink, warm/urgent color (yellow/orange). The feeling is "go now."
- **NEEDS INPUT** = Claude ASKED SOMETHING. Slow blink, cool/calm color (blue/cyan). The feeling is "when you get a chance."

If a user can't tell these apart at a glance, the LCD states have failed.

### Sunglasses rendering
- Pixel art sunglasses overlaid on the beeper character (not on the LCD text area).
- Style must be consistent with the beeper's existing pixel art aesthetic.
- Slide-down animation when YOLO mode is activated (sunglasses drop onto face).
- Slide-up animation when YOLO mode is deactivated.
- Persist across ALL LCD states while in YOLO/bypass mode.

### Toast rendering
- Toasts (e.g., "RESTART SESSION TO APPLY") render as an overlay on the LCD text area.
- Semi-transparent background so the underlying state color is still partially visible.
- Auto-dismiss after specified duration (5s for restart toast).
- Only one toast at a time. New toast replaces current toast.

### Transient flash rendering
- Auth success/error flashes briefly replace the LCD text but not the LCD state.
- After the flash duration (2-3s), the LCD returns to displaying the current state.
- Flash does not change the state machine — it's purely visual.

---

## 9. Don't-Do List

Documented here for reference during development. These are confirmed foot-guns from hooks research.

1. **Don't read tool input from environment variables.** `$CLAUDE_TOOL_INPUT` does not exist. Hook scripts receive JSON via stdin. Always read with `cat` or equivalent.

2. **Don't use Python for hook scripts.** Python's cold start (~200ms) is too slow for hooks that fire on every tool use. The HTTP migration eliminates this — hook scripts are now bash one-liners using curl. If you ever need a more complex hook script, use Node.js.

3. **Don't use `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`.** This environment variable is buggy and unreliable for context management. If context monitoring is needed in the future, use transcript file size as a heuristic instead.

4. **Don't claim hook changes take effect immediately.** Claude Code caches hook configuration at session start. Any change to `~/.claude/settings.json` (including permission mode changes) requires a session restart. Always show the restart toast. Never say "applied" — say "will apply on next session."

5. **Don't assume hooks work in `--bare` mode.** Claude Code's `--bare` flag skips hook execution entirely. CC-Beeper will show IDLE for the entire session. Document this: "CC-Beeper does not monitor --bare mode sessions."

6. **Don't use the `/hooks` endpoint for management.** It's read-only and will remain so. CC-Beeper manages hooks by directly reading/writing `~/.claude/settings.json`.

7. **Don't output anything to stdout from hook scripts.** Any stdout output that isn't wrapped in `{"hookSpecificOutput": {...}}` triggers false "Hook Error" labels in Claude Code's transcript. Use `-o /dev/null` on all curl commands and `2>/dev/null` on any subcommands.

8. **Don't make monitoring hooks synchronous.** Every CC-Beeper hook must have `"async": true` and a `"timeout"`. A crashed or slow CC-Beeper must never block Claude Code. This is a hard rule, not a preference.

9. **Don't use `if` fields on monitoring hooks.** CC-Beeper needs all events to maintain accurate LCD state. Filtering events causes stale/incorrect state display. See §5a for full rationale.

10. **Don't pretty-print settings.json on write.** Users may have their own formatting. Read the file, make targeted changes, write back. Use atomic writes (write to .tmp, rename) to prevent corruption.

---

## Priority Order

| Priority | Item | Effort | User visibility | Dependencies |
|----------|------|--------|----------------|--------------|
| 1 | HTTP Hooks Migration (§3) | High | Invisible | None — foundation for everything |
| 2 | LCD State Expansion (§4) | Medium | High — this IS the product | Depends on §3 (HTTP payloads) |
| 3 | Input vs Permission Differentiation (§2) | Medium | High — fixes YOLO bug | Depends on §3 (Notification payloads) and §4 (APPROVE? vs NEEDS INPUT states) |
| 4 | Permission Spectrum (§1) | Medium | High — the one new feature | Independent (reads/writes settings.json, doesn't need HTTP) |
| 5 | Hook Improvements (§5) | Low | Invisible | Depends on §3 (hook commands are defined there) |
| 6 | LCD Animation Polish (§8) | Medium | High — first impression | Depends on §4 (need final state list) |
| 7 | Onboarding Polish (§7) | Low-Medium | Critical for new users | Depends on §3 (hook installation) |
| 8 | README Overhaul (§6) | Low | Critical for launch | Do last — needs screenshots/GIFs of finished product |
| 9 | Don't-Do List (§9) | None | Developer reference | None |

### Execution order

**Phase 1 — Foundation (do first):**
§3 HTTP Hooks Migration → §4 LCD State Expansion → §2 Input vs Permission

**Phase 2 — Features:**
§1 Permission Spectrum → §5 Hook Improvements (verify async/timeout/stdout)

**Phase 3 — Polish (do right before launch):**
§8 LCD Animation Polish → §7 Onboarding Polish → §6 README Overhaul

**Phase 4 — Reference:**
§9 Don't-Do List — add to CLAUDE.md or a DEVELOPMENT.md in the repo at any point.
