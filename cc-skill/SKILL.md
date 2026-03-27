---
name: aegis-cc
description: >
  Aegis contract-driven quality guardrails for implementation. IRON RULE — always active.
  Enforces: read contracts before coding, import shared types (never redefine), use registered error codes,
  write contract tests for new APIs, never modify contracts directly (file Change Request instead),
  follow CLAUDE.md hard constraints. Triggers on: any coding task in a project with contracts/ directory.
---

# Aegis — Implementation Guardrails (CC Edition)

> **铁律：项目有 `contracts/` 目录时，以下规则无条件生效。**

## Pre-Coding Checklist (每次开始编码前)

1. **Read contracts** — check if `contracts/` exists in project root
2. If yes: read `contracts/api-spec.yaml` to understand the API surface
3. Read `contracts/errors.yaml` for valid error codes
4. Read `contracts/shared-types.ts` for shared type definitions
5. Read `CLAUDE.md` for project-specific hard constraints
6. If a Design Brief exists for your task: read `docs/designs/` relevant file

Skip ONLY if the project has no `contracts/` directory.

## Hard Rules (违反 = PR rejected)

### R1: Contract is the truth
- All API responses MUST conform to `contracts/api-spec.yaml`
- Response shapes, status codes, field names — all from the spec
- If the spec says a field is required, it's required. No exceptions.

### R2: Shared types — import, never redefine
- TypeScript: `import { User, ApiResponse } from '../contracts/shared-types'`
- Go: use the types/structs defined in the shared package
- **NEVER** create a local `interface User` or `type User` that shadows the contract type
- If shared-types doesn't have what you need → file a Change Request (see R5)

### R3: Error codes from registry only
- Use codes defined in `contracts/errors.yaml`
- Never invent error codes like `{ code: "CUSTOM_ERROR" }`
- If you need a new error code → file a Change Request (see R5)

### R4: Contract tests mandatory
- Every new API endpoint MUST have a contract test
- Contract test = validate real response against OpenAPI spec
- Not "does it return 200" — "does the response body match the schema"
- Modified endpoints → update contract test

### R5: Never modify contracts directly
If you discover the contract needs changes:

1. Create file: `docs/contract-changes/CHANGE-{date}-{description}.md`
2. Include: what to change, why, which modules affected
3. Continue implementing with the CURRENT contract
4. Lead (Forge) will review and update the contract

```markdown
# Contract Change Request

**Date:** {YYYY-MM-DD}
**Affects:** {endpoint / schema / error code}

## Current Contract
{What it says now}

## Proposed Change
{What should change}

## Reason
{Why — what doesn't work with current contract}
```

### R6: CLAUDE.md constraints
- Read and follow `CLAUDE.md` ⛔ Hard Constraints section
- These are project-specific and override general preferences
- Common constraints: no business logic in handlers, no hardcoded env vars, structured logging with requestId

## Testing Hierarchy

```
Unit Test         ← Mock allowed here
Contract Test     ← Validate against api-spec.yaml (NO MOCKING the contract)
Integration Test  ← Real services
```

When writing tests:
- **Unit tests:** Mock external dependencies, test pure logic
- **Contract tests:** Hit real endpoints, validate response against OpenAPI spec
- **Never** construct mock data by hand for contract tests — use the spec as source

## File Organization

Expect this structure in Aegis projects:
```
contracts/
├── api-spec.yaml        # OpenAPI 3.1 — READ FIRST
├── shared-types.ts      # Shared types — IMPORT FROM HERE
├── errors.yaml          # Error codes — USE THESE
└── events.schema.json   # Async event schemas
docs/
├── designs/             # Design Briefs
└── contract-changes/    # Change Requests (you write these)
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Need a new endpoint | Check if it's in api-spec.yaml first |
| Need a new type | Check shared-types.ts first → if missing, Change Request |
| Need a new error code | Check errors.yaml first → if missing, Change Request |
| API response doesn't match spec | Fix your code, not the spec |
| Spec seems wrong | File Change Request, implement per current spec |
| No contracts/ directory | These rules don't apply — standard development |
