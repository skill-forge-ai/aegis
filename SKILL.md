# Aegis — DevOps Quality Guardian

## Layer 4: Verification — Consumer-Driven Contract Testing

### Problem

Current Aegis integration test strategy is **provider-driven**: tests are written based on what backend endpoints are implemented. This misses a critical failure mode: **frontend calls endpoints the backend never registered**.

### Real-World Incident (2026-03-31)

IcestoneTech Stripe Billing Platform deployed to production with **5 missing list endpoints**:
- `GET /customers` (paginated list) — frontend called it, backend only had `POST /`
- `GET /subscriptions` (paginated list) — frontend called it, backend only had `POST /` + `GET /{id}`
- `GET /invoices` (global list) — frontend called it, backend only had user-scoped list
- `GET /plans` (global list) — frontend called it, backend only had product-scoped list
- `GET /checkout/sessions` (paginated list) — same pattern

**All existing integration tests passed** because they only tested endpoints the backend had. Nobody tested what the frontend actually needed.

### Consumer-Driven Contract Testing (New Requirement)

For **monorepo and multi-repo full-stack projects**, integration tests must be driven by the frontend consumer, not just the backend provider.

#### Key Principles
1. **Extraction:** Parse `api.ts` / API client files to get every `{method, path}` the frontend calls
2. **Cross-Reference:** Verify every frontend call has a corresponding backend route
3. **Test Coverage:** Write integration tests from the consumer perspective
4. **CI Gate:** Automated script to compare frontend API surface vs backend routes

### Implementation Strategy

#### Contract Layer (L2): Route Manifest
Add `contracts/route-manifest.yaml`:
```yaml
routes:
  - method: GET
    path: /customers
    description: Paginated customer list
    consumer: frontend
    provider: backend
```

#### Verification Layer (L4): Consumer-Driven Tests
```markdown
### Integration Test Requirements

1. Extract frontend API surface
2. Verify every frontend call has a registered backend route
3. Write consumer-perspective integration tests
4. CI script: `verify-route-coverage.sh`
```

#### Design Brief Template
```markdown
## Frontend API Surface
| Method | Path | Description | Backend Handler |
|--------|------|-------------|-----------------|
| GET | /customers | Paginated list | CustomerHandler.List |
```

### Expected Impact
- Catch missing endpoints **before deployment**
- Design-time or CI-time route coverage validation
- Prevent runtime 404/405 errors

### Labels
- Layer 4: Verification
- Layer 2: Contract
- Integration Testing
