# CC-Beeper — Claude Code Configuration Research
## Everything a Non-Technical User Needs to Know

*Compiled 2026-03-28 — 4 parallel research agents + Boris Cherny tips (v3.0.0)*

---

## Table of Contents

1. [The Big Picture: 6 Extension Points](#1-the-big-picture)
2. [CLAUDE.md — Your Project's Brain](#2-claudemd)
3. [settings.json — Permissions & Config](#3-settingsjson)
4. [Skills — On-Demand Knowledge](#4-skills)
5. [Hooks — Automated Guards](#5-hooks)
6. [Plugins — Install & Forget](#6-plugins)
7. [MCP — External Connections](#7-mcp)
8. [Session Management — The #1 Skill](#8-session-management)
9. [Token Cost of Everything](#9-token-cost-of-everything)
10. [Boris Cherny's Key Insights](#10-boris-chernys-key-insights)
11. [What This Means for CC-Beeper](#11-what-this-means-for-cc-beeper)

---

## 1. The Big Picture

Claude Code has 6 ways to customize behavior. Think of them as layers:

| Layer | What It Is | Analogy | Always On? | Token Cost |
|-------|-----------|---------|------------|------------|
| **CLAUDE.md** | Instructions Claude follows | Sticky note on your monitor | Yes, every message | ~2-4K tokens |
| **Skills** | Specialized workflows | Recipe book | No, on-demand | Only when triggered |
| **Hooks** | Automated scripts on events | Security guard at the door | Yes, but external | Zero (runs outside Claude) |
| **Plugins** | Bundles of all the above | An app you install | Depends on contents | Variable |
| **MCP** | Connections to external tools | USB cables to other tools | Tool names loaded, content on-demand | Variable |
| **settings.json** | Permissions & configuration | Your preferences panel | Yes | Zero (config only) |

**The key insight:** Most users only use CLAUDE.md (if that). Skills, hooks, plugins, and MCP are where the real power is — but they're invisible and hard to configure from the terminal.

---

## 2. CLAUDE.md — Your Project's Brain

### What It Is

A plain text file that tells Claude who you are, what your project does, and how you work. Without it, Claude starts every session with zero memory.

### The Hierarchy (All Loaded, All Additive)

| Location | Scope | Shared? | Example Use |
|----------|-------|---------|-------------|
| `~/.claude/CLAUDE.md` | You, all projects | No | "I prefer TypeScript, use 2-space indent" |
| `./CLAUDE.md` (repo root) | Team, this project | Yes (git) | "Run `npm test` before committing" |
| `./.claude/CLAUDE.md` | You, this project | No (gitignored) | Personal overrides |
| `.claude/rules/*.md` | Team, path-scoped | Yes (git) | "API files must validate input" (only loads for `src/api/` files) |
| `CLAUDE.local.md` | You, this project | No (gitignored) | Personal notes |

**They don't replace each other — they stack.** Claude sees ALL of them. If two contradict, Claude picks one arbitrarily.

### What Makes a Good CLAUDE.md

**Include (high ROI):**
- Build/test/lint commands Claude can't guess
- Code style rules that differ from defaults
- Architecture decisions unique to your project
- Common gotchas and non-obvious behaviors
- Domain-specific terms ("a 'Wrap' means the annual video summary")

**Exclude (wasted tokens):**
- Anything Claude can figure out by reading code
- Standard language conventions it already knows
- Detailed API docs (link to them instead)
- Self-evident rules ("write clean code")
- Code snippets (they go stale immediately)

### The Golden Rule

For every line, ask: **"Would removing this cause Claude to make mistakes?"** If not, cut it.

### Size Matters

- Target: **under 200 lines, ~2,000 tokens**
- Every line is injected into context on EVERY message exchange
- Too long → important rules get lost in noise → Claude starts ignoring instructions
- If Claude keeps breaking a rule despite having it in CLAUDE.md, the file is probably too bloated

### The Maturity Framework

| Level | Name | What It Looks Like |
|-------|------|--------------------|
| **L0** | Absent | No CLAUDE.md. Claude is flying blind. |
| **L1** | Basic | File exists, maybe just `/init` output. |
| **L2** | Scoped | Has MUST/MUST NOT rules with strong language. |
| **L3** | Structured | Uses `@imports` to reference external docs. |
| **L4** | Modular | Uses `.claude/rules/` with path-scoped loading. |
| **L5** | Maintained | Actively reviewed and pruned. Living document. |
| **L6** | Adaptive | Uses Skills for specialized workflows. |

Most projects are at L1-L2. L4+ delivers significant token savings and better adherence.

### CC-Beeper Opportunity

A **CLAUDE.md Health Check** that shows:
- "You have a CLAUDE.md with 45 lines. Level: L2."
- "It covers: build commands, architecture. Missing: test commands, conventions."
- "Estimated token cost: 1,800 tokens per message."
- Green/yellow/red indicator
- "Generate a starter" button (runs `/init`)
- View/edit the content

---

## 3. settings.json — Permissions & Config

### The Hierarchy (Highest to Lowest Priority)

| Priority | File | Scope | Shared? |
|----------|------|-------|---------|
| 1 (highest) | Managed settings (enterprise) | Organization | Admin-only |
| 2 | CLI flags (`--model opus`) | Single session | No |
| 3 | `.claude/settings.local.json` | You, this project | No (gitignored) |
| 4 | `.claude/settings.json` | Team, this project | Yes (git) |
| 5 (lowest) | `~/.claude/settings.json` | You, all projects | No |

**Merge behavior:** Arrays (like permission rules) are concatenated and deduplicated across scopes. **A deny rule at any level cannot be overridden** by an allow at a lower level.

### What Can You Configure

| Setting | What It Does |
|---------|-------------|
| `permissions.allow` | Commands Claude can run without asking (e.g., `"Bash(npm test)"`) |
| `permissions.deny` | Commands Claude can NEVER run (e.g., `"Bash(rm -rf *)"`) |
| `hooks` | Lifecycle event scripts (see Hooks section) |
| `mcpServers` | External tool connections |
| `model` | Default model (`opus`, `sonnet`, `haiku`) |
| `effortLevel` | How hard Claude tries (`low`/`medium`/`high`/`max`) |
| `env` | Environment variables |
| `disableAllHooks` | Kill switch for all hooks |

### Permission Modes (The YOLO Spectrum)

| Mode | What Happens | Safety | Speed | Best For |
|------|-------------|--------|-------|----------|
| **plan** | Read-only, no changes | Maximum | Slow | Architecture, analysis |
| **default** | Asks for everything | High | Slow | Learning, sensitive repos |
| **acceptEdits** | Auto-approve file edits, ask for bash | Medium-High | Medium | Daily coding |
| **auto** (NEW) | AI classifier judges each action | Medium | Fast | Development with guardrails |
| **dontAsk** | Deny everything not explicitly allowed | Medium | Fast | CI/CD, automation |
| **bypassPermissions** | YOLO. Everything runs. | None | Maximum | Isolated sandboxes ONLY |

**The sweet spot for most people:** `auto` mode or `acceptEdits` with a generous allowlist.

### Permission Rule Syntax

```
Bash(npm test)      → matches exactly "npm test"
Bash(npm *)         → matches "npm install", "npm run dev", etc.
Bash(git commit:*)  → matches "git commit -m '...'", "git commit --amend"
Edit                → allow all file edits
Read(/path/**)      → allow reading files under a path
```

**Deny always wins.** If managed settings deny `Bash(rm -rf *)`, nothing can override it.

### CC-Beeper Opportunity

A **Permissions Dashboard** showing:
- Current permission mode (with explain)
- Active allow/deny rules in plain English
- Which scope each rule comes from (global vs project vs local)
- "You're clicking approve a lot — consider adding `Bash(npm test)` to your allow list"
- One-click to add common patterns
- The Permission Spectrum slider (Normal → Smart → Guarded YOLO → YOLO)

---

## 4. Skills — On-Demand Knowledge

### What They Are

Skills are specialized workflows that Claude loads **on demand** — when it recognizes the task matches, or when you invoke them with `/skill-name`. Unlike CLAUDE.md (always loaded), skills only consume tokens when used.

### Where They Live

| Location | Scope |
|----------|-------|
| `~/.claude/skills/` | Personal, all projects |
| `.claude/skills/` | Project, shared via git |
| Plugin skills | Via installed plugins |

### How They Work

1. Skill **descriptions** are always loaded (so Claude knows what's available) — costs ~2% of context
2. Full skill **content** only loads when triggered — the expensive part is on-demand
3. Skills can include supporting files (templates, scripts, examples)
4. Skills can define scoped hooks that only run while the skill is active

### Skills vs CLAUDE.md

| | CLAUDE.md | Skills |
|---|----------|--------|
| Loaded | Always, every message | On-demand |
| Purpose | "Always follow these rules" | "Here's how to do X when asked" |
| Token cost | Every message | Only when triggered |
| Best for | Universal project rules | Specialized workflows |

**Rule of thumb:** If it's a rule, put it in CLAUDE.md. If it's a workflow, make it a skill.

### Popular Skills

From the official marketplace and community:
- Language-specific LSP (TypeScript, Python, Swift, etc.)
- `/commit` — standardized commit workflows
- `/review` — code review checklists
- `/deploy` — deployment procedures
- `/debug` — structured debugging
- `/simplify` — code quality review

### CC-Beeper Opportunity

A **Skills Browser** showing:
- Installed skills (personal + project) with descriptions
- Toggle on/off
- "Browse available skills" linking to marketplaces
- Skill health: "3 skills loaded, using ~400 tokens for descriptions"

---

## 5. Hooks — Automated Guards

*(Covered in depth in HOOKS-DEEP-RESEARCH.md)*

**The key insight for Setup Inspector:** Hooks are the ONE extension type with **zero token cost** — they run externally and only add to context if they explicitly return output. They're the best ROI configuration option.

### CC-Beeper Opportunity

The full Hook Manager with 20 presets — this is already designed. The Setup Inspector just needs a summary view:
- "You have 3 hooks active: dangerous command blocker, auto-format, smart approve"
- Green/red status per hook
- "No hooks configured — consider adding safety guards"

---

## 6. Plugins — Install & Forget

### What They Are

Plugins bundle skills, hooks, MCP servers, and commands into a single installable package. They're the easiest way to add capabilities.

### How to Install

The absolute simplest path:
1. Open Claude Code
2. Type `/plugin`
3. Go to **Discover** tab
4. Browse and install
5. Run `/reload-plugins`

No terminal editing, no file manipulation.

### What Everyone Should Install First

From the official Anthropic marketplace:

1. **Your language's LSP plugin** (typescript-lsp, pyright-lsp, swift-lsp) — gives Claude real-time type checking
2. **github** — lets Claude read/write issues and PRs
3. **commit-commands** — streamlines git workflows

### Plugin Categories

| Category | Examples |
|----------|---------|
| **Code Intelligence** | TypeScript, Python, Rust, Go, Swift, Java LSP plugins |
| **Integrations** | GitHub, GitLab, Jira, Linear, Figma, Slack, Sentry |
| **Workflows** | commit-commands, pr-review-toolkit, feature-dev |
| **Output Styles** | explanatory-output, learning-output |
| **Security** | security-guidance (monitors 9 patterns in PreToolUse) |

### Where to Discover

- `/plugin` in Claude Code (Discover tab)
- [aitmpl.com](https://www.aitmpl.com/) — 1000+ components
- [skillsmp.com](https://skillsmp.com/) — agent skills marketplace
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — curated list

### CC-Beeper Opportunity

A **Plugin Overview** showing:
- Installed plugins with status (enabled/disabled)
- "4 plugins active, providing 12 skills and 3 hooks"
- Quick toggle on/off
- Link to discover more

---

## 7. MCP — External Connections

### What It Is

MCP (Model Context Protocol) connects Claude to external tools — GitHub, databases, Figma, Slack, etc. Think of it as USB cables between Claude and other software.

### How They're Configured

In settings.json or `.mcp.json`:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["@github/mcp-server"]
    }
  }
}
```

Or via CLI: `claude mcp add github -- npx @github/mcp-server`

### Token Cost

- Tool **names** are deferred by default (loaded lazily)
- Tool **definitions** expand when first used
- Each connected MCP server adds some baseline overhead

### CC-Beeper Opportunity

An **MCP Status** panel showing:
- Connected servers with health status (green/red)
- "3 MCP servers: Figma (connected), GitHub (connected), Sentry (error)"
- Tool count per server

---

## 8. Session Management — The #1 Skill

### The Most Important Habit

**Start each task with a clean session.** This is the single highest-impact thing you can do. Stale context from a previous task wastes tokens and degrades quality on the current task.

### /clear vs /compact vs New Session

| Action | When to Use |
|--------|------------|
| `/clear` | Between unrelated tasks. After correcting Claude twice on the same issue. |
| `/compact` | At natural breakpoints. BEFORE quality degrades, not after. Every 15-50 messages. |
| `/compact [focus]` | "Focus on the API changes" — tell Claude what to preserve. |
| New session | Completely different task. Want fresh perspective. |

### The Degradation Pattern

Claude doesn't fail suddenly. Signs of context overload:
- Repetitive summaries
- Inconsistent naming
- Earlier instructions being ignored
- Vaguer responses, more hedging
- Re-reading files it already read

**If you see these:** Run `/compact` immediately. If that doesn't help, `/clear` and start fresh with a better prompt.

### Context Usage Thresholds

| Usage | Status | Action |
|-------|--------|--------|
| 0-60% | Green | Working well |
| 60-75% | Yellow | Consider `/compact` at next natural break |
| 75-90% | Orange | `/compact` now |
| 90%+ | Red | Auto-compaction fires (you've lost control of what's preserved) |

### CC-Beeper Opportunity

A **Context Gauge** on the LCD:
- Visual fill indicator (like a battery)
- Color-coded: green → yellow → orange → red
- Nudge notification at 70%: "Context filling up — consider /compact"
- Critical alert at 90%: "Context critical — compacting now will lose data"

---

## 9. Token Cost of Everything

### The Comprehensive Cost Table

| Feature | Token Cost | When Charged | Worth It? |
|---------|-----------|--------------|-----------|
| **CLAUDE.md** (200 lines) | ~2-4K tokens | Every message | Almost always |
| **Skill descriptions** | ~2% of context | Always loaded | Yes, cheap |
| **Skill full content** | Variable | On demand | Yes, on-demand is efficient |
| **Hooks** | Zero | Run externally | Always — best ROI |
| **MCP tool names** | Small, deferred | On first use | Yes if you use the tool |
| **Permission prompts** | Small per prompt | Each approval | Reduce with allow rules |
| **File reads** | 5-10K per large file | Each read | Use subagents for big files |
| **Command output** | Variable | Each command | Pipe through grep to reduce |
| **Extended thinking** | ~32K default | Each response | Reduce with `/effort` |
| **Conversation history** | Accumulates | Every message | Manage with `/compact` |

### The Improvement vs Cost Equation

```
CLAUDE.md:    High improvement, moderate cost    → Always use
Skills:       High improvement, low cost         → Use for recurring workflows
Hooks:        High improvement, zero cost        → Always use
Plugins:      Variable improvement, variable cost → Install what you need
MCP:          High improvement, moderate cost     → Only for tools you use daily
```

### CC-Beeper Opportunity

A **Token Budget Dashboard**:
- "Your CLAUDE.md costs ~2,100 tokens per message"
- "3 skills loaded, ~400 tokens for descriptions"
- "Hooks: zero token cost"
- "MCP: 2 servers, ~800 tokens for tool definitions"
- "Total fixed overhead: ~3,300 tokens per message"
- Recommendations: "Your CLAUDE.md is 340 lines (Level L2). Consider splitting into rules/ for path-scoped loading."

---

## 10. Boris Cherny's Key Insights

*From [howborisusesclaudecode.com](https://howborisusesclaudecode.com) — 57 tips across 8 threads (Jan–Mar 2026). Boris created Claude Code.*

### The #1 Tip: Verification

> "Probably the most important thing to get great results out of Claude Code — give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result."

This directly validates CC-Beeper's Stop Guard (test gate) and AI Stop Guard presets. Verification is the difference between "Claude says it's done" and "Claude proved it's done."

### CLAUDE.md as Living Infrastructure

Boris's team practice: **"Anytime we see Claude do something incorrectly, add it to the CLAUDE.md."** End corrections with "Update your CLAUDE.md so you don't make that mistake again." Claude is "eerily good at writing rules for itself."

They also tag `@.claude` in PR reviews to add learnings directly via the GitHub Action. This is "Compounding Engineering" — every mistake makes the system smarter.

**CC-Beeper angle:** A "Quick Add to CLAUDE.md" action. When something goes wrong, one tap to append a rule. The CLAUDE.md viewer shows what's there; this lets you grow it naturally.

### Auto Mode — The Official "Guarded YOLO"

```bash
claude --enable-auto-mode
# Or cycle with shift+tab: plan → auto → normal
```

A classifier model evaluates each action before it runs. Safe operations get auto-approved, risky ones still get flagged. Boris: "no 👏 more 👏 permission prompts 👏"

**CC-Beeper angle:** The Permission Spectrum should integrate with Auto Mode as its recommended middle tier:
- Normal → Auto Mode → Guarded YOLO (Auto + CC-Beeper hooks) → YOLO

### /sandbox — File & Network Isolation

```
> /sandbox
```

OS-level sandboxing that isolates Claude's file and network access. Three modes: sandbox with auto-allow, sandbox with regular permissions, no sandbox.

**CC-Beeper angle:** Show sandbox status in the overview. "Sandbox: OFF — Claude has full filesystem access."

### /dream — Memory Cleanup

Auto-dream runs a subagent that reviews past sessions, keeps what matters, removes stale entries, and merges insights into cleaner structured memory. Named after how REM sleep consolidates short-term memory.

**CC-Beeper angle:** Show memory health. "Your auto-memory has 47 entries. Last dream: 3 days ago. Consider running /dream."

### /simplify and /batch — Built-In Quality & Migration

- `/simplify` runs parallel agents to review changed code for reuse, quality, and efficiency. Boris uses it daily.
- `/batch` plans code migrations interactively, then fans out to parallel agents with worktree isolation.

**CC-Beeper angle:** Could add a "Run /simplify after every task" toggle (PostToolUse or Stop hook that injects the command).

### /loop and /schedule — Recurring Tasks

- `/loop` runs a prompt on an interval for up to 3 days (local)
- `/schedule` runs recurring cloud jobs even when your laptop is closed

Use cases: PR babysitting, Slack summaries, deploy monitoring, doc updates.

**CC-Beeper angle:** Show active loops/schedules in the overview. "2 active: PR babysitter (every 30min), Slack digest (daily 9am)."

### /btw — Side Questions Without Breaking Flow

```
> /btw what does the retry logic do?
```

Single-turn, no tool calls, but has full conversation context. Claude responds inline without stopping work.

**CC-Beeper angle:** A quick-input field on the pager for `/btw` questions — ask without switching to the terminal.

### /effort max — Deep Reasoning

Four levels: low, medium (default), high, max. Max uses as many tokens as needed for hard debugging and architecture decisions. Burns limits faster.

**CC-Beeper angle:** Show current effort level. Let the user toggle from the pager.

### Parallel Work is the #1 Unlock

Boris: "The single biggest productivity unlock. Spin up 3-5 git worktrees at once."

- Name worktrees, color-code terminal tabs
- Have a dedicated "analysis" worktree for reading logs
- Use iTerm2 notifications to know when any Claude needs attention

**CC-Beeper angle:** CC-Beeper IS the notification layer. Multi-session awareness (which session needs you, which is working, which is done) is already core.

### iMessage Plugin

Claude Code is now a contact in your Messages app. Text it tasks from iPhone/iPad/Mac.

**CC-Beeper angle:** Claude Code is going multi-channel (terminal, desktop, web, mobile, iMessage). CC-Beeper's companion role gets MORE relevant as the surface area grows — it's the one place that shows all sessions regardless of channel.

### PostCompact Hook

Fires after context compaction. Use it to re-inject critical instructions that get lost.

**CC-Beeper angle:** Directly validates the Context Re-injection preset hook.

### Boris's Model Advice

Use Opus with thinking for everything. "Even though it's bigger & slower than Sonnet, since you have to steer it less and it's better at tool use, it is almost always faster."

### Boris's Key Workflow

```
Plan Mode → Refine plan → Auto-accept edits → Claude 1-shots it
```

"A good plan is really important to avoid issues down the line." If something goes sideways, switch BACK to plan mode and re-plan.

---

## 11. What This Means for CC-Beeper

### The Core Insight

**Most Claude Code users don't know what's in their `.claude/` folder, and it's heavily affecting every session.** The terminal makes this invisible. A GUI makes it visible.

### CC-Beeper Settings: Feature Map

#### Overview (read-only dashboard)

A single-screen health check of your Claude Code environment:

| Item | What It Shows | Health Color |
|------|---------------|-------------|
| CLAUDE.md | Line count, level (L0-L6), token cost | Red if missing, yellow if >200 lines |
| Skills | Count, token cost for descriptions | Green if any, neutral if none |
| Hooks | Count, active/error status | Yellow if none ("no safety guards") |
| Plugins | Installed count, enabled/disabled | Green if any, neutral if none |
| MCP Servers | Connected count, health per server | Red if any erroring |
| Permission Mode | Current mode in plain English | Neutral (informational) |
| Sandbox | On/off, isolation level | Yellow if off |
| Context | Current usage % | Green→yellow→orange→red |
| Memory | Entry count, last /dream date | Yellow if stale |
| Active Loops | Count and descriptions | Neutral |
| Effort Level | Current setting | Neutral |

Plus warnings:
- "No CLAUDE.md — Claude is flying blind"
- "No .claudeignore — Claude may read build artifacts"
- "No hooks — consider safety guards"
- "CLAUDE.md is 340 lines — consider splitting into rules/"
- "Auto-memory has 47 entries, last dream 3 days ago"

#### CLAUDE.md (view + edit)

- Show contents of all CLAUDE.md files (global + project + local + rules)
- Label which scope each section comes from
- Line count and estimated token cost per file
- Maturity level indicator (L0-L6)
- "Quick Add" — append a rule from anywhere in the app
- Simple text editor for edits
- "Generate starter" (runs `/init`)

#### Permissions

- Current permission mode with plain-English explanation
- Active allow/deny rules, grouped by scope (global / project / local)
- Suggested additions based on approval patterns
- One-click common patterns ("Allow all git reads", "Allow npm test")
- Auto Mode integration

#### Hooks (the full manager)

- The 20 presets from HOOKS-DEEP-RESEARCH.md
- Toggle on/off per preset
- Custom hook builder (pick event → matcher → if condition → command)
- Permission Spectrum selector (Normal / Auto / Guarded YOLO / YOLO)
- Active hook status (green/red per hook)
- Hook performance stats

#### Extensions (read-only)

- Installed skills with descriptions
- Installed plugins with enabled/disabled status
- Connected MCP servers with health
- Token cost per extension
- "Discover more" links

### What NOT to Build

- Full plugin marketplace (Anthropic owns this)
- Deep plugin configuration (too project-specific)
- Agent/subagent management (too niche)
- CLAUDE.md AI generator (users should write their own rules — Boris says Claude is good at writing them for itself when asked)

### Build Order

1. **Hooks Manager** — the moat, nobody else builds this
2. **Overview** — read-only, cheap, immediate "aha" for new users
3. **CLAUDE.md Viewer** — makes the invisible visible, add editor later
4. **Permissions Panel** — reduces the #1 daily friction (permission fatigue)
5. **Extensions** — read-only, shows what's installed

---

## Sources

### Official Anthropic
- [Memory & CLAUDE.md](https://code.claude.com/docs/en/memory)
- [Settings Reference](https://code.claude.com/docs/en/settings)
- [Permissions](https://code.claude.com/docs/en/permissions)
- [Permission Modes](https://code.claude.com/docs/en/permission-modes)
- [Skills](https://code.claude.com/docs/en/skills)
- [Plugins](https://code.claude.com/docs/en/plugins)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [MCP](https://code.claude.com/docs/en/mcp)
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Cost Management](https://code.claude.com/docs/en/costs)
- [Auto Mode](https://www.anthropic.com/engineering/claude-code-auto-mode)

### Community
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [awesome-claude-md](https://github.com/josix/awesome-claude-md)
- [claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice)
- [claude-code-ultimate-guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide)
- [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) — 1000+ skills
- [aitmpl.com](https://www.aitmpl.com/) — component directory

### Boris Cherny (Creator of Claude Code)
- [howborisusesclaudecode.com](https://howborisusesclaudecode.com) — 57 tips, v3.0.0 (2026-03-26)
- [boris-SKILL.md](https://howborisusesclaudecode.com/api/install) — installable skill compiled by @CarolinaCherry
- Parts 1-8 (Jan–Mar 2026) covering parallel work, plan mode, CLAUDE.md, skills, hooks, permissions, MCP, plugins, agents, sandboxing, auto mode, /schedule, iMessage, auto-memory, /dream

### Blog Posts
- [HumanLayer — Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Builder.io — How to Write a Good CLAUDE.md](https://www.builder.io/blog/claude-md-guide)
- [Builder.io — 50 Claude Code Tips](https://www.builder.io/blog/claude-code-tips-best-practices)
- [Dometrain — Creating the Perfect CLAUDE.md](https://dometrain.com/blog/creating-the-perfect-claudemd-for-claude-code/)
- [DEV.to — CLAUDE.md Best Practices](https://dev.to/cleverhoods/claudemd-best-practices-from-basic-to-adaptive-9lm)
- [eesel AI — settings.json Guide](https://www.eesel.ai/blog/settings-json-claude-code)
- [Claude Lab — settings.json Complete Guide](https://claudelab.net/en/articles/claude-code/claude-code-settings-json-complete-guide)
- [Shipyard — Tokens Explained](https://shipyard.build/blog/claude-code-tokens/)
