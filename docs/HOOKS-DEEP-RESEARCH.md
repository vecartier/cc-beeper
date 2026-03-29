# CC-Beeper Hooks — Deep Research Report
## State of the Art, Creative Uses, Best Practices, Risks & Potential

*Compiled 2026-03-28 — 6 parallel research agents, 50+ sources*

---

## Table of Contents

1. [The Full Hook API (25 Events)](#1-the-full-hook-api-25-events)
2. [Handler Types Deep Dive](#2-handler-types-deep-dive)
3. [The `if` Field & Filtering](#3-the-if-field--filtering)
4. [Community Ecosystem Map](#4-community-ecosystem-map)
5. [Best Practices (Consensus)](#5-best-practices-consensus)
6. [Risks & Failure Modes](#6-risks--failure-modes)
7. [Creative & Unconventional Uses](#7-creative--unconventional-uses)
8. [HTTP Hooks: The Unlocked Frontier](#8-http-hooks-the-unlocked-frontier)
9. [Prompt Injection Defense (Lasso Security)](#9-prompt-injection-defense-lasso-security)
10. [What This Means for CC-Beeper](#10-what-this-means-for-cc-beeper)
11. [Sources](#11-sources)

---

## 1. The Full Hook API (25 Events)

### Session Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **SessionStart** | Session begins, resumes, context cleared, or compacted | `startup`, `resume`, `clear`, `compact` | No (stdout → context) |
| **SessionEnd** | Session terminates | `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` | No |

### Prompt Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **UserPromptSubmit** | User presses enter, before Claude processes | None (always fires) | Yes (`decision: "block"`) |

### Tool Events (The Core)

| Event | When | Matchers | `if` field? | Can Block? |
|-------|------|----------|------------|-----------|
| **PreToolUse** | Before any tool runs | Tool name | Yes (v2.1.85+) | Yes (`permissionDecision: "deny"`) |
| **PostToolUse** | After tool succeeds | Tool name | Yes | Yes (but can't undo) |
| **PostToolUseFailure** | After tool fails | Tool name | Yes | No |
| **PermissionRequest** | Permission dialog appears | Tool name | No | Yes (`behavior: "allow"/"deny"`) |

### Stop Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **Stop** | Claude finishes responding | None | Yes (`decision: "block"`) |
| **StopFailure** | API error instead of normal stop | `rate_limit`, `authentication_failed`, `billing_error`, `invalid_request`, `server_error`, `max_output_tokens`, `unknown` | No |

### Subagent & Team Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **SubagentStart** | Subagent spawns | Agent type | No |
| **SubagentStop** | Subagent finishes | Agent type | Yes |
| **TaskCreated** | Task created for teammate | None | Yes (`continue: false`) |
| **TaskCompleted** | Teammate finishes task | None | Yes |
| **TeammateIdle** | Teammate about to idle | None | Yes |

### Configuration & File Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **InstructionsLoaded** | CLAUDE.md or rules loaded | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact` | No |
| **ConfigChange** | Config file changes | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` | Yes |
| **CwdChanged** | Working directory changes | None | No |
| **FileChanged** | Watched file changes on disk | Filename | No |

### Worktree Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **WorktreeCreate** | Worktree created | None | Yes (replaces default) |
| **WorktreeRemove** | Worktree removed | None | No |

### Compaction Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **PreCompact** | Before context compaction | `manual`, `auto` | No |
| **PostCompact** | After compaction completes | `manual`, `auto` | No |

### MCP Elicitation Events

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **Elicitation** | MCP server requests user input | MCP server name | Yes (`action: "accept"/"decline"/"cancel"`) |
| **ElicitationResult** | After user responds to MCP elicitation | MCP server name | Yes |

### Notification Event

| Event | When | Matchers | Can Block? |
|-------|------|----------|-----------|
| **Notification** | Claude needs attention | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` | No |

### Common Input Fields (All Events)

```json
{
  "session_id": "string",
  "transcript_path": "string",
  "cwd": "string",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "hook_event_name": "string",
  "agent_id": "string (optional)",
  "agent_type": "string (optional)"
}
```

### Environment Variables Available to Hooks

| Variable | Available in |
|----------|-------------|
| `$CLAUDE_PROJECT_DIR` | All hooks |
| `$CLAUDE_CODE_REMOTE` | All hooks (`"true"` if headless) |
| `$CLAUDE_ENV_FILE` | SessionStart, CwdChanged, FileChanged only |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks only |
| `${CLAUDE_PLUGIN_DATA}` | Plugin hooks only |
| `$CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | System-level (v2.1.83+) |

**There are NO magic variables for tool input** — `$CLAUDE_TOOL_INPUT`, `$CLAUDE_FILE_PATHS` do not exist. The ONLY way to get event data is reading JSON from stdin.

---

## 2. Handler Types Deep Dive

### Command (`type: "command"`) — 95% of usage

```json
{
  "type": "command",
  "command": "node ~/.claude/cc-beeper/hooks/guard.js",
  "if": "Bash(rm *)",
  "timeout": 600,
  "async": false,
  "statusMessage": "Checking safety...",
  "once": false
}
```

- Receives JSON on **stdin**, writes to **stdout/stderr**, uses **exit codes**
- Shell sources user profile — beware unconditional `echo` statements in `.zshrc`
- `async: true` runs in background, cannot return decisions

### HTTP (`type: "http"`) — The new hotness

```json
{
  "type": "http",
  "url": "http://localhost:9876/hooks/event",
  "headers": {"Authorization": "Bearer $MY_TOKEN"},
  "allowedEnvVars": ["MY_TOKEN"],
  "timeout": 30
}
```

- POSTs JSON body (same as command hook stdin)
- Header values support `$VAR` interpolation but ONLY for vars in `allowedEnvVars`
- To block: return 2xx with JSON containing decision fields (HTTP status alone cannot block)
- Deduplication by URL
- **Key advantage:** Persistent server = state without files, connection pooling, WebSocket push

### Prompt (`type: "prompt"`) — LLM-as-judge

```json
{
  "type": "prompt",
  "prompt": "Should Claude stop? Evaluate: $ARGUMENTS",
  "model": "claude-haiku-4-5",
  "timeout": 30
}
```

- Single-turn LLM evaluation (no tool access)
- `$ARGUMENTS` replaced with JSON input data
- Returns `{"ok": true}` or `{"ok": false, "reason": "..."}`
- `ok: false` blocks the action, `reason` fed back to Claude

### Agent (`type: "agent"`) — Heavy verification

```json
{
  "type": "agent",
  "prompt": "Verify all tests pass and code is correct: $ARGUMENTS",
  "model": "claude-sonnet-4-6",
  "timeout": 60
}
```

- Multi-turn subagent with Read, Grep, Glob, Bash access
- Up to 50 tool-use turns
- Same `{"ok": true/false}` decision format
- Use when verification requires inspecting files or running commands

---

## 3. The `if` Field & Filtering

**Requires v2.1.85+ (2026-03-26).** Earlier versions silently ignore it.

The `if` field uses permission rule syntax to filter by tool name AND arguments:

```
"if": "Bash(git *)"        → Bash commands starting with "git"
"if": "Edit(*.ts)"          → Edit tool for TypeScript files
"if": "Bash(rm *)"          → Bash commands starting with "rm"
"if": "mcp__memory__.*"     → All memory server tools
"if": "Edit(src/**/*.ts)"   → TypeScript in src/ only
```

**Three-layer filtering architecture:**
1. **Event** — WHEN does the hook fire? (`PreToolUse`, `Stop`, etc.)
2. **Matcher** — WHICH tool? Regex on tool name (`"Bash"`, `"Edit|Write"`)
3. **`if` field** — WHAT arguments? Permission rule syntax. Hook script doesn't even spawn if `if` doesn't match. **This is the performance game-changer.**

**Gotcha:** Adding `if` to a non-tool event (SessionStart, Stop, etc.) **prevents the hook from running entirely** — silent failure.

---

## 4. Community Ecosystem Map

### Tier 1 — Major Repos (1K+ stars)

| Repo | Stars | Focus | Key Innovation |
|------|-------|-------|---------------|
| **hesreallyhim/awesome-claude-code** | 33,419 | Curated list | Canonical index of all hook projects |
| **davila7/claude-code-templates** | 23,721 | Marketplace | Web UI + CLI installer, 39+ hook templates |
| **shanraisshan/claude-code-best-practice** | 22,753 | Reference | Most thorough settings documentation anywhere |
| **affaan-m/everything-claude-code** | 113,194 | Framework | Runtime hook profiling (`ECC_HOOK_PROFILE=minimal|standard|strict`) |
| **parcadei/Continuous-Claude-v3** | 3,632 | Learning system | Skill activation injection on UserPromptSubmit |
| **disler/claude-code-hooks-mastery** | 3,424 | Reference impl | All 13 events, uv single-file scripts, TTS system |
| **disler/multi-agent-observability** | 1,306 | Monitoring | Real-time Vue dashboard via HTTP hooks + WebSocket |

### Tier 2 — Specialized (100-1K stars)

| Repo | Stars | Focus | Key Innovation |
|------|-------|-------|---------------|
| **karanb192/claude-code-hooks** | 304 | Safety | 262 tests, zero dependencies, three safety levels |
| **ccproxy (starbaser)** | 191 | Model routing | LiteLLM proxy that routes by request complexity |
| **lasso-security/claude-hooks** | 183 | Security | 50+ prompt injection patterns, PostToolUse defender |
| **GowayLee/cchooks** | 125 | Python SDK | Typed contexts, fluent exit methods |
| **beyondcode/claude-hooks-sdk** | 62 | PHP SDK | Laravel-inspired fluent API |

### Tier 3 — Niche / Creative

| Repo | Focus | Key Innovation |
|------|-------|---------------|
| **claude-bumper-lanes** | Circuit breaker | Weighted scoring, 10 diff visualizations, fuel gauge |
| **claude-quest** | Gamification | 90 achievements, XP leveling, ASCII dashboard |
| **cc-dice** | D&D triggers | Probabilistic hooks with accumulator escalation |
| **claudio** | Sound effects | OS-native sounds per event |
| **scv-sounds** | Fun | StarCraft SCV voice lines |
| **HCOM** | Inter-agent | Real-time comms between subagents via @-mentions |
| **parry** | Security | Prompt injection scanner |
| **Britfix** | i18n | American → British English (respects code identifiers) |

### SDK Layer

| SDK | Language | Pattern |
|-----|----------|---------|
| **cchooks** | Python | `create_context()` → typed context objects |
| **cc-hooks-ts** | TypeScript | `defineHook()` → full type safety per tool |
| **claude-hooks-sdk** | PHP | Laravel-style fluent builder |
| **claude_hooks** | Ruby | DSL with class inheritance |

---

## 5. Best Practices (Consensus)

### The Rules Everyone Agrees On

1. **Exit codes are sacred.** `0` = proceed, `2` = block, anything else = warning but proceed. Using `exit 1` for security gates is the #1 mistake — the action executes anyway.

2. **Fail-closed for security hooks.** Wrap logic in try/catch, default to `exit 2` on unexpected errors. A crashing security hook that exits 1 fails open.

3. **Check `stop_hook_active` in Stop hooks.** Always. Without this, Stop hooks create infinite loops that burn tokens indefinitely.

4. **stderr is your feedback channel.** Block messages written to stderr get fed back to Claude so it can self-correct. Make them specific and constructive.

5. **stdout is sacred too.** Debug `console.log()` or `print()` statements corrupt the JSON stream. Use `console.error()` / `sys.stderr` for diagnostics.

6. **Use absolute paths in JSON config.** `$HOME` and `~` are not expanded in JSON. The hook silently fails to load.

7. **Performance budget:**
   - Bash: ~10-20ms (best for simple checks)
   - Node.js: ~50-100ms (recommended for high-frequency hooks)
   - Python: ~200-400ms (only for infrequent events)
   - All hooks combined: <1 second (PrimeLine benchmark: 0.8s for 20 hooks)
   - **95 hooks is viable** if each completes in <200ms (Blake Crosley)

8. **Use the `if` field** (v2.1.85+) to prevent hook scripts from even spawning when they don't need to run. This is the single biggest performance optimization.

9. **Global hooks for security, project hooks for workflow.** Safety gates go in `~/.claude/settings.json`. Project-specific formatters go in `.claude/settings.json`.

10. **Hooks are deterministic; CLAUDE.md is advisory.** If something must happen every time with zero exceptions, use a hook. If it's guidance Claude can interpret, use CLAUDE.md.

### The Friction Frame

The best pitch for hooks isn't speed or safety — it's **friction elimination**:

> "Twenty tiny interruptions later, the thread is gone. Flow state slipped out while you weren't looking."

CC-Beeper's hooks aren't about making Claude faster — they're about keeping the USER in flow state by removing every micro-interruption.

### Production Results (PrimeLine, 6 months, 20 hooks)

| Metric | Before | After |
|--------|--------|-------|
| Manual checks per commit | 6 | 0 |
| Context limit hits per month | 12 | 1 |
| Accidental dangerous commands | 4 | 0 |
| All 20 hooks execution time | — | 0.8 seconds |
| Sessions lost to context overflow | 8 | 0 |

---

## 6. Risks & Failure Modes

### CRITICAL

#### Stop Hook Infinite Loops
When a Stop hook exits 2, Claude continues → finishes → triggers Stop hook again → exits 2 → infinite loop. Burns tokens indefinitely.
- **Mitigation:** Always check `stop_hook_active`. Set a max retry count.

#### Fail-Open on Hook Crash
Exit code 1 is non-blocking. If your security hook has an unhandled exception, it fails open — the dangerous command executes.
- **Mitigation:** Wrap in try/catch, default to exit 2 on unexpected errors for security hooks.

#### Repository-Based RCE (CVE-2025-59536)
Hooks in `.claude/settings.json` are committed to repos. A malicious contributor could inject hooks that execute arbitrary code on every collaborator's machine.
- **Status:** Patched (trust dialog now shown before executing project hooks).
- **Mitigation:** Review `.claude/settings.json` changes in PRs like you review code.

### HIGH

#### Token Consumption from Hook Context
Hooks that inject `additionalContext` eat into the ~33K-45K token context buffer. Known bug: `additionalContext` injected multiple times (Issue #14281).
- **Mitigation:** Keep hook output terse. Don't return `additionalContext` unless Claude genuinely needs it.

#### Version Regression
Hooks have been broken by Claude Code updates (v2.0.30 fixed, v2.0.31 broken again). Tool renames (`View` → `Read`) break matchers silently.
- **Mitigation:** Pin versions in CI. Test hooks after every update.

#### Race Conditions with Concurrent Instances
Multiple Claude Code instances sharing one machine: `.claude.json` corruption, OAuth race conditions, hooks firing twice, 100% CPU hangs.
- **Mitigation:** Use file locking in hooks that write shared files. Use `--session-id` for isolation.

#### Secret Leakage
Hooks run with full access to environment variables, filesystem, credentials. Hook stdout becomes part of context sent to Anthropic's API. Claude Code also reads `.env` files without explicit disclosure.
- **Mitigation:** Never log env vars in hook output. Use `.claudeignore` for `.env` files.

#### Silent Failures
- `$HOME` not expanded in JSON config → hook path resolves to nothing
- Missing dependencies → hook exits non-blocking
- Hooks not shown in `/hooks` → not loaded at all
- Debug stdout corrupts JSON stream
- Windows stdin connected as TTY → hooks never receive input
- **Mitigation:** Verify with `/hooks`. Test independently. Use absolute paths.

### MEDIUM

#### Process Spawning Overhead
Every hook invocation spawns a new process. A single tool call can trigger 3-4 hook processes. Hundreds of tool calls per session = hundreds of process spawns.
- **Mitigation:** Consolidate hooks. Use Node.js over Python. Consider HTTP hooks (one persistent server).

#### False Positive Blocking
Hooks that block `rm` also block `npm run build`. Over-broad patterns cause frustration.
- **Mitigation:** Start in advisory mode (exit 0 with warnings), promote to blocking after validating low false-positive rates.

#### Config Not Hot-Reloaded
Hook config is snapshotted at session start. Changes require a full restart. No `/reload` command.
- **Mitigation:** Always restart after config changes.

### Lessons from Analogous Ecosystems

| Ecosystem | Lesson for Hooks |
|-----------|-----------------|
| **Git Hooks** | Too-slow hooks get bypassed with `--no-verify`. Same psychology applies. |
| **VS Code Extensions** | Quality > quantity. One buggy extension degrades everything. No "Extension Bisect" equivalent for hooks. |
| **WordPress Plugins** | Plugin sprawl is real. 30+ hooks become unmanageable. Start with 2-3 essential. |
| **Webpack Plugins** | Sync vs async semantics must be crystal clear. Claude Code's distinction could be clearer. |

---

## 7. Creative & Unconventional Uses

### DX Innovation

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **Frustration detector** | Easy | Game-changer | UserPromptSubmit prompt hook evaluates tone → adjusts Claude's verbosity |
| **Adaptive skill profiling** | Medium | Game-changer | Track user patterns over sessions → inject profile so Claude adapts explanation depth |
| **Progressive guardrail relaxation** | Easy | Nice-to-have | Strict mode for new users, relax as "trust score" grows |
| **Time-of-day personality** | Easy | Nice-to-have | SessionStart checks clock → "Be brief, the user is tired" |

### Team & Collaboration

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **File lock broadcasting** | Medium | Game-changer | PreToolUse POSTs to shared server → warns if someone else is editing same file |
| **Team learnings injector** | Easy | Game-changer | SessionStart reads shared `TEAM_LEARNINGS.md` → everyone gets one person's discoveries |
| **Observer mode** | Medium | Nice-to-have | HTTP hooks stream to web dashboard → second dev watches + injects context |
| **Activity feed** | Easy | Nice-to-have | Async PostToolUse → Slack channel of live activity |

### AI-Augmented

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **Semantic code review gate** | Easy | Game-changer | PreToolUse prompt hook asks "does this change introduce vulnerabilities?" |
| **Architectural compliance checker** | Medium | Game-changer | PostToolUse agent hook checks layering violations |
| **Cascading quality gates** | Medium | Game-changer | Fast command check → prompt semantic check → agent deep verify |
| **Commit message quality** | Easy | Nice-to-have | PreToolUse prompt hook evaluates commit messages |

### Educational

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **"Explain as you go" mode** | Easy | Game-changer | PostToolUse prompt hook explains what just happened and why |
| **Quiz mode** | Easy | Nice-to-have | PostToolUse generates comprehension question after code is written |
| **Training wheels** | Easy | Nice-to-have | Block advanced ops for beginners with educational messages |

### Analytics & Insights

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **Live web dashboard** | Medium | Game-changer | HTTP hook server + WebSocket → real-time session visualization |
| **Session journal** | Easy | Nice-to-have | Stop hook appends structured entry → dataset for productivity analysis |
| **Anti-pattern detector** | Easy | Nice-to-have | PostToolUse tracks repeated edits/commands → warns of circular behavior |

### Integrations

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **Context-aware Slack summaries** | Medium | Game-changer | Stop hook summarizes via prompt → posts rich Slack message |
| **Bidirectional Slack control** | Hard | Game-changer | HTTP server bridges Slack commands → approve permissions from mobile |
| **Auto-status Linear/Jira updates** | Medium | Game-changer | Stop hook detects ticket patterns → updates status via API |
| **Deploy-on-green** | Easy | Nice-to-have | Stop hook triggers deployment pipeline after tests pass |

### Hardware

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **Ambient light (Hue/LIFX)** | Easy | Nice-to-have | Hook controls bulb: green=working, yellow=input, red=error |
| **Stream Deck integration** | Medium | Nice-to-have | HTTP hook → live button updates, press to approve |
| **E-ink session summary** | Medium | Nice-to-have | Stop hook renders to Raspberry Pi e-ink display |
| **Adaptive soundscape** | Medium | Nice-to-have | PostToolUse maps code metrics to Spotify API |

### Wild Cards

| Idea | Feasibility | Impact | How |
|------|------------|--------|-----|
| **Git archaeology guard** | Easy | Nice-to-have | PreToolUse checks `git log` age → warns on ancient files |
| **Time capsule** | Easy | Nice-to-have | Stop hook saves snapshot → resurfaces 6 months later |
| **D&D dice triggers** | Easy | Fun | Probabilistic Stop hook rolls d20 → injects refactor prompts |
| **Carbon footprint tracker** | Easy | Awareness | Estimates compute carbon cost per session |
| **Pomodoro integration** | Easy | Nice-to-have | Timer → suggests breaks, summarizes progress |

---

## 8. HTTP Hooks: The Unlocked Frontier

HTTP hooks (added v2.1.63, Feb 28 2026) are the most powerful and underexplored handler type. They change the game for CC-Beeper specifically.

### Why HTTP > Command for CC-Beeper

| Aspect | Command Hooks | HTTP Hooks |
|--------|--------------|------------|
| State | File-based IPC (JSONL) | In-memory (persistent server) |
| Startup cost | New process per invocation | Zero (server already running) |
| Bidirectional | Stdout only | Request/response |
| Real-time push | Not possible | WebSocket bridge |
| Multi-session | Separate processes | Single server handles all |
| Update logic | Redeploy scripts | Hot-reload server |

### What HTTP Hooks Enable

1. **Direct event delivery** — CC-Beeper is already a running app. Instead of Python script → JSONL → file watcher → SwiftUI, events POST directly to CC-Beeper's local HTTP server. Zero intermediate files.

2. **Real-time dashboards** — WebSocket push to any connected client (web UI, mobile app, other tools).

3. **Multi-session orchestration** — One server receives hooks from all active Claude Code sessions. Can coordinate, prevent conflicts, share discoveries.

4. **Stateful decisions** — The server remembers previous events. A "smart approve" pattern that learns from your approval history without writing to disk.

5. **External input injection** — The server can queue messages from Slack, mobile app, physical buttons. Next hook response includes them as `additionalContext`.

### CC-Beeper Hybrid Architecture

**HTTP hooks for monitoring** (replace Python script + JSONL pipeline):
- All events POST to `http://localhost:PORT/hooks/event`
- CC-Beeper's server processes them in-memory
- LCD state, notifications, voice reader all driven directly

**Command hooks for guards** (self-contained, no server dependency):
- Dangerous command blocker
- Protect secrets
- Stop guard (tests)
- These must work even if CC-Beeper isn't running

---

## 9. Prompt Injection Defense (Lasso Security)

**[lasso-security/claude-hooks](https://github.com/lasso-security/claude-hooks)** — 183 stars, MIT license

### What It Does

A `PostToolUse` hook that scans ALL tool outputs for indirect prompt injection attacks using 50+ regex patterns organized in 4 categories:

| Category | Risk | Examples |
|----------|------|---------|
| **Instruction Override** | High | "ignore previous instructions", "new system prompt:", fake delimiters |
| **Role-Playing / DAN** | High | "you are now DAN", "jailbreak mode enabled", persona switching |
| **Encoding / Obfuscation** | Medium-High | Base64 payloads, hex escapes, leetspeak, Cyrillic homoglyphs, zero-width Unicode |
| **Context Manipulation** | High | Fake Anthropic authority, hidden HTML comments, fake `{"role":"system"}` JSON |

### Why It's Smart

- **Pattern-based, not LLM-based** — zero cost, deterministic, auditable
- **Warns, doesn't block** — injects warning into Claude's context, Claude decides if content is actually malicious
- **Tool-aware content extraction** — handles plain strings, nested objects, arrays, falls back to JSON serialization
- **Monitors MCP outputs** — forward-thinking since MCP is a growing attack surface
- **Dual-runtime** — Python (uv) and TypeScript (Bun) implementations with shared `patterns.yaml`
- **Self-installing via Claude** — structured as a skill with cookbook workflows

### CC-Beeper Opportunity

This is a natural Tier 2 preset hook:
- **"Injection Shield"** — toggle in CC-Beeper Settings
- LCD indicator when injection detected ("INJECTION ALERT")
- Pattern updates pushed via CC-Beeper auto-update
- Severity escalation: warn on medium, alert on high, optional block on critical

---

## 10. What This Means for CC-Beeper

### Key Takeaways

1. **HTTP hooks should replace the Python JSONL pipeline.** CC-Beeper is already a running server. Direct HTTP delivery eliminates all intermediate files and file-watching overhead. Keep command hooks for guards that must work without CC-Beeper running.

2. **The `if` field is a game-changer for performance.** Every CC-Beeper preset that uses PreToolUse should use `if` to avoid spawning hook processes unnecessarily. Requires v2.1.85+ — add a version check.

3. **The Permission Spectrum is validated by the community.** Multiple projects (everything-claude-code's `ECC_HOOK_PROFILE`, karanb192's three safety levels) converge on the same pattern: preset combinations of hooks at different strictness levels.

4. **Prompt/agent hooks are underexplored gold.** The AI Stop Guard (prompt hook) and semantic code review gate are genuine differentiators. Nobody has shipped a polished UI for configuring prompt hooks yet.

5. **The risks are real but manageable.** Stop hook infinite loops, fail-open crashes, and context pollution are the big three. CC-Beeper can guard against all three with good defaults and clear UI feedback.

6. **Lasso Security's injection defender is a natural fit** for a "security" preset category. Pattern-based, zero-cost, and the detection categories map cleanly to CC-Beeper's alert system.

7. **Sound/haptic/visual feedback is CC-Beeper's moat.** Multiple projects (claudio, scv-sounds, ESP32 monitor) prove there's demand for physical feedback. CC-Beeper already has the hardware. Hooks are the event source.

### Revised Tier Recommendations

**Tier 1 — Launch (high impact, proven patterns):**
1. Dangerous Command Blocker (with safety levels + `if` field)
2. Protect Secrets
3. Stop Guard (test gate, with `stop_hook_active` check)
4. Smart Approve (PermissionRequest auto-allow for reads)
5. Auto-Format (on Stop, not on every edit — avoid token noise)
6. Context Re-injection (SessionStart on compact|resume)
7. Permission Spectrum selector (Normal / Smart / Guarded YOLO / YOLO)

**Tier 2 — Differentiators:**
8. AI Stop Guard (prompt hook — "did Claude actually finish all tasks?")
9. Loop Detector (PostToolUseFailure counter)
10. Context Guard (two-tier: 70% warn, 90% block)
11. Branch Guard (SessionStart + optional PreToolUse block on main)
12. Injection Shield (Lasso Security patterns)
13. Auto-Checkpoint (PostToolUse edit counter → git commit)

**Tier 3 — Power user:**
14. Protect Tests
15. Quality Pipeline
16. Thrash Detector
17. Auto-Continue
18. Question Answerer (FAQ)
19. Quick Guards (temporary freeze/careful toggles)

**HTTP migration — parallel track:**
- Replace Python JSONL pipeline with HTTP hooks for all monitoring events
- Keep command hooks for guards (must work without CC-Beeper)

---

## 11. Sources

### Official Anthropic
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Changelog](https://code.claude.com/docs/en/changelog)
- [Best Practices](https://code.claude.com/docs/en/best-practices)

### Major Repos
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 113K stars
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — 33K stars
- [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates) — 24K stars
- [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) — 23K stars
- [parcadei/Continuous-Claude-v3](https://github.com/parcadei/Continuous-Claude-v3) — 3.6K stars
- [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) — 3.4K stars
- [disler/multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability) — 1.3K stars
- [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks) — 304 stars
- [lasso-security/claude-hooks](https://github.com/lasso-security/claude-hooks) — 183 stars
- [kylesnowschwartz/claude-bumper-lanes](https://github.com/kylesnowschwartz/claude-bumper-lanes) — 31 stars

### SDKs
- [GowayLee/cchooks](https://github.com/GowayLee/cchooks) (Python)
- [sushichan044/cc-hooks-ts](https://github.com/sushichan044/cc-hooks-ts) (TypeScript)
- [beyondcode/claude-hooks-sdk](https://github.com/beyondcode/claude-hooks-sdk) (PHP)
- [gabriel-dehan/claude_hooks](https://github.com/gabriel-dehan/claude_hooks) (Ruby)

### Blog Posts
- [Blake Crosley — 5 Production Hooks](https://blakecrosley.com/blog/claude-code-hooks-tutorial)
- [GitButler — Automate AI Workflows](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks)
- [Karan Bansal — Most Underrated Feature](https://karanbansal.in/blog/claude-code-hooks/)
- [Lakshmi Narasimhan — The Feature You're Ignoring](https://medium.com/@lakshminp/)
- [Steve Kinney — Hook Examples](https://stevekinney.com/courses/ai-development/claude-code-hook-examples)
- [SmartScope — Production Implementation](https://smartscope.blog/en/generative-ai/claude/claude-code-hooks-practical-implementation/)
- [DEV Community — Automated Workflow](https://dev.to/ji_ai/how-i-automated-my-entire-claude-code-workflow-with-hooks-5cp8)

### Security
- [Check Point Research — CVE-2025-59536](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/)
- [Knostic — Claude Loads .env Secrets](https://www.knostic.ai/blog/claude-loads-secrets-without-permission)
- [DEV Community — 5 Hook Mistakes](https://dev.to/yurukusa/5-claude-code-hook-mistakes-that-silently-break-your-safety-net-58l3)
- [Lasso Security — Hidden Backdoor in Claude](https://www.lasso.security/blog/the-hidden-backdoor-in-claude-coding-assistant)

### GitHub Issues
- [#3523 — Progressive hook duplication (16K+ hooks)](https://github.com/anthropics/claude-code/issues/3523)
- [#10205 — Infinite loop with Stop hooks](https://github.com/anthropics/claude-code/issues/10205)
- [#14281 — additionalContext injected multiple times](https://github.com/anthropics/claude-code/issues/14281)
- [#22172 — 100% CPU with parallel instances](https://github.com/anthropics/claude-code/issues/22172)
- [#28847 — .claude.json corruption](https://github.com/anthropics/claude-code/issues/28847)
- [#21988 — PreToolUse exit code ignored](https://github.com/anthropics/claude-code/issues/21988)
