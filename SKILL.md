# Aegis — AI Development Quality Guardian

> AgentSkill for OpenClaw

## Description

Aegis enforces structured quality assurance across AI-assisted development workflows.
It provides a five-layer defense system: Design → Contract → Implementation → Verification → Project Management.

**Activate when:** Starting a new feature, dispatching coding tasks, reviewing PRs, or managing multi-agent development workflows.

---

## Workflow

### Phase 1: Design

Before any non-trivial feature, create a Design Brief:

1. Read `templates/design-brief.md` for the template
2. Fill in: Problem Statement, Architecture Overview, Key Decisions, Module Boundaries, API Surface, Known Gaps, Testing Strategy
3. Submit for human review
4. **Gate:** Do not proceed to Phase 2 until Design Brief is approved

### Phase 2: Contract

Define the API contract before writing implementation code:

1. Create/update `contracts/api-spec.yaml` (OpenAPI 3.1)
2. Create/update `contracts/shared-types.ts` (shared type definitions)
3. Create/update `contracts/errors.yaml` (error code definitions)
4. Submit for review
5. **Gate:** Contract must be approved before implementation begins

### Phase 3: Implementation

When dispatching coding tasks (e.g., to Claude Code):

1. Inject the project's `CLAUDE.md` (use `templates/claude-md.md` as base)
2. Reference the relevant Design Brief
3. Reference the contract files
4. Include relevant code lessons / quality rules
5. Define clear acceptance criteria including contract conformance

**Contract Change Protocol:**
- If an agent needs to modify the contract during implementation → **STOP**
- Submit a Contract Change Request (what, why, impact)
- Lead reviews and approves/rejects
- If approved: update contract, notify all agents
- If rejected: implement per existing contract

### Phase 4: Verification

Testing pyramid (bottom to top):

1. **Unit Tests** — Pure logic, mocks allowed
2. **Contract Tests** — Validate implementation conforms to `contracts/api-spec.yaml`
3. **Integration Tests** — Real services via docker-compose
4. **E2E Tests** — Full browser/API testing against real deployment

**Key principle:** Mocks only at the unit test level. Everything above uses real services.

### Phase 5: Project Management

Track progress and gaps:

1. Each feature → Story with subtasks (Design/Contract/Implementation/Testing)
2. Each discovered gap → Issue (tagged with severity: blocking/non-blocking)
3. Sprint planning includes gap triage
4. Story cannot close until all subtasks (including tests) are done

---

## Modes

### Lite Mode
For small features or single-stack work:
- Simplified Design Brief
- Contract + Contract Test required
- Integration/E2E tests optional

### Full Mode
For large features or multi-stack work:
- Complete Design Brief
- Full contract suite
- All test levels required
- PM tracking with full subtask breakdown

---

## Commands

### Initialize a Project
```bash
bash scripts/init-project.sh /path/to/project
```

### Validate Contracts
```bash
bash scripts/validate-contract.sh /path/to/project
```

### Generate Gap Report
```bash
bash scripts/gap-report.sh /path/to/project
```

---

## File Structure

```
aegis/
├── SKILL.md              # This file
├── README.md             # Public documentation
├── templates/            # Project templates
├── scripts/              # Automation scripts
├── references/           # Detailed guides
└── examples/             # Working examples
```
