---
name: product-plan
description: "Challenge a product vision, clarify decisions, then create a global plan with epics, user stories, verifiable tasks and a quality matrix. Use before implementation when the user gives a product objective."
---

# Product Plan

## Gate

Do not write implementation code while a material product decision remains unresolved.

## Sequence

1. Restate the user's vision and intended value.
2. Challenge assumptions, users, workflows, constraints, non-goals, risks and success measures.
3. List open questions and decisions; set `clarification_status: open` until they are resolved.
4. Set `clarification_status: clarified` only when the implementation path is clear enough to plan.
5. Build the global plan in `docs/project/product-plan.md` from `_governance/product-plan-template.md`.
6. Define epics, user stories, dependencies and measurable acceptance criteria.
7. Decompose each story into tasks with scope, expected result, test and evidence.
8. Select a test level and matrix covering function, UX/accessibility, security, messages, performance, regression, documentation and rollback as applicable.

## Output

- Vision and value
- Questions and objections
- Decisions and assumptions
- Epics and dependencies
- User stories and acceptance criteria
- Verifiable tasks
- Quality/test matrix
- Risks, rollback and next gate

## Boundary

This skill owns product framing and planning. It does not implement code, deploy, delete or push.
