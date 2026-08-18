---
name: pre-action-plan
description: "Mandatory before any implementation, governance edit, script execution or release. Build a concise plan with objective, scope, critical path, risks, rollback, real tests, feedback loop, learning and integration check."
---

# Pre-action plan

## Gate

Before any action that changes code, docs, governance, configuration, Git state or an external system:

1. Read the current source files and project-status.
2. State the objective and the smallest useful scope.
3. Map the critical path and dependencies.
4. List blocking risks and the rollback point.
5. Define a real discriminating test before editing.
6. Define the post-edit feedback loop and integration check.
7. Define the learning/retro capture.
8. Answer the mandatory `parallel_dispatch` question: does the CDC contain two or more independent slices? If yes, apply `graph-parallel-dispatch` before execution.

No plan means no action. A plan is not permission to deploy, delete, push or widen scopes.

## Product-to-delivery gate

1. Start from the user's product vision.
2. Challenge assumptions, contradictions, users, value, constraints, non-goals and success measures.
3. Keep `clarification_status: open` while a material decision remains unresolved. During this phase, only discovery, questions and safe analysis are allowed.
4. Set `clarification_status: clarified` only when the path is clear enough to plan.
5. Then build the global plan with epics, user stories, dependencies and measurable outcomes.
6. Decompose each story into tasks with scope, preconditions, action, expected result, test and evidence.
7. Select `test_level` and create a matrix when there are multiple paths, roles, risks, production impact or shared governance.
8. Cover function, UX/accessibility, security, messages, performance, regression, documentation and rollback as applicable.

Implementation is blocked until clarification is `clarified` and the global plan exists.

Foundation changes are versioned once per project. Increment only for a traced amendment
to foundation data, messages or constants, never for an ordinary coding tranche.

When a live test is required, use `_governance/live-test-procedure-template.md` and fill
every project-specific field. A live-test verdict cannot rely on code reading alone.

## Compact format

```yaml
id: <date>-<short-id>
status: planned
objective: "<measurable result>"
scope: "<files, project, or workflow>"
critical_path: "read -> hypothesis -> edit -> focused test -> integration check"
risks: "<blocking risks and likely regressions>"
rollback: "<backup, commit, or restore path>"
tests: "<real command or user path that can fail>"
feedback_loop: "<what to rerun after each edit>"
learning: "<what to capture if a new lesson appears>"
integration_check: "<dependent projects, contracts, catalogs and GO paths to verify>"
parallel_dispatch: "<yes/no; if yes, list independent slices, dependencies, files and merge point>"
human_gate: "<none or decision/approval/secret/irreversible>"
human_value: "<why interrupt the user; otherwise none>"
acceptance: "<proof required before completion>"
mode: plan_first
routing: "<agents and skills selected, or none>"
agents: "<agents to activate, or none>"
skills: "<skills to activate, or none>"
arbitrations: "<decisions made, or none>"
retirements: "<retired elements, or none>"
evidence: "<fresh commands and results when status is verified>"
```

Product planning fields:

```yaml
phase: discovery | planned | execution | verification | release
vision: "<product vision or user objective>"
challenge: "<assumptions, contradictions, questions and constraints to clarify>"
clarification_status: open | clarified | blocked
global_plan: "<plan path or epics, dependencies and milestones>"
epics: "<epic IDs and measurable outcomes>"
user_stories: "<story IDs and acceptance criteria>"
tasks: "<small testable and verifiable tasks>"
test_level: targeted | matrix | recette
test_matrix: "<matrix path or inline scenarios>"
quality_dimensions: "function, UX/accessibility, security, messages, performance, tests, docs, rollback"
foundations_version_start: "<integer captured at tranche start>"
foundations_version_at_completion: "<integer read at completion>"
foundations_version_change: "none | <traced amendment reference>"
foundations_version_confirmation: "none | confirmed:<human confirmation reference>"
live_test_required: false
live_test_procedure: "not_required | <project procedure path>"
live_test_status: "not_required | planned | executed | blocked"
live_test_evidence: "not_required | <output, capture or proof>"
```

## Status transitions

- `planned` -> plan exists and source was read.
- `in_progress` -> edit or test is underway.
- `blocked` -> a risk or missing decision prevents safe progress.
- `verified` -> fresh evidence and integration checks pass; record `evidence`.

## Rules

- Use the cheapest focused test first, then widen only when it passes.
- If a test falsifies the hypothesis, stop and revise the plan before editing again.
- Do not ask the user to run a command that the agent can run safely and that adds no decision value.
- Ask the user only for approvals, secrets, credentials, business decisions or irreversible actions.
- Every requested user action must have a `human_gate` and a non-empty `human_value`; otherwise execute it yourself.
- Use `mode: plan_first` for every action. Choose agents and skills in the plan before editing.
- Record arbitrations and retirements explicitly; do not keep parallel mechanisms without a declared boundary.
- Always include `parallel_dispatch` and answer whether the CDC contains at least two independent slices. Set it to `no` unless independent files and dependencies are explicitly proven; a `yes` decision requires a frozen CDC scope, one worktree per slice and a named merge point. Deployment remains serial.
- Keep code simple: remove duplicate paths and prefer existing abstractions.
