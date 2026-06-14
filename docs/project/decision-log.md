# Decision Log

Use this file to record product and technical decisions.

## Entry Format
### YYYY-MM-DD - Title
- Decision: what was decided
- Rationale: why
- Impact: scope and consequence
- Owner: who owns the decision

## Kickoff Entry Template
### YYYY-MM-DD - Project startup kit initialization
- Decision: initialize startup assets, owner matrix, and skill baseline.
- Rationale: enforce governance and traceability from day 1.
- Impact: release guardrail active and startup workflow standardized.
- Owner: Product Owner + Architecture.

### 2026-06-15 - Governance sync automation and onboarding kit
- Decision: standardize workspace-wide Copilot governance sync with `sync-workspace-github.ps1`, add `sync-to-user-prompts.ps1`, and create `init-existing-project-governance.ps1` plus `GO NEW PROJECT` onboarding guidance.
- Rationale: reduce drift across projects, centralize governance propagation, and make onboarding of existing repos repeatable without deployment.
- Impact: shared instructions/agents/skills can now be resynchronized in one command; existing projects can adopt the governance layer with safer doc merging.
- Tags: 💡 [RETRO-MODELE], governance, automation, documentation
- Owner: Copilot

### 2026-06-15 - CO-STAR and blind-design rules become default governance
- Decision: upgrade reusable agents, prompts, and skills with CO-STAR structure, accessibility/performance requirements, and text-only design validation rules.
- Rationale: improve quality of AI-facing assets, keep guidance reusable, and adapt reviews to a non-visual VS Code environment.
- Impact: future agent and skill updates must carry explicit expert structure and accessibility/performance checks by default.
- Tags: 💡 [RETRO-MODELE], prompts, accessibility, performance
- Owner: Copilot
