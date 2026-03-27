---
name: aegis
description: >
  Contract-driven, design-first quality guardrails for AI-assisted full-stack development.
  Prevents project chaos at scale by enforcing a five-layer protection system: Design → Contract → Implementation → Verification → PM.
  Use when: starting a new full-stack project, planning a non-trivial feature, dispatching frontend/backend work to coding agents,
  coordinating multi-agent parallel development, setting up contract tests, or running integration/E2E verification.
  Triggers on: "aegis init", "design brief", "write contract", "contract test", "integration test", "aegis verify",
  "multi-agent coordination", "quality guardrails", "project setup with aegis".
---

# Aegis — AI Full-Stack Quality Guardrails

> _"AI writes code at the speed of thought. Aegis makes sure the thoughts are correct."_

Five-layer protection: **Design → Contract → Implementation → Verification → PM**.
Each layer catches a different class of failure. Skip none.

## Quick Start

Initialize Aegis structure in an existing project:

```bash
bash scripts/init-project.sh /path/to/project
```

This creates:
- `contracts/` — API spec, shared types, error codes, event schemas
- `docs/designs/` — Design Brief storage
- Updates `CLAUDE.md` with Aegis constraints (if exists, appends; if not, creates from template)

## Workflow Overview

```
Peter 提需求
  → [L1] Write Design Brief (docs/designs/NNN-feature.md)
  → Peter Review → approve / revise
  → [L2] Write Contract (contracts/api-spec.yaml + shared-types)
  → Peter Review → approve / revise
  → [L3] Dispatch CC with Aegis constraints (CLAUDE.md + contract + brief)
  → CC implements → Contract Test must pass
  → [L4] Integration Test → E2E Test (playwright-forge)
  → [L5] Update PM tracking (Jira/scrum), close gaps
  → PR with Implementation Summary → merge
```

## Layer 1: Design

Before any non-trivial feature, produce a Design Brief.

### Write a Design Brief

Use template: `templates/design-brief.md`

```bash
cp templates/design-brief.md docs/designs/NNN-feature-name.md
```

Fill in: Problem Statement, Architecture Overview (Mermaid/ASCII), Key Design Decisions,
Module Boundaries, API Surface (summary), Known Gaps, Testing Strategy, Debugging Guide.

**Every gap must be tagged:** `blocking` (stops downstream work) or `non-blocking` (can defer).

### Implementation Summary

After CC completes work, produce an Implementation Summary (attach to PR).
Use template: `templates/implementation-summary.md`

Covers: Design conformance (✅/⚠️), File map, New gaps discovered, Debug cheatsheet.

## Layer 2: Contract

Contract = single source of truth shared by all agents and humans.

### Project Contract Structure

```
contracts/
├── api-spec.yaml          # OpenAPI 3.1 — REST API contract
├── shared-types.ts        # Auto-generated from api-spec (DO NOT EDIT MANUALLY)
├── events.schema.json     # WebSocket / async event schemas
└── errors.yaml            # Unified error codes
```

### Rules

1. **Contract before code** — write/update contract before implementation.
2. **Contract is the only truth** — frontend types and backend responses must match.
3. **No unilateral changes** — any agent wanting to change contract must file a Change Request. Lead reviews, then updates and notifies all agents.
4. **Contract is executable** — validated by OpenAPI tools + TypeScript compiler.

### Contract Change Protocol

When an agent discovers the contract needs modification:

1. Agent writes a Contract Change Request: what, why, which modules affected.
2. Lead (Forge) reviews.
3. Approved → update contract + notify all related agents.
4. Rejected → agent implements per original contract.

See `references/contract-guide.md` for detailed contract-first development guide.

## Layer 3: Implementation

CC must build according to design + contract, not freestyle.

### CLAUDE.md Enhancement

Use template: `templates/claude-md.md`

Key sections to enforce:
- **Hard Constraints** (⛔) — violate = reject (contract conformance, no type redefinition, etc.)
- **Code Standards** (📋) — naming, structure, logging, error handling
- **Testing Requirements** (🧪) — contract tests mandatory for new APIs
- **Dependencies & Contracts** (🔗) — paths to contract files

### Dispatch Protocol

When dispatching CC tasks, inject:

1. `CLAUDE.md` (project constraints)
2. Relevant Design Brief
3. Contract file paths (tell CC to read them)
4. Code Lessons (from `code-lessons.md` if applicable)
5. Explicit acceptance criteria

See `references/dispatch-protocol.md` for the full prompt template.

### Multi-Agent Coordination

When frontend + backend run in parallel:

1. Both agents receive the same contract.
2. Agents never communicate directly — all coordination via contract + lead.
3. Contract Change Requests go through lead.
4. Recommended sequence: contract → backend → contract test → frontend → integration test.

See `references/multi-agent-protocol.md` for coordination rules.

## Layer 4: Verification

Graduate from mock illusions to real verification.

### Test Pyramid (AI-Dev Specialized)

```
        E2E Test              ← playwright-forge (real browser + real backend)
      Integration Test        ← docker compose (real frontend + backend + DB)
    Contract Test             ← each side validates against contract
  Unit Test                   ← pure logic (mocking allowed here only)
```

**Key principle: Mocking only at the bottom layer. Everything above is real.**

### Contract Tests

- **Backend (Provider):** Validate API responses against OpenAPI spec.
- **Frontend (Consumer):** Build test data from contract types, not ad-hoc mocks.

See `references/testing-strategy.md` for examples and docker-compose integration template.

### Integration & E2E

- Integration: `docker-compose.integration.yml` — spins up real services.
- E2E: Call playwright-forge for browser-level verification.
- CI pipeline: `lint → type-check → unit → contract → build → integration → E2E`

## Layer 5: Project Management

Track design, gaps, and delivery status.

### Gap Management

Every discovered gap → tracked issue (Jira, GitHub Issues, or markdown backlog):
- Source (which design brief or implementation)
- Impact scope
- Urgency: blocking / non-blocking
- Suggested fix

### Sprint Integration

Story subtasks follow Aegis phases:
`Design Review → Contract Definition → Backend Impl → Frontend Impl → Contract Test → Integration Test → E2E → Done`

A story cannot close until all test subtasks pass.

## Lite Mode vs Full Mode

| | Lite | Full |
|---|------|------|
| **When** | Small feature, single-stack | Large feature, multi-stack |
| Design Brief | Simplified (problem + solution + constraints) | Complete |
| Contract | ✅ Required | ✅ Required |
| Contract Test | ✅ Required | ✅ Required |
| Integration Test | Optional | ✅ Required |
| E2E Test | Optional | ✅ Required |
| Implementation Summary | PR description | Standalone doc |

## Scripts

- `scripts/init-project.sh <project-path>` — Initialize Aegis structure in a project
- `scripts/validate-contract.sh <project-path>` — Validate contract consistency
- `scripts/generate-types.sh <project-path>` — Generate shared types from OpenAPI spec

## Templates

- `templates/design-brief.md` — Design Brief template
- `templates/implementation-summary.md` — Post-implementation summary template
- `templates/claude-md.md` — Enhanced CLAUDE.md template with Aegis constraints
- `templates/api-spec-starter.yaml` — OpenAPI 3.1 starter spec
- `templates/shared-types-starter.ts` — Shared types starter (typically auto-generated)
- `templates/errors-starter.yaml` — Error code definition starter
- `templates/docker-compose.integration.yml` — Integration test compose template

## References

- `references/contract-guide.md` — Contract-first development deep dive
- `references/dispatch-protocol.md` — Full dispatch prompt template
- `references/multi-agent-protocol.md` — Multi-agent coordination rules
- `references/testing-strategy.md` — Testing strategy with examples

## CC Skill (Claude Code Side)

Aegis operates at two levels:
- **This skill (OpenClaw):** Flow orchestration — when to design, when to contract, when to verify
- **CC skill (`cc-skill/SKILL.md`):** Implementation discipline — CC auto-enforces contract rules while coding

Install the CC skill to `~/.claude/skills/aegis/SKILL.md` so CC has persistent Aegis awareness.
Without it, constraints only exist when manually injected into dispatch prompts — easy to forget, easy to skip.

**铁律：** CC 版 Aegis 是铁律级规则。项目有 `contracts/` 目录时无条件生效。
