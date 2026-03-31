# Multi-Agent Coordination Protocol

## Architecture

```
                 ┌──────────────┐
                 │  Lead (Forge) │
                 │ Holds Contract│
                 └──────┬───────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
     ┌─────▼─────┐ ┌───▼───┐ ┌─────▼─────┐
     │ CC-Frontend│ │Contract│ │ CC-Backend │
     │ (Agent A)  │ │  Repo  │ │ (Agent B)  │
     └───────────┘ └───────┘ └───────────┘
```

## Rules

1. **Same contract, same truth.** Both agents receive identical contract files. Neither can modify them unilaterally.

2. **No direct communication.** Agents never talk to each other. All coordination goes through the contract + lead.

3. **Contract changes require approval.** If an agent needs to change the contract, it writes a Change Request. Lead reviews, updates contract, notifies both agents.

4. **Recommended sequence:**
   ```
   contract → backend → contract test → frontend → integration test
   ```
   Backend goes first because frontend depends on real API behavior. But both can start in parallel if the contract is solid.

5. **Backend agent rules:**
   - Implement exactly what the contract defines (no extra endpoints, no missing fields)
   - Write contract tests that validate responses against api-spec.yaml
   - If a design gap is found, document it — don't guess

6. **Frontend agent rules:**
   - Import all types from `contracts/shared-types.ts`
   - During development, mock API using contract-defined schemas
   - Do not invent response formats
   - If contract feels incomplete, file a Change Request

7. **Integration handoff:**
   - Backend completes → lead runs contract tests → green
   - Frontend completes → lead connects to real backend → integration test
   - Both green → E2E test → PR ready

## Contract Change Request Format

```markdown
# Contract Change Request

**Requested by:** {agent name}
**Date:** {YYYY-MM-DD}
**Affects:** {endpoint(s) / schema(s)}

## Current Contract
{What the contract currently says}

## Proposed Change
{What should change}

## Reason
{Why the change is needed — what doesn't work with current contract}

## Impact
- Backend: {needs to change X}
- Frontend: {needs to change Y}
- Tests: {which tests need updating}
```

## Cross-Workspace Architecture

When frontend and backend live in **separate workspaces** (different repos, different agents, possibly different machines), the coordination protocol changes significantly.

### Architecture Types

Aegis auto-detects the workspace architecture at init time (see SKILL.md § Workspace Architecture Detection). Three modes:

| Mode | Description | Contract Location |
|------|-------------|-------------------|
| **Monorepo** | Frontend + backend in one repo | `contracts/` inside the repo |
| **Multi-Repo, Single Agent** | One agent manages multiple repos | `contracts/` in lead workspace, copied to each repo |
| **Cross-Agent, Cross-Workspace** | Different agents, different workspaces | **Dedicated contract repository** (independent Git repo) |

### Cross-Workspace Contract Protocol

When operating in **Cross-Agent, Cross-Workspace** mode:

#### 1. Dedicated Contract Repository

```
contracts-repo/                  ← Independent Git repo, all agents pull from here
├── api-spec.yaml                ← OpenAPI 3.1 (authoritative)
├── shared-types.ts              ← Auto-generated (DO NOT EDIT)
├── errors.yaml                  ← Error code registry
├── events.schema.json           ← Async event definitions
├── CHANGELOG.md                 ← All contract changes logged
├── scripts/
│   └── generate-types.sh        ← Type generation script
└── .github/workflows/
    └── validate.yml             ← CI: lint + validate spec on every push
```

- The contract repo is the **single source of truth** — no agent holds a "more authoritative" copy.
- Human (Lead) has merge rights. Agents submit PRs for changes.

#### 2. Integration into Agent Workspaces

Each agent's project integrates the contract repo via one of:

**Option A: Git Submodule (recommended for stable contracts)**
```bash
git submodule add <contracts-repo-url> contracts/
```
- Agent reads from `contracts/` (read-only)
- Updates via `git submodule update --remote`
- Pros: version-locked, auditable
- Cons: submodule update is an explicit step

**Option B: Package Registry (recommended for typed languages)**
```bash
npm install @project/contracts    # or pip install, go module, etc.
```
- Contract repo publishes versioned packages (types, spec files)
- Agents pin to a specific version
- Pros: semantic versioning, dependency management built-in
- Cons: requires publishing pipeline

**Option C: Copy-Sync by Lead (lightweight, for small teams)**
- Lead agent holds the authoritative copy
- Before dispatching each agent, lead copies latest contract files into the agent's workspace
- Agent treats `contracts/` as read-only
- Pros: zero setup, works immediately
- Cons: manual sync, risk of stale copies

#### 3. Dispatch Prompt Adjustments

When dispatching to an agent in cross-workspace mode, add to the prompt:

```markdown
## Workspace Architecture: Cross-Workspace

You are the {frontend|backend} agent. The other side is developed by a
separate agent in a separate workspace. You cannot see their code.

## Contract (Source of Truth — External Repository)
Your local copy is in `contracts/`. It is **read-only**.
- DO NOT modify any file in `contracts/`
- All types must be imported from `contracts/shared-types.ts`
- If the contract is insufficient, write a Change Request in `CHANGE_REQUEST.md`
  (file it at root of your workspace — Lead will review)

## Your Scope
Only modify files in: {allowed directories}
DO NOT touch: contracts/, {other forbidden dirs}
```

#### 4. Contract Sync Workflow

```
Lead updates contracts-repo
  → CI validates spec
  → Merge to main
  → Each agent workspace syncs:
      Submodule: git submodule update --remote
      Package: npm update @project/contracts
      Copy-Sync: Lead re-copies files
  → Agents continue with updated contract
```

#### 5. Contract Test Isolation

In cross-workspace mode, each side runs its own contract tests independently:

- **Backend workspace:** Contract conformance tests (does my API match the spec?)
- **Frontend workspace:** Type-check against `shared-types.ts` + mock server from spec

Integration testing requires a separate environment (e.g., docker-compose that combines both services). This is typically orchestrated by the Lead or CI, not by individual agents.

## Consumer Route Manifest Exchange Protocol

In cross-workspace mode, the frontend and backend cannot scan each other's code. The consumer route manifest bridges this gap.

### Protocol

1. **Frontend agent** extracts all API calls from its codebase and exports `consumer-routes.yaml`:

```yaml
# consumer-routes.yaml — exported by frontend agent into contract repo
routes:
  - method: GET
    path: /api/customers
    description: Paginated customer list
    consumer: frontend
    provider: backend
  - method: GET
    path: /api/customers/:id
    description: Customer detail
    consumer: frontend
    provider: backend
  - method: POST
    path: /api/customers
    description: Create customer
    consumer: frontend
    provider: backend
```

2. **Frontend agent** commits `consumer-routes.yaml` to the contract repository (or includes it in a Change Request for the Lead to merge).

3. **Backend CI** reads `consumer-routes.yaml` from the contract repo and validates route coverage:

```bash
# Backend CI pipeline step (after integration tests)
bash scripts/verify-route-coverage.sh . --manifest contracts/consumer-routes.yaml
```

4. **Lead** is notified of any gaps — unmatched routes mean the backend is missing endpoints that the frontend expects.

### When to Update

- Frontend agent updates `consumer-routes.yaml` whenever it adds, removes, or changes API calls
- This is part of the Contract Change Protocol — new consumer routes may require new backend endpoints
- Backend agent treats `consumer-routes.yaml` as a test fixture: "these are the routes I must serve"

### Degradation in Cross-Workspace Mode

If the frontend agent has not yet exported `consumer-routes.yaml`:
- Backend CI runs `verify-route-coverage.sh` → finds no manifest → ⚠️ DEGRADED mode
- CI passes with a warning, does not block
- Lead should ensure the frontend agent exports the manifest before the next integration milestone

## Conflict Resolution

When agents disagree (e.g., backend says "this field should be optional" but frontend needs it required):

1. Lead examines the Design Brief for intent
2. Lead decides based on: user needs > API cleanliness > implementation convenience
3. Decision is recorded in Design Brief's "Key Design Decisions" table
4. Contract is updated authoritatively
5. Both agents comply — no exceptions
