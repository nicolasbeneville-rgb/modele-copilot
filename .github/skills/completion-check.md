---
name: completion-check
description: "Run a fresh evidence check before declaring work complete, fixed, committed, or ready to deploy."
---

# Completion Check

## Gate

Before claiming completion:

1. Identify the command or user path that proves the claim.
2. Run it freshly and read the complete result.
3. Check the original symptom, critical path, and regressions.
4. Check documentation, secrets, TODOs, and the action plan evidence.
5. Return `READY TO COMMIT` only when every required check passes.

## Foundations version gate

Before the verdict, run `_scripts/validate-foundation-version.ps1 -ProjectPath . -Phase Post`.

- Read `foundations.version` from the project status.
- Compare it with `foundations_version_start` captured when the tranche began.
- Confirm `foundations_version_at_completion` matches the current version.
- A version change is blocking until `foundations_version_change` names a traced amendment and `foundations_version_confirmation` contains explicit human confirmation.
- A normal coding tranche does not increment the version. Only a traced amendment to foundation data, messages or constants does.

## Live-test gate

When `live_test_required: true`, run:

```powershell
_scripts/validate-live-test-procedure.ps1 -Path <project procedure> -RequireExecuted
```

The verdict is blocked unless every procedure field is filled, the scenario comes from
`cdc-recette`, `execution_status` is `executed`, and fresh evidence exists. Code reading
alone never satisfies this gate.

## Output

```text
VERIFICATION — <task> — <date>
Functional: PASS / FAIL
Evidence: <fresh command and result>
Regression: PASS / FAIL
Docs: PASS / TODO
Verdict: READY TO COMMIT / STOP
```

## GAS checks

- Use `clasp push --dry-run` for upload and syntax validation.
- Confirm `appsscript.json` scopes are unchanged or explicitly approved.

One failed check means `STOP`.