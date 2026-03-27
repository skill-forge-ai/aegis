---
name: aegis
description: >
  AI Development Quality Guardian — contract-driven, design-first quality guardrails
  for AI-assisted full-stack development. Five-layer defense: Design → Contract →
  Implementation → Verification → PM. Prevents project chaos at scale.
  Activate when: starting a feature, setting up a project, dispatching coding tasks,
  reviewing PRs, or managing multi-agent workflows. Also triggers on projects with
  a contracts/ directory (implementation guardrails auto-activate).
---

# Aegis — AI Development Quality Guardian

> Five-layer defense for AI-assisted software development.

## Modes

### Lite Mode (Default for small tasks)
- Design Brief only → straight to implementation
- Use when: solo dev, single-service feature, quick fix

### Full Mode (Multi-service / team projects)
- Complete contract-first workflow
- Use when: multiple API boundaries, team collaboration, complex features

---

## Phase 1: Design

Before any non-trivial feature, create a Design Brief:

1. Read `templates/design-brief.md` for the template
2. Fill in: Problem Statement, Architecture Overview, Key Decisions, Module Boundaries, API Surface, Known Gaps, Testing Strategy
3. Submit for human review
4. **Gate:** Do not proceed to Phase 2 until Design Brief is approved

**Lite Mode stops here** — proceed to Phase 3 after Design Brief approval.

## Phase 2: Contract (Full Mode)

Define the API contract before writing implementation code:

1. Create/update `contracts/api-spec.yaml` (OpenAPI 3.1) — use `templates/api-spec-starter.yaml` as base
2. Create/update `contracts/shared-types.ts` — use `templates/shared-types-starter.ts` as base
3. Create/update `contracts/errors.yaml` — use `templates/errors-starter.yaml` as base
4. Run `bash scripts/validate-contract.sh <project-path>` to check consistency
5. **Gate:** Contracts must be reviewed before implementation begins

Reference: `references/contract-first-guide.md` for the full contract-first methodology.

## Phase 3: Implementation

### Pre-Coding Checklist (EVERY TIME before writing code)

1. Check if `contracts/` exists in the project root
2. If yes: read `contracts/api-spec.yaml`, `contracts/errors.yaml`, `contracts/shared-types.ts`
3. Read `CLAUDE.md` for project-specific constraints
4. If a Design Brief exists for your task: read `docs/designs/` relevant file

### Hard Rules (violation = PR rejected)

**R1: Contract is the truth**
- All API responses MUST conform to `contracts/api-spec.yaml`
- Response shapes, status codes, field names — all from the spec

**R2: Shared types — import, never redefine**
- `import { User, ApiResponse } from '../contracts/shared-types'`
- NEVER create local types that shadow contract types
- If shared-types doesn't have what you need → file a Change Request (R5)

**R3: Error codes from registry only**
- Use codes defined in `contracts/errors.yaml`
- Never invent ad-hoc error codes
- Need a new code → file a Change Request (R5)

**R4: Contract tests mandatory**
- Every new API endpoint MUST have a contract test
- Contract test = validate real response against OpenAPI spec schema
- Modified endpoints → update contract test

**R5: Never modify contracts directly**
If the contract needs changes:
1. Create `docs/contract-changes/CHANGE-{date}-{description}.md`
2. Include: what, why, which modules affected
3. Continue implementing with the CURRENT contract
4. Human reviews and updates the contract

**R6: CLAUDE.md constraints**
- Read and follow all ⛔ Hard Constraints in CLAUDE.md
- These are project-specific and override general preferences

**R7: Pre-commit checks are mandatory**
- Run lint → type-check → format-check → contract validation before committing
- After ALL code changes, run formatters as a final step
- Never bypass with `--no-verify`

### Quick Reference

| Situation | Action |
|-----------|--------|
| Need a new endpoint | Check api-spec.yaml first |
| Need a new type | Check shared-types.ts → if missing, Change Request |
| Need a new error code | Check errors.yaml → if missing, Change Request |
| API response doesn't match spec | Fix code, not spec |
| Spec seems wrong | Change Request, implement per current spec |
| No contracts/ directory | Hard rules don't apply — standard development |

## Phase 4: Verification

After implementation, validate quality:

1. Run contract tests — `bash scripts/validate-contract.sh <project-path>`
2. Generate gap report — `bash scripts/gap-report.sh <project-path>`
3. Review: are all Design Brief items implemented?
4. Review: do all endpoints have contract tests?
5. **Gate:** All contract tests must pass before PR/MR

### Testing Hierarchy

```
Unit Test         ← Mock external deps, test pure logic
Contract Test     ← Validate against api-spec.yaml (NO mocking the contract)
Integration Test  ← Real services via docker-compose.integration.yml
```

Reference: `references/testing-strategy.md` for the full testing pyramid.

## Phase 5: PM

Track progress and enforce quality gates:

1. Update `docs/designs/<feature>/implementation-summary.md` — use `templates/implementation-summary.md`
2. Mark Design Brief items as completed
3. Note any contract Change Requests filed during implementation
4. Release readiness check: all gates passed?

---

## Project Setup

Initialize Aegis in any project:

```bash
bash scripts/init-project.sh /path/to/project
```

This creates:
- `contracts/` — API spec, shared types, error codes (stack-aware)
- `docs/designs/` — for Design Briefs
- `.aegis/` — portable validation scripts
- `CLAUDE.md` — from Aegis template (if not existing)
- `docker-compose.integration.yml` — auto-detects your database

Set up guardrails (pre-commit hooks + CI):

```bash
bash scripts/setup-guardrails.sh /path/to/project --ci github  # or --ci gitlab
```

---

## Multi-Agent Protocol

When multiple agents work on the same project:
- Each agent reads contracts before starting
- Contracts are the synchronization point — not code
- Change Requests prevent concurrent contract modifications
- Reference: `references/multi-agent-protocol.md`

## File Structure

```
~/.claude/skills/aegis/          # ← You are here (CC skill)
├── SKILL.md                     # This file
├── templates/                   # Project templates
│   ├── design-brief.md
│   ├── claude-md.md
│   ├── api-spec-starter.yaml
│   ├── shared-types-starter.ts
│   ├── errors-starter.yaml
│   ├── contract-test-example.ts
│   ├── docker-compose.integration.yml
│   └── implementation-summary.md
├── scripts/                     # Automation
│   ├── init-project.sh          # Initialize Aegis in a project
│   ├── setup-guardrails.sh      # Pre-commit + CI setup
│   ├── detect-stack.sh          # Auto-detect language/framework
│   ├── validate-contract.sh     # Validate contract consistency
│   ├── gap-report.sh            # Design Brief vs implementation gaps
│   └── generate-types.sh        # Generate types from OpenAPI spec
└── references/                  # Deep-dive guides
    ├── contract-first-guide.md
    ├── testing-strategy.md
    └── multi-agent-protocol.md
```
