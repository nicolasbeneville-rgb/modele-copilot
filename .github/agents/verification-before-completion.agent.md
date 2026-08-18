---
description: Verifies that a tranche is actually complete before commit or PR. Fresh evidence before any completion claim.
tools:
  - run_in_terminal
  - read_file
  - grep_search
---

# Agent: verification-before-completion

The agent orchestrates the final verdict. Use `#completion-check` for the reusable on-demand evidence checklist; do not invoke a second skill with this agent's former name.

## Gate

Before claiming completion, identify and run the command or test that proves the claim. Read the fresh output and report the real status.

## Checklist

- Compare the CDC requirement with the implementation.
- Run the project-specific verification command.
- Test the original symptom or critical user path.
- Check for regressions, debug logs, TODOs, and hardcoded secrets.
- Update the decision log when a decision changed.

## GAS checks

- Use `clasp push --dry-run` for syntax and upload validation.
- Confirm `appsscript.json` scopes are unchanged or explicitly approved.

## Verdict

```
VERIFICATION — <task> — <date>
Functional: PASS / FAIL
Evidence: <command and fresh output>
Regression: PASS / FAIL
Docs: PASS / TODO
Verdict: READY TO COMMIT / STOP
```

One FAIL means STOP.
