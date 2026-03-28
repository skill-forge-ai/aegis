# Changelog

All notable changes to Aegis will be documented in this file.

## [1.2.0] - 2026-03-28

### Added
- **Workspace Architecture Detection** (CC skill) — Phase 0 auto-detection of project architecture before entering Aegis workflow. Detects monorepo/split/cross-agent and prompts human when ambiguous.
- **Cross-Workspace Contract Protocol** (CC skill) — dedicated contract repository pattern, three integration methods (submodule/package/copy-sync), cross-workspace dispatch template, contract test isolation strategy.
- Updated multi-agent protocol reference with full cross-workspace section.

### Fixed
- CC skill (`cc-skill/`) now includes all v1.1.0 features that were previously only in the OpenClaw SKILL.md.

## [1.1.0] - 2026-03-28

### Added
- **Workspace Architecture Detection** — new phase before the Aegis workflow. Auto-detects project architecture (Monorepo / Split Workspace / Cross-Agent Cross-Workspace) by scanning directory structure and framework indicators. When ambiguous, prompts the human to confirm.
- **Cross-Workspace Contract Protocol** — dedicated section in `references/multi-agent-protocol.md` for projects where frontend and backend live in separate workspaces managed by different agents. Covers:
  - Dedicated contract repository pattern
  - Three integration methods: Git submodule, package registry, copy-sync by lead
  - Dispatch prompt adjustments for cross-workspace agents
  - Contract sync workflow
  - Test isolation strategy (each side runs contract tests independently)
- **Architecture Mode Effects** — different contract strategies and CLAUDE.md adjustments per detected mode
- This CHANGELOG

## [1.0.0] - 2026-03-27

### Added
- Five-layer protection system: Design → Contract → Implementation → Verification → PM
- Layer 0: Automated guardrails (pre-commit hooks + CI pipeline, language-adaptive)
- Layer 1: Design Brief template and workflow
- Layer 2: Contract-first development (OpenAPI spec, shared types, error codes)
- Layer 3: Implementation constraints via enhanced CLAUDE.md
- Layer 4: Verification pyramid (unit → contract → integration → E2E)
- Layer 5: Project management integration (gap tracking, sprint subtasks)
- Multi-agent coordination protocol
- CC Skill (Claude Code side) for persistent Aegis awareness
- Scripts: init-project, setup-guardrails, detect-stack, validate-contract, generate-types
- Self-contained CC skill package (`cc-skill/`) for pure Claude Code users
- Lite Mode vs Full Mode support
