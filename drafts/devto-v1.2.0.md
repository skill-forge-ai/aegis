# Aegis v1.2.0: Quality Guardrails for AI-Assisted Development — Now with Cross-Workspace Support

## Draft DEV.to Article

**Title:** Aegis v1.2.0: Quality Guardrails That Scale Across Workspaces

**Tags:** ai, agentskill, coding, opensource

**Body:**

---

AI writes code at 100x speed. But without guardrails, it also breaks things at 100x speed.

## The Problem Gets Worse at Scale

If you've used AI coding agents (Claude Code, Codex, Cursor, Gemini CLI), you've probably noticed:

- **Frontend agent assumes one API format, backend agent implements another.** Integration day is a bloodbath.
- **Mock-based tests give false confidence.** Both sides "pass" their tests. Neither works with the other.
- **Contracts drift silently.** Agent A adds a field, Agent B doesn't know, Agent C picks a random default.

These problems get exponentially worse when **agents work in separate workspaces** — a reality for any serious team where frontend and backend are separate repos, managed by separate agents.

## Aegis: Five Layers of Defense

[Aegis](https://github.com/skill-forge-ai/aegis) is an open-source AgentSkill that enforces structured quality at every phase:

```
Layer 0: Automated Guardrails  ← lint, type-check, format (pre-commit + CI)
Layer 1: Design                ← Design Brief before any code
Layer 2: Contract              ← OpenAPI spec + shared types + error codes
Layer 3: Implementation        ← Code against contract, not freestyle
Layer 4: Verification          ← Contract tests → Integration → E2E
Layer 5: PM                    ← Gap tracking, quality gates
```

**The key insight:** Contract-first development isn't just a nice practice — it's the *only* reliable coordination mechanism between AI agents that can't talk to each other.

## What's New in v1.2.0: Cross-Workspace Intelligence

### Workspace Architecture Detection

Aegis now auto-detects your project structure before entering the workflow:

- **Monorepo** — frontend + backend in one repo → contract lives inside the project
- **Split Workspace** — only one side in this workspace → prompts you to clarify the setup
- **Cross-Agent, Cross-Workspace** — different agents, different repos → activates the dedicated contract protocol

No configuration needed. Aegis scans your directory structure and asks when it's not sure.

### Cross-Workspace Contract Protocol

For projects where frontend and backend are truly separate:

1. **Dedicated Contract Repository** — an independent Git repo that holds the API spec, shared types, and error codes. Both agents pull from it. Neither can modify it unilaterally.

2. **Three Integration Methods:**
   - Git submodule (version-locked, auditable)
   - Package registry (semantic versioning)
   - Copy-sync by lead (zero setup, fast start)

3. **Contract Change Requests** — when an agent discovers the contract is wrong, it files a CR instead of editing directly. The lead reviews and propagates changes to all agents.

4. **Test Isolation** — each side runs its own contract tests independently. Integration testing is orchestrated separately.

## Quick Start

### Claude Code

```bash
git clone https://github.com/skill-forge-ai/aegis.git
cp -r aegis/cc-skill ~/.claude/skills/aegis
```

### ClawHub

```bash
npx clawhub install aegis-quality-guardian
```

### OpenClaw

```bash
git clone https://github.com/skill-forge-ai/aegis.git /path/to/skills/aegis
```

Then initialize any project:

```bash
bash ~/.claude/skills/aegis/scripts/init-project.sh /path/to/your/project
```

This creates `contracts/`, `docs/designs/`, pre-commit hooks, CI pipeline, and an enhanced `CLAUDE.md`.

## What's Included

- **SKILL.md** — complete 5-phase workflow with workspace detection
- **8 templates** — Design Brief, CLAUDE.md, OpenAPI starter, shared types, error codes, integration compose, etc.
- **6 scripts** — project init, guardrail setup, stack detection, contract validation, gap report, type generation
- **3 reference guides** — contract-first development, testing strategy, multi-agent protocol with cross-workspace support
- **Self-contained CC skill package** — works with Claude Code out of the box

## Why Open Source?

AI development is evolving fast. Quality guardrails need to evolve just as fast — and that takes a community. Aegis is MIT licensed. Use it, fork it, improve it.

If you have ideas for new layers, better detection heuristics, or support for more languages — [contributions are welcome](https://github.com/skill-forge-ai/aegis/blob/main/CONTRIBUTING.md).

---

**GitHub:** https://github.com/skill-forge-ai/aegis
**ClawHub:** `npx clawhub install aegis-quality-guardian`
**Release:** https://github.com/skill-forge-ai/aegis/releases/tag/v1.2.0
