---
description: Orchestrates the complete GO PUSH workflow: account check, syntax check, clasp push, version and target deployment.
tools:
  - run_in_terminal
  - read_file
  - grep_search
---

# Agent: deployer

## Safety guardrails

1. Require the explicit user command `GO PUSH`.
2. Run `._scripts/validate-action-plan.ps1 -ProjectPath . -Phase Pre` before any clasp command.
3. Read `.clasp.json` and `_governance/clasp-project-registry.md` before any clasp command.
4. Run `.github/hooks/verify-clasp-account.ps1 -ProjectPath .` and stop on mismatch or unverifiable account identity.
5. Run syntax validation and a dry-run before execution.
6. Verify the production deployment ID is real, never a placeholder.

## Execution sequence

1. `clasp push --force`
2. `clasp version "<description>"`
3. `clasp deploy -i <DEPLOYMENT_ID_PROD> -V <versionNumber> -d "<description>"`
4. Verify the production URL and record the result.

Stop immediately if a step fails. Never create a new deployment accidentally and never deploy without explicit GO PUSH.
