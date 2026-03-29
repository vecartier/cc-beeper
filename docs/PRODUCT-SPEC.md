# CC-Beeper — Product Spec
## The Claude Code Companion That Helps You Work Better

*2026-03-29 — Final*

---

## What CC-Beeper Is Today

A macOS floating widget shaped like a retro pager. It sits on your desktop and:

- Shows Claude's state on an LCD (THINKING / DONE / NEEDS YOU / IDLE)
- Lets you approve/deny permissions via buttons or global hotkeys (Option+A/D)
- Reads Claude's responses aloud (TTS via Kokoro or Apple)
- Takes voice input and injects it into the terminal (STT via Parakeet)
- Supports 10 color themes, dark mode, sound effects, vibration
- Auto-launches when Claude Code starts a session

Communication happens via file-based IPC: a Python hook script monitors 8 Claude Code events, writes to JSONL files, CC-Beeper watches them via kqueue.

---

## What We're Adding

A new panel (name TBD, separate from Preferences) with four sections, plus LCD and behavioral enhancements:

1. **Guidelines** — view, edit, and grow your global `~/.claude/CLAUDE.md`
2. **Guards** — toggle presets that prevent bad things
3. **Automations** — toggle presets that do things automatically
4. **Permissions** — control how much Claude can do on its own

Plus:

5. **Proactive Nudges** — behavior-based suggestions surfaced on the pager
6. **Recommended Setup** — one-tap onboarding that enables a sensible default set

---

## Design Principles

**1. Toggle first, configure second.** Every feature starts as ON/OFF. Configuration appears only when you expand the card.

**2. Plain English everywhere.** The user never sees "hook," "PreToolUse," "exit code 2," or "settings.json." They see "Block dangerous commands" and "Run tests before done."

**3. Show consequences, not mechanisms.** "Token cost: none" not "This writes to ~/.claude/settings.json hooks.PreToolUse." "Speed: <50ms per check" not "Node.js script reading JSON from stdin."

**4. Informative, not binary.** When a guard blocks something, the feedback must be precise. "Blocked: `rm -rf .` would delete your entire project. Use `make clean` or target a specific directory" — not just "Blocked." Precise feedback lets Claude self-correct without overcorrecting. (Source: @DanielleFong + @AryamanIyer3 — "failed because X gives the model something precise to correct. 'failed' just triggers a full restart.")

**5. Guards always win over Permissions.** If "Block dangerous commands" is ON and the user adds `rm -rf` to "Always allow," the guard still blocks it. Safety beats convenience.

**6. Proactive, not passive.** CC-Beeper doesn't wait for you to open a panel. It notices patterns and nudges. The panel is for deliberate configuration; the nudges are for organic improvement.

**7. Don't duplicate Claude Code.** If Claude Code has a terminal command that works (`/plugin`, `/model`, `/effort`, `/compact`), CC-Beeper doesn't rebuild it in a GUI. CC-Beeper only builds what the terminal can't do: visual hook management, guideline editing, permission tracking, context awareness.

---

## The New Panel

### Navigation

Four sections, each answering a plain-English question:

| Section | Question It Answers |
|---------|-------------------|
| **Guidelines** | "What does Claude know about me?" |
| **Guards** | "What is Claude protected from?" |
| **Automations** | "What does Claude do automatically?" |
| **Permissions** | "How much can Claude do on its own?" |

---

### 1. Guidelines

**What it manages:** `~/.claude/CLAUDE.md` — your global personal instructions that apply to every project, every session.

**Why it matters:** This file massively affects Claude's behavior but it's buried in a hidden folder (`~/.claude/`). Most users don't know it exists. Those who do rarely look at it. Every line costs tokens on every message — but good guidelines are worth the cost because they prevent Claude from making the same mistakes repeatedly.

#### Three interaction modes

**View & Edit**
- Shows the file contents as readable markdown
- Line count and estimated token cost at the top: "87 lines — ~1,400 tokens per message"
- Edit inline like Apple Notes — no special syntax needed
- Save writes directly to `~/.claude/CLAUDE.md`
- If the file doesn't exist, show empty state (see Create)

**Create**
- Empty state when no `~/.claude/CLAUDE.md` exists
- "Claude doesn't know anything about you yet. Your guidelines tell Claude your preferences, coding style, and how you like to work — across every project."
- Two options:
  - "Start blank" — opens the editor with an empty file
  - "Let Claude help" — triggers Chat mode with a starter prompt

**Chat**
- Text input where you describe what you want in plain English
- "I prefer TypeScript strict mode" / "Always explain what you're doing before you do it" / "I'm a designer, not an engineer — keep explanations simple"
- CC-Beeper injects a prompt into the active terminal session: "Add to ~/.claude/CLAUDE.md: [user's input]. Write the rule clearly and concisely."
- Claude writes the rule for itself — Boris Cherny: "Claude is eerily good at writing rules for itself"
- Guidelines view refreshes to show the updated file
- **Requires an active Claude Code session.** If none running, Chat input is disabled: "Start a Claude Code session to use Chat mode." View & Edit still work (just file operations).

#### What it shows but doesn't edit

- A note at the bottom: "This project also has a CLAUDE.md (45 lines)" — if one exists in the current working directory
- Read-only, tappable to view contents
- Per-project CLAUDE.md editing belongs in the project, not a system-level companion

#### Quick Add

Available from anywhere in CC-Beeper (menu bar, pager context menu, or a hotkey):
- "Claude keeps doing something wrong? Add a rule."
- Small text input → appends to `~/.claude/CLAUDE.md`
- The Boris workflow: "Anytime Claude does something incorrectly, add it to the CLAUDE.md"

---

### 2. Guards

**What it manages:** Hooks in `~/.claude/settings.json` that **prevent bad things from happening**.

**Why it matters:** Claude can run dangerous commands, read your secrets, edit protected branches, weaken your linter config, get stuck in loops. Guards are deterministic scripts that catch these before they happen. They cost zero tokens — they run outside Claude's context.

#### Preset Guards

Each preset is a card: name, one-line description, ON/OFF toggle. Tap to expand for details and configuration.

##### Safety

| Guard | Default | What It Does |
|-------|---------|-------------|
| **Block dangerous commands** | ON | Prevents `rm -rf`, `git push --force`, `DROP TABLE`, fork bombs, `curl \| bash`, `chmod 777`. Three safety levels: Critical / High (recommended) / Strict. Where possible, suggests a safer alternative instead of just blocking (e.g., `git push --force` → "Use `--force-with-lease` instead"). |
| **Protect secrets** | ON | Blocks reading `.env`, SSH keys, AWS credentials, kubeconfig. Blocks bash commands that expose secrets (`cat .env`, `printenv`, `echo $API_KEY`). Allows `.env.example` and `.env.template`. |
| **Protect configs** | ON | Blocks Claude from modifying linter/formatter configs (`.eslintrc`, `biome.json`, `.prettierrc`, `ruff.toml`, `swiftformat`, ~25 filenames). Forces Claude to fix the source code instead of weakening the rules. (Source: everything-claude-code — agents frequently modify linter configs to make checks pass.) |
| **Branch protection** | OFF | Warns or blocks when on `main`/`master`. Prevents accidental commits to protected branches. |
| **Injection shield** | OFF | Scans tool outputs for prompt injection attacks — fake system prompts, role-play attempts, encoded payloads, Cyrillic homoglyphs, zero-width Unicode, base64 payloads. 50+ regex patterns from Lasso Security. Warns Claude without blocking. |

##### Anti-Loop

| Guard | Default | What It Does |
|-------|---------|-------------|
| **Loop detection** | OFF | Counts consecutive failures on the same tool/file combo. After 3 failures (configurable): "You've failed at this 3 times with the same approach. The error is [specific error]. Try a completely different strategy." |
| **Thrash detection** | OFF | Tracks when Claude edits the same file back and forth. After 5 edits to the same file (configurable): "You've edited `auth.ts` 5 times. Step back, read the file fully, and decide what you actually want before editing again." |

##### Expanded Card Example

```
┌──────────────────────────────────────────────────┐
│  Block dangerous commands                  [ON]  │
│  Prevents rm -rf, force push, and other          │
│  destructive terminal commands                   │
│                                                  │
│  Safety level                                    │
│  ○ Critical — only catastrophic operations       │
│  ● High — recommended for daily use              │
│  ○ Strict — maximum protection                   │
│                                                  │
│  What it catches at High level:                  │
│  · rm -rf /, rm -rf ~, rm -rf .                  │
│  · git push --force main/master                  │
│  · git reset --hard                              │
│  · DROP TABLE, TRUNCATE                          │
│  · Fork bombs, curl | bash                       │
│  · chmod 777, dd to disk, mkfs                   │
│                                                  │
│  When blocked, Claude gets a specific message    │
│  explaining WHY and suggesting alternatives.     │
│                                                  │
│  Token cost: none                                │
│  Speed: <50ms per check                          │
└──────────────────────────────────────────────────┘
```

#### Custom Guards

Below the presets:
- "See all hooks" — lists every hook in `~/.claude/settings.json`, including non-CC-Beeper ones
- Each shows: event type, matcher, command, source (CC-Beeper / manual / other)
- Can remove any hook
- "Add custom guard" — simple form: pick event, pick matcher, enter command. Power users only.

---

### 3. Automations

**What it manages:** Hooks in `~/.claude/settings.json` that **do things automatically**.

**Why it matters:** Instead of manually checking if tests pass, if code is formatted, if all tasks are done — let the machine verify the machine. Zero effort, every time. (Source: @MingtaKaivo — "stopped doing this and added a pre-commit hook instead. the machine should verify the machine, not you.")

#### Preset Automations

##### Quality

| Automation | Default | What It Does | Config |
|-----------|---------|-------------|--------|
| **Run tests before done** | OFF | Claude can't finish until your test command passes. If tests fail, the specific failure output is fed back: "3 tests failed in `auth.test.ts`: `testTokenRefresh`, `testSessionExpiry`, `testLogout`. Fix these before stopping." | Test command: `npm test`, `pytest`, `swift test`, etc. |
| **Verify all tasks complete** | OFF | AI judge evaluates whether Claude finished everything you asked — without seeing Claude's self-assessment. See [AI Judge details](#ai-judge-mechanism). | Toggle only. |
| **Verify claims** | OFF | Catches when Claude says "this works" or "done" without having run tests or verification commands. A prompt-type Stop hook asks: "Did Claude back up its claims with evidence (test runs, command output)?" (Source: @DanielleFong's epistemic hook.) | Toggle only. |
| **Auto-format code** | OFF | Runs your formatter when Claude finishes. Catches the 10% of cases where Claude's formatting doesn't match your project. | Formatter command: `npx prettier --write .`, `swiftformat .`, etc. |

##### Context

| Automation | Default | What It Does | Config |
|-----------|---------|-------------|--------|
| **Re-inject rules after compaction** | OFF | When Claude compresses its context, important instructions can get lost. This re-injects your critical rules after every compaction. | Rules text area — "sticky rules" that must survive compaction. |
| **Auto-compact when context fills** | OFF | Nudges Claude to compact at 70% context usage. At 90%, blocks new file reads until context is cleared. Two-tier: warn first, enforce second. | Thresholds (defaults: 70/90). |

##### Workflow

| Automation | Default | What It Does | Config |
|-----------|---------|-------------|--------|
| **Auto-continue** | OFF | Suppresses "Should I continue?" questions when the answer is obviously yes. Claude just keeps going. | Toggle only. |
| **Auto-checkpoint** | OFF | Creates a git checkpoint commit after every N file edits so you can easily rollback. | Edits before checkpoint (default: 5). |

#### AI Judge Mechanism

The "Verify all tasks complete" automation uses a `prompt`-type Stop hook that sends a single-turn evaluation to a fast model (Haiku).

**How it gets the data:** The Stop hook JSON includes `transcript_path` — the path to the full session JSONL transcript. The hook script parses this to extract:
1. The **first user message** of the current task (the original request)
2. The **tool outputs** from the session (files written, commands run, test results)

It does NOT include `last_assistant_message` (Claude's self-assessment). This is the autoclear principle — the judge evaluates work product against the request, not Claude's opinion of its own work.

**The prompt sent to the judge:**
```
The user asked Claude to do the following:
[original user request]

Here is what was actually produced:
[summary of tool outputs: files changed, test results, commands run]

Did Claude complete ALL tasks the user asked for? If not, list what is
still missing. Respond with {"ok": true} or {"ok": false, "reason": "..."}.
```

If `ok: false`, the specific reason is fed back to Claude and it continues working. If Claude has already been sent back once (`stop_hook_active: true`), it's allowed to stop — preventing infinite loops.

**Limitation:** Transcript parsing is approximate. Very long sessions may have truncated transcripts. The judge works best on focused, single-task sessions. **If the transcript file exceeds 500KB, skip the judge entirely** — the data is too noisy to produce reliable verdicts. Exit 0 silently.

#### Expanded Card Example

```
┌──────────────────────────────────────────────────┐
│  Run tests before done                     [ON]  │
│  Claude must pass your tests before finishing     │
│                                                  │
│  Test command                                    │
│  ┌──────────────────────────────────────────┐    │
│  │ npm test                                 │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  How it works:                                   │
│  When Claude says "done," this runs your test    │
│  command. If tests fail, the specific failures   │
│  are sent back: "3 tests failed in auth.test.ts: │
│  testTokenRefresh, testSessionExpiry. Fix these   │
│  before stopping."                               │
│                                                  │
│  If Claude still can't fix the tests after one   │
│  attempt, it's allowed to stop and explain       │
│  what's wrong (prevents infinite loops).         │
│                                                  │
│  Token cost: none (tests run externally)         │
└──────────────────────────────────────────────────┘
```

---

### 4. Permissions

**What it manages:** `permissions.allow` and `permissions.deny` in `~/.claude/settings.json`, plus the permission mode.

**Why it matters:** Permission fatigue is the #1 daily friction. Clicking "approve" 50 times for `npm test` is not safety — it's annoyance. But full YOLO mode is reckless. The sweet spot is personal: auto-approve what you trust, block what you don't.

#### Permission Spectrum

The hero element — a slider at the top.

```
    How much can Claude do on its own?

    Cautious ───────────●──── Autonomous

    ● Auto Mode
    A classifier judges each action. Safe operations
    proceed automatically. Risky ones still ask you.
```

| Position | Mode | What Happens |
|----------|------|-------------|
| **Cautious** | `default` | Claude asks before every action. |
| **Guided** | `auto` | AI classifier auto-approves safe actions. You only see risky ones. (Recommended) |
| **Guarded YOLO** | `bypassPermissions` + CC-Beeper guards ON | Everything auto-approved, but Guards still block dangerous commands and protect secrets. |
| **Full YOLO** | `bypassPermissions` + guards OFF | Everything runs. No guardrails. Isolated sandboxes only. |

Moving the slider shows a preview of what changes before you commit.

#### Always Allow

Commands Claude can run without asking. Built from your behavior + manual additions.

```
┌──────────────────────────────────────────────────┐
│  Suggested (based on your approvals)             │
│                                                  │
│  npm test              approved 23x    [Add]     │
│  git status            approved 18x    [Add]     │
│  git diff              approved 14x    [Add]     │
│                                                  │
│  ─────────────────────────────────────────────── │
│                                                  │
│  Active                                          │
│                                                  │
│  ✓  Read any file                        [x]     │
│  ✓  npm run build                        [x]     │
│  ✓  git log                              [x]     │
│                                                  │
│  + Add command...                                │
└──────────────────────────────────────────────────┘
```

**Proactive suggestions:** CC-Beeper sits in the permission approval flow — it writes every response. It counts how many times you approve each command pattern. When a command crosses a threshold (10+ approvals), it surfaces a suggestion: "You've approved `npm test` 23 times. Always allow?" One tap to add. This is data only CC-Beeper has.

#### Never Allow

Commands Claude can never run, regardless of permission mode.

```
┌──────────────────────────────────────────────────┐
│  ✗  rm -rf (anything)                    [x]     │
│  ✗  git push --force main               [x]     │
│  ✗  git push --force master             [x]     │
│                                                  │
│  + Add rule...                                   │
└──────────────────────────────────────────────────┘
```

Some defaults are pre-populated. User can add/remove.

#### Relationship to Guards

- **Permissions** = "Claude can do X without asking" (convenience)
- **Guards** = "Claude is prevented from doing X even if permissions allow it" (safety)

Guards always win. The UI makes this clear — if a conflict exists, the guard's card shows a note explaining it overrides the permission.

---

## Recommended Setup

First-time onboarding or accessible from the panel header. One tap enables a sensible default set:

| Preset | State |
|--------|-------|
| Block dangerous commands | ON (High) |
| Protect secrets | ON |
| Protect configs | ON |
| Run tests before done | ON (prompts for test command) |
| Re-inject rules after compaction | ON |

Five presets, one tap, immediately protected. The user can tune from there. Avoids the "13 toggles, where do I start?" problem.

---

## Proactive Nudges

CC-Beeper isn't a settings panel you open once and forget. It notices how you work and helps you improve. Nudges surface naturally from data CC-Beeper already has.

| Trigger | Nudge | Action |
|---------|-------|--------|
| Approved same command 10+ times | "You've approved `npm test` 23 times. Always allow?" | One tap → adds permission rule |
| No `~/.claude/CLAUDE.md` exists | First-session message | "Claude doesn't know about you. Set up guidelines?" |
| Claude finishes but tests fail | "Claude said 'done' but tests failed. Add a test gate?" | Toggle → enables Stop guard |
| Same tool fails 3+ times | "Claude seems stuck. Enable loop detection?" | Toggle → enables loop guard |
| No guards enabled | Subtle badge on panel | "You have no safety guards active" |
| Claude modifies a linter config | "Claude changed your ESLint config. Want to protect configs?" | Toggle → enables config guard |

Nudges are not popups. They appear on the LCD, in the menu bar, or as a subtle badge. The user is never interrupted — they glance and decide.

---

## How CC-Beeper Manages Hooks (Technical)

All Guards and Automations are hooks under the hood. The user never sees the word "hook."

### File Structure

```
~/.claude/cc-beeper/
├── hooks/                          # Hook scripts (Node.js for speed)
│   ├── block-dangerous.js          # Guard: dangerous commands
│   ├── protect-secrets.js          # Guard: secret files
│   ├── protect-configs.js          # Guard: linter/formatter configs
│   ├── branch-guard.js             # Guard: branch protection
│   ├── injection-shield.js         # Guard: prompt injection
│   ├── loop-detector.js            # Guard: loop detection
│   ├── thrash-detector.js          # Guard: thrash detection
│   ├── stop-guard.sh               # Automation: test gate
│   ├── ai-judge.js                 # Automation: task verification
│   ├── verify-claims.js            # Automation: epistemic check
│   ├── auto-format.sh              # Automation: code formatting
│   ├── context-reinject.sh         # Automation: rule re-injection
│   ├── context-guard.js            # Automation: compact nudge
│   ├── auto-continue.js            # Automation: suppress continue
│   └── auto-checkpoint.sh          # Automation: git checkpoints
├── sticky-rules.txt                # Sticky rules for re-injection
├── patterns.yaml                   # Injection shield patterns (Lasso Security)
└── state/                          # Runtime state (per session)
    ├── loop-state.json             # Failure counts per tool/file
    ├── thrash-state.json           # Edit counts per file
    ├── checkpoint-count            # Edits since last checkpoint
    ├── tool-call-count             # Tool calls for compact suggestion
    └── approval-counts.json        # Permission approval frequency
```

### Hook Script Requirements

**Performance:**
- PreToolUse hooks: <100ms. Node.js only (50-100ms startup). Never Python (200-400ms).
- Stop hooks: can be slower (tests naturally take time). Bash is fine.
- All CC-Beeper hooks combined: <1 second total per tool call cycle.
- Use the `if` field (v2.1.85+) to prevent scripts from spawning when they don't need to.
- Use `async: true` for monitoring hooks that don't need to block.
- Consider in-process loading pattern (from everything-claude-code's `run-with-flags.js`) — if a hook exports `run()`, call it directly instead of spawning a subprocess. Saves ~50-100ms per hook.

**Safety:**
- Security hooks (guards) default to **exit 2** (block) on unexpected errors. Fail closed.
- Non-security hooks (automations) default to **exit 0** (allow) on unexpected errors. Fail open.
- Stop hooks must always check `stop_hook_active` flag to prevent infinite loops.
- AI Judge must use autoclear — original request + tool outputs only, never Claude's self-assessment.
- Never write debug output to stdout (corrupts JSON). Use stderr.

**Feedback quality (the informative-not-binary principle):**
- Every block message must explain WHAT was blocked, WHY it's dangerous, and WHAT to do instead.
- Every test failure must include specific failing tests, not just "tests failed."
- Every loop detection must include the specific error that keeps recurring.
- Vague feedback causes Claude to overcorrect. Precise feedback lets Claude make targeted fixes.

### Settings.json Management

1. **Read** existing `~/.claude/settings.json`
2. **Identify** CC-Beeper's hooks by naming convention (command paths containing `cc-beeper`)
3. **Remove** all existing CC-Beeper hooks
4. **Add** hooks for currently-enabled presets
5. **Write** back without touching any non-CC-Beeper hooks or other settings
6. **Version check** — warn if Claude Code below v2.1.85 (required for `if` fields)

### Security & Integrity

**File locking:** The current `HookInstaller.swift` does a simple read-modify-write without locking. This is vulnerable to race conditions — if Claude Code or another process writes to `settings.json` between our read and write, those changes are lost (documented: GitHub #29036, #28847). **Must add `flock()` around the read-modify-write cycle.** Also write to `settings.json.tmp` first, then atomic `rename()`.

**Hook script permissions:** Set all guard scripts to `0o700` (owner-only execute), not `0o755`. The parent directory `~/.claude/cc-beeper/hooks/` should be `0o700`. This prevents other users or processes from tampering with guard scripts.

**Script integrity:** On app launch, verify installed hook scripts match the bundled versions by comparing file hashes. If a script has been modified externally, warn the user and offer to reinstall.

**No context injection from guards:** Guard scripts (PreToolUse hooks) must NEVER write to stdout unless returning a structured JSON decision. Any debug output goes to stderr only. Stdout on certain events (SessionStart, UserPromptSubmit) gets injected directly into Claude's context — a compromised hook could manipulate Claude's behavior via prompt injection through stdout.

**Global hooks are implicitly trusted:** Unlike project hooks, global hooks in `~/.claude/settings.json` do NOT trigger a trust dialog. They run silently. This is fine for CC-Beeper (the user explicitly installed them), but means a compromised `settings.json` executes without warning.

### Token Usage Guardrails

**Guard hooks must not inject context.** All PreToolUse guard scripts should either exit 0 (silent pass) or exit 2 (block with stderr message). They should NEVER return `additionalContext` in their JSON output — this gets injected into Claude's conversation and accumulates every turn.

**Prompt-type hooks cost API calls.** The AI Judge and Verify Claims presets use `type: "prompt"`, which makes a separate API call to Haiku on every Stop event. This is acceptable for Stop (fires once per turn) but would be prohibitive for PreToolUse (fires on every tool call). **Never use prompt/agent types for PreToolUse guards.**

**Multiple Stop hooks compound.** If "Run tests" (command, 10-30s) + "AI Judge" (prompt, 5-15s) + "Verify claims" (prompt, 5-15s) all fire on Stop, Claude waits 20-60s before each response. **Show estimated overhead in the UI.** Consider making AI Judge and Verify Claims mutually exclusive, or sequential-with-short-circuit (if tests fail, skip the judge).

### Restart Requirement

**Hook config changes require a session restart.** Claude Code caches hook configuration at session start (GitHub #22679). Changes to `settings.json` are NOT reliably hot-reloaded. When CC-Beeper modifies hooks, show on the LCD: "Guards updated — restart Claude Code session to apply." Do NOT claim changes take effect immediately.

Permission rule changes (`permissions.allow`/`permissions.deny`) may hot-reload (since v1.0.90), but hook entries do not. The Permission Spectrum slider's permission changes should take effect immediately; its hook-related changes (Guarded YOLO enabling guards) need a restart.

---

## Technical Reference: Hook Implementation Details

This section is for Claude Code when building the presets. It covers the four handler types, the three-layer filtering system, JSON schemas, and specific implementation patterns for the AI Judge and epistemic check.

### Four Handler Types

CC-Beeper presets use all four handler types depending on what the preset needs to do:

#### Command (`type: "command"`) — Most presets

```json
{
  "type": "command",
  "command": "node ~/.claude/cc-beeper/hooks/block-dangerous.js",
  "if": "Bash(rm *)",
  "timeout": 10,
  "statusMessage": "Checking safety..."
}
```

- Receives JSON on **stdin**, writes to **stdout** (JSON) or **stderr** (block message)
- Exit 0 = proceed (stdout parsed as JSON). Exit 2 = block (stderr fed to Claude). Other = warning only.
- **Critical:** Exit 2 ignores stdout. Exit 0 ignores stderr for blocking. Pick one approach.
- Default timeout: 600s. CC-Beeper presets should set 5-30s.
- `async: true` runs in background (can't block). Use for monitoring/logging only.

#### HTTP (`type: "http"`) — Future IPC migration

```json
{
  "type": "http",
  "url": "http://localhost:PORT/hooks/event",
  "headers": {"Authorization": "Bearer $TOKEN"},
  "allowedEnvVars": ["TOKEN"],
  "timeout": 30
}
```

- POSTs same JSON that command hooks get on stdin
- Response: 2xx + empty = success. 2xx + text = added as context. 2xx + JSON = parsed as hook output. Non-2xx = non-blocking error.
- **To block:** Return 2xx with JSON containing decision fields (HTTP status codes alone cannot block)
- Only vars in `allowedEnvVars` are interpolated in headers — security by design
- Deduplication by URL
- **CC-Beeper opportunity:** When migrating from Python JSONL IPC, CC-Beeper's app hosts the HTTP server. Claude Code POSTs events directly. Zero intermediate files. See backlog: HTTP hooks migration.

#### Prompt (`type: "prompt"`) — AI Judge, Verify Claims

```json
{
  "type": "prompt",
  "prompt": "Evaluate if Claude completed all tasks: $ARGUMENTS",
  "model": "claude-haiku-4-5",
  "timeout": 30
}
```

- Single-turn LLM evaluation. No tool access.
- `$ARGUMENTS` replaced with the hook's full JSON input data
- Model returns `{"ok": true}` or `{"ok": false, "reason": "explanation"}`
- `ok: false` blocks the action and feeds `reason` back to Claude
- Default model: fast (Haiku). Override with `model` field.
- Default timeout: 30s.
- **Used by:** "Verify all tasks complete" and "Verify claims" presets

#### Agent (`type: "agent"`) — Deep verification

```json
{
  "type": "agent",
  "prompt": "Run the test suite and verify all tests pass: $ARGUMENTS",
  "model": "claude-sonnet-4-6",
  "timeout": 120
}
```

- Multi-turn subagent with tool access (Read, Grep, Glob, Bash)
- Up to 50 tool-use turns
- Same `{"ok": true/false, "reason": "..."}` decision format
- Default timeout: 60s.
- **Use when:** Verification requires reading files or running commands, not just evaluating text

### Three-Layer Filtering (Event → Matcher → `if`)

Every hook goes through three filters before its script runs:

```
1. EVENT        — Which lifecycle point?
                  (PreToolUse, Stop, PostToolUse, etc.)

2. MATCHER      — Which tool (regex on tool name)?
                  "Bash", "Edit|Write", "mcp__github__.*"
                  Scope: per group (all hooks in the group share it)

3. IF FIELD     — Which arguments (permission rule syntax)?
                  "Bash(rm *)", "Edit(*.ts)", "Bash(git *)"
                  Scope: per handler (each hook has its own)
                  The script doesn't even spawn if `if` doesn't match.
```

**Example flow** (from @dani_avila7's flowchart):
```
Claude runs Bash "rm -rf /tmp/build"
  → PreToolUse fires
    → matcher "Bash" matches? YES
      → if "Bash(rm *)" matches? YES
        → hook script runs → blocks with exit 2
```

If either matcher or `if` doesn't match, the hook is skipped entirely — zero overhead.

**`if` field rules:**
- Requires Claude Code v2.1.85+ (earlier versions silently ignore it)
- Only works on tool events: PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest
- **WARNING: Adding `if` to any other event (Stop, SessionStart, etc.) prevents the hook from running entirely — silent failure, no error message.** This is the #1 gotcha for custom guards. The UI must validate this: if a user creates a custom guard on a non-tool event and adds an `if` condition, show an error: "The 'if' filter only works on tool events (PreToolUse, PostToolUse). Remove it or your guard will never fire."
- Uses permission rule syntax: `"ToolName(pattern)"`, `"Bash(git *)"`, `"Edit(src/**/*.ts)"`
- Pipe alternation not supported in `if` — use separate handlers

**CC-Beeper must use `if` fields on every PreToolUse preset** to avoid spawning scripts on irrelevant tool calls. Examples:

| Preset | Matcher | `if` field |
|--------|---------|-----------|
| Block dangerous commands | `Bash` | `Bash(rm *)` for rm, separate handler for `Bash(git push *)`, etc. |
| Protect secrets | `Read\|Edit\|Write\|Bash` | No `if` (needs to check multiple patterns internally) |
| Protect configs | `Edit\|Write` | No `if` (checks ~25 filenames internally) |
| Branch guard | `Edit\|Write` | No `if` (checks git branch, not tool args) |

### AI Judge: Implementation Detail

The "Verify all tasks complete" preset uses a `prompt`-type Stop hook. The key design constraint is **impartiality** — the judge must not be influenced by Claude's self-assessment.

**What the judge receives (via `$ARGUMENTS`):**

The Stop hook JSON includes:
- `transcript_path` — path to the full session JSONL transcript
- `stop_hook_active` — boolean, true if Claude was already sent back by this hook
- `last_assistant_message` — Claude's final response (DO NOT use this for judging)

**The autoclear principle:**

The hook script parses `transcript_path` to extract:
1. The **first user message** after the last `/clear` or session start (the original request)
2. The **tool outputs** — files written, test results, command outputs

It explicitly strips `last_assistant_message` and any assistant text. The judge evaluates **work product against request**, never **Claude's opinion against request**.

**The prompt:**
```
The user asked Claude to do the following:
[extracted user request]

Here is what was actually produced:
[summary of tool outputs: files changed, test results, commands run]

Did Claude complete ALL tasks the user asked for?
If yes: {"ok": true}
If no: {"ok": false, "reason": "Specifically: [what's missing]"}

Be precise about what is missing. Do not say "incomplete" — say which
specific task or subtask was not done.
```

**Infinite loop prevention:**
```javascript
const input = JSON.parse(stdin);
if (input.stop_hook_active) {
  // Claude was already sent back once — let it stop
  process.exit(0);
}
```

**Why the reason must be specific** (from @AryamanIyer3): "failed because X gives the model something precise to correct. 'failed' just triggers a full restart." If the judge says `{"ok": false, "reason": "incomplete"}`, Claude overcorrects — rewrites everything. If it says `{"ok": false, "reason": "Missing: the logout test in auth.test.ts was not written"}`, Claude adds that one test.

### Verify Claims: Implementation Detail

The "Verify claims" preset is inspired by @DanielleFong's epistemic hook. It catches Claude making claims like "this works" or "I've verified this" without having actually run tests or verification commands.

**Implementation:** A `prompt`-type Stop hook that receives `$ARGUMENTS` (the full stop event JSON including `last_assistant_message` and `transcript_path`).

**The prompt:**
```
Review Claude's final message and the session transcript.

Claude's final message:
[last_assistant_message]

Tools used in this session (from transcript):
[list of tool names and commands from transcript_path]

Check: Did Claude make any claims about correctness, functionality, or
completion ("this works", "tests pass", "I've verified", "everything is
correct") WITHOUT having run a verification command (test suite, build,
manual check) in the same session?

If Claude made unverified claims:
{"ok": false, "reason": "You claimed [specific claim] but didn't run
[what verification was needed]. Please verify before finishing."}

If all claims are backed by tool outputs:
{"ok": true}
```

**Note:** Unlike the AI Judge, this hook DOES read `last_assistant_message` — because it needs to check what Claude claimed. The impartiality constraint only applies to the task-completion judge, not the epistemic check.

### JSON Config Examples for CC-Beeper Presets

#### Guard: Block Dangerous Commands
```json
{
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "if": "Bash(rm *)",
      "command": "node ~/.claude/cc-beeper/hooks/block-dangerous.js",
      "timeout": 5
    }, {
      "type": "command",
      "if": "Bash(git push *)",
      "command": "node ~/.claude/cc-beeper/hooks/block-dangerous.js",
      "timeout": 5
    }, {
      "type": "command",
      "if": "Bash(git reset *)",
      "command": "node ~/.claude/cc-beeper/hooks/block-dangerous.js",
      "timeout": 5
    }]
  }]
}
```

Multiple `if` handlers for different patterns — the script only spawns when one matches.

#### Automation: Run Tests Before Done
```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "~/.claude/cc-beeper/hooks/stop-guard.sh",
      "timeout": 120,
      "statusMessage": "Running tests..."
    }]
  }]
}
```

No matcher (Stop has no matcher support). The script checks `stop_hook_active` internally.

#### Automation: Verify All Tasks Complete (AI Judge)
```json
{
  "Stop": [{
    "hooks": [{
      "type": "prompt",
      "prompt": "Review the session. The user's original request and the tool outputs are in: $ARGUMENTS. Did Claude complete ALL requested tasks? If not, respond with {\"ok\": false, \"reason\": \"Specifically: [what is missing]\"}. Be precise.",
      "model": "claude-haiku-4-5",
      "timeout": 30
    }]
  }]
}
```

#### Automation: Context Re-injection After Compaction
```json
{
  "SessionStart": [{
    "matcher": "compact",
    "hooks": [{
      "type": "command",
      "command": "cat ~/.claude/cc-beeper/sticky-rules.txt"
    }]
  }]
}
```

SessionStart stdout is injected as context Claude can see.

#### Automation: Auto-Approve Read Operations (via PermissionRequest)
```json
{
  "PermissionRequest": [{
    "matcher": "Read|Glob|Grep",
    "hooks": [{
      "type": "command",
      "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PermissionRequest\",\"decision\":{\"behavior\":\"allow\"}}}'"
    }]
  }]
}
```

### Common Input Fields (All Events)

Every hook receives this on stdin (command) or as POST body (HTTP):

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/Users/you/project",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "hook_event_name": "PreToolUse",
  "agent_id": "optional",
  "agent_type": "optional"
}
```

Plus event-specific fields: `tool_name` + `tool_input` for tool events, `stop_hook_active` + `last_assistant_message` for Stop, `source` for SessionStart, etc.

### Environment Variables

| Variable | Available In | Notes |
|----------|-------------|-------|
| `$CLAUDE_PROJECT_DIR` | All hooks | Project root. Quote for spaces. |
| `$CLAUDE_ENV_FILE` | SessionStart, CwdChanged, FileChanged | Write exports here to persist env vars for the session |
| `$CLAUDE_CODE_REMOTE` | All hooks | `"true"` if headless/remote |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks | Plugin install directory |
| `${CLAUDE_PLUGIN_DATA}` | Plugin hooks | Persistent plugin data directory |

**There are NO magic variables for tool input.** `$CLAUDE_TOOL_INPUT` does not exist. Read JSON from stdin.

---

---

## UX Guidelines

### Panel Layout

Use `NavigationSplitView` with a sidebar listing the four sections (Guidelines, Guards, Automations, Permissions). Never show all sections at once — one category at a time, like System Settings and Raycast. The sidebar shows a badge count for pending suggestions.

### Toggle Cards

Each guard/automation is a card with: icon (dimmed when OFF) + title + subtitle + toggle. Tapping the card body expands configuration detail — but only when the toggle is ON. Disabling auto-collapses the detail. Two levels maximum — if a feature needs more, it gets its own pane.

```
┌────────────────────────────────────────────┐
│  🛡  Block dangerous commands       [ON]   │
│  Prevents rm -rf, force push, etc.         │
│                                            │
│  ▸ Tap to configure safety level           │
└────────────────────────────────────────────┘
```

### Grouping

Use `Form` with `.grouped` style and `Section` headers. Guards group into Safety (3) + Anti-Loop (2). Automations group into Quality (4) + Context (2) + Workflow (2). Max 3-4 cards per section — fits one screen without scrolling on a 13" MacBook.

### Suggested Permissions (Inline Banner)

Suggestions appear as a yellow-tinted banner at the top of the Permissions section:

```
💡 You've approved `npm test` 23 times. Always allow?    [Add]  [✕]
```

- Show max 3 suggestions at a time
- Each suggestion shown max 3 times across 3 sessions. After 3 dismissals, never again.
- After the user adds the rule, remove the suggestion permanently.
- Never suggest features the user explicitly disabled.

### Permission Spectrum Slider

Stepped slider with 4 discrete detents (not continuous). Each position shows its name and a one-line description below. Changes preview before committing. Use Slider with `step: 0.33` and named stops.

### Guidelines Editor

TextEditor with monospaced font, bordered container, footer showing line count + estimated token cost. Min height 120px, max 240px. Token count turns red above 2,000 tokens. No "Save" button — auto-saves on every edit (macOS convention: settings never need a save button).

### Onboarding (Recommended Setup)

A single sheet on first launch:
- Header: "Quick Setup — we've selected the most popular protections"
- Shows the 5 recommended presets as a checklist (pre-checked)
- "Get Started" primary button applies them all
- "Customize" disclosure expands the full toggle list
- Test command prompt appears inline if "Run tests" is checked

### Restart Warning

When CC-Beeper writes hook changes to `settings.json`, show a toast on the LCD:

```
  GUARDS UPDATED
  Restart session to apply
```

This appears for 10 seconds, then fades. Not a modal, not a popup — just an LCD message.

### Anti-Patterns to Avoid

- **No "Save" or "Apply" buttons.** Settings auto-save. Period.
- **No confirmation dialogs for toggles.** Toggling is instant and undoable.
- **No alphabetical ordering.** Order by frequency of use and logical grouping.
- **No more than 8 toggles visible at once.** Beyond that, collapse sections.
- **No hidden dependencies.** If enabling "Verify claims" requires "Run tests," auto-enable it or disable the toggle with an explanation.
- **No toggle fatigue.** The Recommended Setup handles the initial decision. After that, users only change 1-2 things at a time.

---

## What CC-Beeper Does NOT Do

- **No plugin/skill/MCP management.** Claude Code handles this natively via `/plugin`, `/skills`, `claude mcp`.
- **No per-project CLAUDE.md editing.** Global guidelines only. Per-project belongs in the project.
- **No session management.** `/compact`, `/clear`, `/rename` are terminal commands. CC-Beeper shows context status but doesn't run commands for you.
- **No model/effort selection.** `/model` and `/effort` work fine in the terminal.
- **No agent/subagent management.** Multi-agent orchestration is too niche for a consumer companion.
- **No marketplace or discovery.** Anthropic builds this.

---

## Preferences (Existing, Unchanged)

The existing Settings window is renamed to **Preferences**:

| Tab | What It Configures |
|-----|-------------------|
| Theme | 10 shell colors, dark mode |
| Voice Record | STT engine, language |
| Voice Reader | TTS provider (Kokoro/Apple), voice selection, VoiceOver toggle |
| Feedback | Sound effects, vibration |
| Hotkeys | Global hotkey mapping (⌥A, ⌥D, ⌥R, ⌥T, ⌥M) |
| Permissions | macOS accessibility, microphone, speech recognition status |
| Setup | Re-run onboarding, reinstall hooks, uninstall |
| About | Version, links, credits |

---

## Summary

| Component | What | Status |
|-----------|------|--------|
| **Pager widget** | LCD display, permission buttons, voice I/O, hotkeys | Exists |
| **Preferences** | Theme, voice, hotkeys, feedback, setup | Exists (rename from Settings) |
| **New panel — Guidelines** | Global CLAUDE.md: view, edit, create, chat, quick add | New |
| **New panel — Guards** | 7 presets (block dangerous, protect secrets, protect configs, branch guard, injection shield, loop detect, thrash detect) + custom | New |
| **New panel — Automations** | 8 presets (test gate, AI judge, verify claims, auto-format, context re-inject, auto-compact, auto-continue, auto-checkpoint) + custom | New |
| **New panel — Permissions** | Permission Spectrum slider, always-allow with proactive suggestions, never-allow | New |
| **Recommended Setup** | One-tap onboarding enabling 5 sensible defaults | New |
| **Proactive nudges** | Behavior-based suggestions surfaced on LCD/menu bar | New |

**Totals:** 15 toggle presets (7 guards + 8 automations), 4 permission modes, 3 guideline interaction modes.

---

## Backlog (Not In This Spec)

- **HTTP hooks migration** — replace Python JSONL IPC with CC-Beeper hosting a local HTTP server. Claude Code POSTs events directly. Eliminates file-based IPC. See `project_ccbeeper_http_hooks.md`.
- **Multilingual voice** — French TTS via Kokoro, Whisper for multilingual STT, voice picker in onboarding. See `project_ccbeeper_next_session.md`.
- **Per-project panel** — extend panel to show/edit per-project CLAUDE.md and project-level hooks.
- **Question Answerer / FAQ** — prebuilt Q&A pairs so Claude stops asking "which database?" every session.
- **Quick Guards** — temporary session-level toggles (freeze all writes, careful mode) from the pager.
- **Cost tracking** — token/cost metrics per session (pattern from everything-claude-code).

---

## Research & Sources

### Research Documents (in `docs/`)
- [HOOKS-DEEP-RESEARCH.md](./HOOKS-DEEP-RESEARCH.md) — 25 hook events, 4 handler types, community ecosystem (15+ repos), risks, creative uses, performance budgets
- [CLAUDE-SETUP-RESEARCH.md](./CLAUDE-SETUP-RESEARCH.md) — full Claude Code config landscape (CLAUDE.md, settings.json, skills, plugins, MCP), Boris Cherny tips, CLAUDE.md maturity framework (L0-L6), token cost analysis

### Key Repos Studied
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 100K+ stars, 30 agents, 135 skills, runtime hook profiling (`ECC_HOOK_PROFILE`), config protection pattern, in-process hook loading via `run-with-flags.js`
- [lasso-security/claude-hooks](https://github.com/lasso-security/claude-hooks) — 183 stars, 50+ prompt injection detection patterns, dual Python/TS implementations
- [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks) — 304 stars, 262 tests, three safety levels, zero-dependency Node.js
- [kylesnowschwartz/claude-bumper-lanes](https://github.com/kylesnowschwartz/claude-bumper-lanes) — circuit breaker pattern, weighted edit scoring, fuel gauge
- [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) — all 13 events, TTS system, uv single-file scripts
- [disler/multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability) — real-time Vue dashboard via HTTP hooks + WebSocket

### Official Anthropic
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide) — official guide, `if` field (v2.1.85+)
- [Hooks Reference](https://code.claude.com/docs/en/hooks) — full event schemas, JSON formats
- [Best Practices](https://code.claude.com/docs/en/best-practices) — hooks in context of workflows
- [Auto Mode](https://www.anthropic.com/engineering/claude-code-auto-mode) — classifier-based permission system

### People & Posts
- [Boris Cherny](https://howborisusesclaudecode.com) — 57 tips (v3.0.0), "Claude is eerily good at writing rules for itself," verification is the #1 tip, auto mode, /dream
- [@trq212 (Thariq, Anthropic)](https://x.com/trq212) — prompt-based Stop hooks announcement (35K views): "Prompt hooks are great for encouraging Claude to work for longer periods of time, doing clean up work like removing extra files, writing tests or keeping track of what work is being done"
- [@MingtaKaivo](https://x.com/MingtaKaivo) — "the machine should verify the machine, not you"
- [@DanielleFong](https://x.com/DanielleFong) — epistemic hook that catches Claude making claims without proving them (31K views). "After it fires, the model around it makes good corrections"
- [@AryamanIyer3](https://x.com/AryamanIyer3) — "the overcorrection is the annoying part. hook fires, model reformulates more than it needs to. the fix is making the hook output informative not binary. 'failed because X' gives the model something precise to correct. 'failed' just triggers a full restart"
- [@dani_avila7 (Daniel San)](https://x.com/dani_avila7) — `if` field flowchart: matcher → if → hook command resolution. "This unlocks more surgical hooks for project-specific workflows, no more hooks firing on every tool call when you only care about one"
- [PrimeLine](https://primeline.cc/blog/hooks-automation) — 20 hooks, 6 months production: manual checks 6→0, context hits 12→1/month, dangerous commands 4→0, all 20 hooks combined 0.8s
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 18 hook ideas table for context engineers including: auto-run tests after code changes (PostToolUse async on Write|Edit), LLM-powered quality gate on Stop (prompt type), agent-based verification gate (agent type), rewrite Bash commands before execution (PreToolUse updatedInput), prevent premature task completion (TaskCompleted), inject repo-specific context per subagent (SubagentStart)

### Security
- [CVE-2025-59536](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) — repo-based RCE via project hooks (patched)
- [Knostic](https://www.knostic.ai/blog/claude-loads-secrets-without-permission) — Claude reads .env without disclosure
- [GitHub #10205](https://github.com/anthropics/claude-code/issues/10205) — Stop hook infinite loops
- [GitHub #14281](https://github.com/anthropics/claude-code/issues/14281) — additionalContext injected multiple times
