# Testing Strategy — Aegis Approach

## The Problem with AI-Generated Tests

AI agents love to mock everything. The result: all tests pass, but the system doesn't work.

Aegis enforces a testing pyramid where **mocks are only allowed at the bottom layer**.

## Testing Pyramid

```
         ╱  E2E Test  ╲          ← Real browser + real backend
        ╱───────────────╲
       ╱ Integration Test╲       ← Real services via docker-compose
      ╱───────────────────╲
     ╱   Contract Test     ╲     ← Validates conformance to contract
    ╱───────────────────────╲
   ╱     Unit Test           ╲   ← Pure logic, mocks allowed
  ╱───────────────────────────╲
```

## Layer Details

### Unit Tests
- **What:** Pure business logic, utilities, transformations
- **Mocks:** Yes — external dependencies (DB, HTTP, etc.)
- **Speed:** Milliseconds
- **When:** Every code change

### Contract Tests
- **What:** Does the implementation match the contract?
- **Backend (Provider):** Start the real server, hit endpoints, validate response against OpenAPI spec
- **Frontend (Consumer):** Build test data from contract types, verify components handle them correctly
- **Mocks:** Only for dependencies external to the contract scope
- **Speed:** Seconds
- **When:** Every code change that touches an API

### Integration Tests
- **What:** Do all services work together?
- **Setup:** docker-compose with real database, real backend, real frontend
- **Mocks:** None
- **Speed:** Minutes
- **When:** Before merge

### E2E Tests
- **What:** Does the deployed system work from a user's perspective?
- **Setup:** Playwright against a real deployment
- **Mocks:** None
- **Speed:** Minutes
- **When:** After deployment, before release

## Key Principles

1. **Never mock across contract boundaries** — If frontend tests mock the API, you're testing your assumptions, not the system
2. **Contract tests are mandatory** — They're cheap and catch 80% of integration issues
3. **Integration tests prove it works** — docker-compose is your safety net
4. **E2E tests validate the user experience** — Not every flow, just the critical paths
