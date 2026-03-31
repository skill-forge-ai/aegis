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
- `CLAUDE.md` with Aegis constraints
- `.aegis/pre-commit.sh` + `.git/hooks/pre-commit` — hard guardrails
- `.github/workflows/aegis-checks.yml` or `.gitlab-ci-aegis.yml` — CI pipeline
- Language-specific linter/formatter configs (auto-detected)

## Workspace Architecture Detection

Before entering the Aegis workflow, detect the project's architecture to choose the right contract strategy.

### Auto-Detection Logic

Run at `aegis init` or when first applying Aegis to a project:

1. **Scan workspace root** for indicators:
   - Both `frontend/` (or `client/`, `web/`, `app/`) AND `backend/` (or `server/`, `api/`, `services/`) directories → **Monorepo**
   - Only one side present (e.g., only `src/` with frontend framework) → **Split Workspace**
   - `package.json` with workspaces containing both frontend and backend → **Monorepo**
   - Single-stack indicators only (e.g., pure Go API, pure React app) → **Split Workspace**

2. **If Split Workspace detected**, ask the human:
   ```
   Detected: This workspace contains only {frontend|backend} code.
   Where does the other side live?
   
   (a) Another repo managed by the same agent (I can access it)
   (b) Another repo managed by a different agent/workspace (I cannot access it)
   (c) This is actually a monorepo (I missed something — please point me to the other side)
   ```

3. **Set architecture mode** based on detection + confirmation:

| Mode | Contract Location | Sync Method |
|------|------------------|-------------|
| **Monorepo** | `contracts/` in project root | Direct (same repo) |
| **Multi-Repo, Single Agent** | Lead workspace's `contracts/`, copied to each repo | Copy before dispatch |
| **Cross-Agent, Cross-Workspace** | Dedicated contract repository | Git submodule / package / lead copy-sync |

### Architecture Mode Effects

- **Monorepo:** Standard Aegis workflow — `contracts/` lives inside the project. All layers work as documented.
- **Multi-Repo, Single Agent:** Lead (Forge) maintains the contract in its own workspace. Before dispatching each CC task, latest contract files are copied into the target repo. CC treats `contracts/` as read-only.
- **Cross-Agent, Cross-Workspace:** Contract lives in an independent Git repository. Each agent's workspace integrates it via submodule, package, or copy-sync. Contract Change Requests go through the Lead who has merge rights on the contract repo. See `references/multi-agent-protocol.md` § Cross-Workspace Architecture for full protocol.

### CLAUDE.md Adjustment by Mode

The `templates/claude-md.md` contract section adapts based on mode:

- **Monorepo:** `contracts/` is writable by Lead, read-only for dispatched CC (standard)
- **Split/Cross:** Add explicit "Contract is external and read-only" constraint + Change Request instructions

## Workflow Overview

```
Peter 提需求
  → [L0] Auto-guardrails already installed (lint, type-check, format, contract validation)
  → [L1] Write Design Brief (docs/designs/NNN-feature.md)
  → Peter Review → approve / revise
  → [L2] Write Contract (contracts/api-spec.yaml + shared-types)
  → Peter Review → approve / revise
  → [L3] Dispatch CC with Aegis constraints (CLAUDE.md + contract + brief)
  → CC implements → pre-commit hook catches lint/type/format errors
  → Contract Test must pass
  → [L4] Integration Test → E2E Test (playwright-forge)
  → [L5] Update PM tracking (Jira/scrum), close gaps
  → PR with Implementation Summary → CI pipeline validates → merge
```

## Layer 0: Automated Guardrails (Machine-Enforced)

Hard checks that don't depend on AI judgment. Two enforcement points:
- **Pre-commit hook** — blocks bad commits locally
- **CI pipeline** — blocks bad PRs remotely

### Language-Adaptive Checks

Auto-detected by `scripts/detect-stack.sh`:

| Language | Lint | Type Check | Format | Additional |
|----------|------|------------|--------|------------|
| **TypeScript** | ESLint (`--max-warnings 0`) | `tsc --noEmit` | Prettier | — |
| **JavaScript** | ESLint | — | Prettier | — |
| **Go** | golangci-lint | `go vet` | `gofmt` | — |
| **Python** | ruff check | mypy (optional) | ruff format | — |
| **Rust** | clippy (`-D warnings`) | `cargo check` | `cargo fmt` | — |

Plus **Aegis contract validation** (always, when `contracts/` exists):
- YAML/JSON syntax
- OpenAPI spec validity
- No local shared-type redefinitions
- CLAUDE.md references contracts

### Setup

Automatically run by `init-project.sh`, or manually:

```bash
bash scripts/setup-guardrails.sh /path/to/project [--ci github|gitlab]
```

### Bypass (emergency only)

```bash
git commit --no-verify  # skips pre-commit hook
```

CI pipeline cannot be bypassed — it's the final wall.

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
├── errors.yaml            # Unified error codes
└── route-manifest.yaml    # Consumer-driven route coverage (auto-generated or manual)
```

### Route Manifest (Consumer-Driven Contract Artifact)

The route manifest declares every API route the frontend consumes. It bridges the gap between "what the backend implements" and "what the frontend actually calls."

```yaml
# contracts/route-manifest.yaml
routes:
  - method: GET
    path: /api/customers
    description: Paginated customer list
    consumer: frontend
    provider: backend
    tested: false
```

**Generation:** Use `scripts/verify-route-coverage.sh` to auto-generate from frontend code scans, or maintain manually. In cross-workspace mode, the frontend agent exports this as `consumer-routes.yaml` into the contract repo.

Use template: `templates/route-manifest-starter.yaml`

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

**Cross-Workspace mode:** When agents operate in separate workspaces, contract lives in a dedicated repository. Each agent integrates via submodule/package/copy-sync and treats `contracts/` as read-only. Integration testing is orchestrated externally (Lead or CI).

See `references/multi-agent-protocol.md` for coordination rules + Cross-Workspace Architecture protocol.

## Layer 4: Verification

Graduate from mock illusions to real verification.

### Test Pyramid (AI-Dev Specialized)

```
        E2E Test              ← playwright-forge (real browser + real backend)
      Integration Test        ← real HTTP server + real DB (no mocks)
    Contract Test             ← each side validates against contract
  Frontend Test               ← Vitest + RTL + MSW (contract-typed mocks)
  Unit Test                   ← pure logic (mocking allowed here only)
```

**Key principle: Mocking only at the bottom layer. Everything above is real.**

### Frontend Tests (Production-Ready Standard)

Required when project has frontend:
- **Stack:** Vitest + React Testing Library + MSW
- **Coverage:** API clients (normal/error/auth), data hooks (loading/success/error), key component rendering
- **MSW:** Must mock every backend endpoint with contract-typed response data
- **CI Gate:** `pnpm test` must pass — blocked PR if not

### Contract Tests

- **Backend (Provider):** Validate API responses against OpenAPI spec.
- **Frontend (Consumer):** Build test data from contract types, not ad-hoc mocks.

### Backend Integration Tests (HTTP E2E Standard)

Every API endpoint must have HTTP-level integration tests:
- **Real HTTP server** — start the actual server, send real requests
- **Real database** — isolated test DB, not mocks
- **Coverage per endpoint:** happy path (200) + bad request (400) + not found (404) + auth failure (401)
- **Mutation verification:** POST/PUT/DELETE → GET to confirm state change
- **CI Gate:** must pass after contract tests, before build

### Consumer-Driven Integration Testing

**Problem:** Provider-driven tests only verify what the backend implemented. If the frontend calls `GET /customers` but the backend never registered that route, all tests pass — but the app is broken.

**Solution:** Integration tests must be driven by the consumer (frontend), not just the provider (backend).

#### Three-Tier Verification

| Tier | Condition | Behavior |
|------|-----------|----------|
| **Full** | Frontend API surface available (scan or manifest) | Cross-reference consumer → provider. Every consumer route must have a backend handler + integration test. Fail CI on gaps. |
| **Degraded** | No frontend code or manifest found | Fallback to provider-driven tests (current behavior). CI outputs ⚠️ WARNING, exits 0. |
| **Error** | Frontend found but no backend routes | CI fails — backend is missing entirely. |

#### Route Coverage Gate

Run `scripts/verify-route-coverage.sh` in CI after integration tests:

```bash
bash scripts/verify-route-coverage.sh /path/to/project
```

The script:
1. Extracts all frontend API calls (scans for fetch/axios/api client patterns)
2. Cross-references with backend registered routes
3. Reports: matched / unmatched / total coverage %
4. Exit 0 if all covered OR degraded mode; exit 1 if gaps found

#### Architecture-Specific Approaches

**Monorepo:** Script scans both frontend and backend code directly in the same repo.

**Multi-Repo, Single Agent:** Lead scans the frontend repo, generates `contracts/route-manifest.yaml`, copies it to the backend repo. Backend CI validates coverage against the manifest.

**Cross-Agent, Cross-Workspace:** Frontend agent MUST export a `consumer-routes.yaml` manifest into the contract repo. Backend CI reads this manifest and validates that every listed route has a handler + test.

#### Degradation Strategy (铁律)

When the frontend API surface **cannot** be obtained:
- ⚠️ **Degraded mode** — fallback to provider-driven integration tests
- CI outputs WARNING, **not** failure — does not block the pipeline
- `verify-route-coverage.sh` exits 0 + prints ⚠️ WARNING
- Log the degradation reason for traceability

This ensures existing projects without frontend manifests are not broken by the upgrade.

### E2E Tests

- E2E: Call playwright-forge for browser-level verification.
- CI pipeline: `lint → type-check → unit → frontend-test → contract → integration → route-coverage → build → E2E`

### Test Strategy as Design Artifact

**Full-stack features require a complete testing strategy in the Design Brief** (Design Review gate):
1. Frontend: API client coverage, hook coverage, key components, MSW plan
2. Backend integration: endpoint list, scenario matrix, DB setup
3. E2E: critical user flows

A Design Brief without testing strategy for a full-stack feature **cannot be approved**.

See `references/testing-strategy.md` for detailed standards and examples.

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

- `scripts/init-project.sh <project-path>` — Initialize Aegis structure + guardrails in a project
- `scripts/setup-guardrails.sh <project-path> [--ci github|gitlab]` — Set up pre-commit hook + CI pipeline (language-adaptive)
- `scripts/detect-stack.sh <project-path>` — Detect project languages/frameworks (JSON output)
- `scripts/validate-contract.sh <project-path>` — Validate contract consistency
- `scripts/generate-types.sh <project-path>` — Generate shared types from OpenAPI spec
- `scripts/verify-route-coverage.sh <project-path> [--manifest <path>]` — Consumer-driven route coverage verification

## Templates

- `templates/design-brief.md` — Design Brief template
- `templates/implementation-summary.md` — Post-implementation summary template
- `templates/claude-md.md` — Enhanced CLAUDE.md template with Aegis constraints
- `templates/api-spec-starter.yaml` — OpenAPI 3.1 starter spec
- `templates/shared-types-starter.ts` — Shared types starter (typically auto-generated)
- `templates/errors-starter.yaml` — Error code definition starter
- `templates/docker-compose.integration.yml` — Integration test compose template
- `templates/route-manifest-starter.yaml` — Route manifest starter for consumer-driven testing

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
