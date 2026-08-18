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

### 2026-06-16 - Session lifecycle hardened with global prompt triggers
- Decision: finalize lifecycle governance around global triggers `#bonjour`, `#go-ui`, `#go-bug`, `#go-compact`, and `#bonne-nuit` and align project instructions with Multi-PC startup recovery.
- Rationale: reduce startup friction, preserve context across machines, and enforce low-token operational routines.
- Impact: start/end session behavior is now explicit, repeatable, and recoverable with session memory continuity.
- Tags: 💡 [RETRO-MODELE], session-lifecycle, prompts, multi-pc
- Owner: Copilot

### 2026-08-17 - Gate pré-action et preuve d'intégration obligatoires
- Decision: imposer un plan avant toute action et une preuve fraîche après chaque tranche, avec objectif, risques, rollback, test réel, boucle de rétrocontrôle, apprentissage et intégration.
- Rationale: l'audit a révélé des validateurs faux-verts, des chemins GO incomplets et des demandes utilisateur sans valeur ajoutée.
- Impact: les scripts de gouvernance refusent désormais un plan absent ou incomplet ; les actions utilisateur sont demandées uniquement si elles portent une décision, un secret, une approbation ou une irréversibilité.
- Tags: 💡 [RETRO-MODELE], governance, validation, feedback-loop, token-optimization
- Owner: Copilot
