# Aegis — AI Development Quality Guardian

> _"Move fast, but don't break the blueprint."_

**Aegis** (Greek: the divine shield of Zeus and Athena) is an AgentSkill for [OpenClaw](https://github.com/nicepkg/openclaw) that brings structured quality assurance to AI-assisted software development.

AI writes code at the speed of thought. Aegis makes sure the thoughts are correct.

---

## The Problem

AI-assisted development is fast — dangerously fast. As projects grow, things quietly fall apart:

- **Design gaps accumulate silently** — each AI agent sees only its slice, nobody holds the full picture
- **Mock testing creates illusions** — frontend and backend mock each other, tests pass, integration explodes
- **Context drifts across agents** — parallel agents develop divergent understandings of the same interface
- **The code isn't yours** — debugging AI-generated code feels like inheriting a stranger's project
- **Constraints are too loose** — `CLAUDE.md` alone isn't enough to prevent architectural drift

## The Solution: Five-Layer Defense

```
┌─────────────────────────────────────────────────────────┐
│              Layer 5: Project Management                  │
│           PM Tool Integration — Tracking + Gap Mgmt      │
├─────────────────────────────────────────────────────────┤
│              Layer 4: Verification                        │
│      Contract Test → Integration Test → E2E Test         │
├─────────────────────────────────────────────────────────┤
│              Layer 3: Implementation                      │
│   CLAUDE.md Constraints + Dispatch Protocol + Review     │
├─────────────────────────────────────────────────────────┤
│              Layer 2: Contract                            │
│      API Spec + Shared Types + Event Schema              │
├─────────────────────────────────────────────────────────┤
│              Layer 1: Design                              │
│           Design Brief + Architecture Doc                │
└─────────────────────────────────────────────────────────┘
```

Each layer addresses a specific failure mode. Together, they form a complete quality shield.

## Quick Start

### Option A: Claude Code (CC) Users

```bash
# One-liner: clone the cc-skill folder into your CC skills directory
git clone https://github.com/skill-forge-ai/aegis.git /tmp/aegis-clone \
  && cp -r /tmp/aegis-clone/cc-skill ~/.claude/skills/aegis \
  && rm -rf /tmp/aegis-clone

# Verify installation
ls ~/.claude/skills/aegis/SKILL.md
```

Or manually:
1. Download/clone this repo
2. Copy `cc-skill/` → `~/.claude/skills/aegis/`
3. Done — Claude Code will auto-detect the skill

Then initialize Aegis in your project:
```bash
bash ~/.claude/skills/aegis/scripts/init-project.sh /path/to/your/project
```

### Option B: OpenClaw Users

```bash
# Clone into your OpenClaw skills directory
git clone https://github.com/skill-forge-ai/aegis.git ~/.openclaw/workspace/skills/aegis
```

### Option C: Other Agents (Codex, Gemini CLI, Cursor, etc.)

Any agent that supports the AgentSkill spec can use Aegis:
1. Clone the repo or copy the `cc-skill/` folder to your agent's skill path
2. Point your agent at the `SKILL.md` file
3. Run `init-project.sh` on your project

### Initialize a Project

```bash
# Run the init script in your project root
bash ~/.openclaw/workspace/skills/aegis/scripts/init-project.sh /path/to/your/project
```

This creates:
```
your-project/
├── contracts/
│   ├── api-spec.yaml          # OpenAPI 3.1 spec
│   ├── shared-types.ts        # Shared type definitions
│   └── errors.yaml            # Error code definitions
├── docs/
│   └── designs/               # Design Briefs go here
└── CLAUDE.md                  # Enhanced with Aegis constraints
```

### 3. Start Building

Follow the workflow:

```
Design Brief → Contract → Implementation → Verification → Delivery
```

See [SKILL.md](./SKILL.md) for the complete workflow reference.

## Modes

| | Lite Mode | Full Mode |
|---|-----------|-----------|
| **Use for** | Small features, single-stack | Large features, full-stack |
| **Design Brief** | Simplified | Complete |
| **Contract** | ✅ Required | ✅ Required |
| **Contract Test** | ✅ Required | ✅ Required |
| **Integration Test** | Optional | ✅ Required |
| **E2E Test** | Optional | ✅ Required |

## Templates

- [`templates/design-brief.md`](./templates/design-brief.md) — Design Brief template
- [`templates/claude-md.md`](./templates/claude-md.md) — Enhanced CLAUDE.md template
- [`templates/api-spec-starter.yaml`](./templates/api-spec-starter.yaml) — OpenAPI starter
- [`templates/shared-types-starter.ts`](./templates/shared-types-starter.ts) — Shared types starter

## How It Works

### For Solo Developers
Aegis acts as your quality co-pilot. Write a Design Brief before coding, define contracts for your APIs, and let contract tests catch drift before it becomes a bug.

### For Multi-Agent Workflows
Aegis becomes the coordination layer. All agents share the same contract. No agent can modify the contract unilaterally — changes go through a review process, ensuring everyone stays aligned.

```
                 ┌──────────────┐
                 │  Lead Agent   │
                 │ (holds contract)│
                 └──────┬───────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
     ┌─────▼─────┐ ┌───▼───┐ ┌─────▼─────┐
     │  Frontend  │ │Contract│ │  Backend   │
     │  Agent     │ │  Repo  │ │  Agent     │
     └───────────┘ └───────┘ └───────────┘
```

## Integration

Aegis works with your existing tools:

| Tool | Integration |
|------|-------------|
| **Claude Code** | Native skill (`cc-skill/`) — copy to `~/.claude/skills/aegis/` |
| **OpenClaw** | Native AgentSkill (full repo) |
| **Codex / Gemini CLI / Cursor** | Compatible via AgentSkill spec |
| **Playwright** | E2E verification layer |
| **GitHub Actions / GitLab CI** | CI pipeline templates (auto-generated) |

## Philosophy

1. **Contract-first** — Define the interface before writing the implementation
2. **Mock only at the bottom** — Unit tests can mock; everything above uses real services
3. **Gaps are first-class citizens** — Track them, triage them, resolve them
4. **Design Briefs are for humans** — AI writes code fast; humans need to understand what's being built
5. **Progressive strictness** — Lite mode for small stuff, Full mode for critical paths

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) before submitting a PR.

## License

[MIT](./LICENSE)

---

_Development under Aegis — AI helps you build, Aegis makes sure it stands._
