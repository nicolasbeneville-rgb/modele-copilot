---
name: check-account
description: "Verify the active clasp email with the project registry before GO PUSH. Block when the project alias is missing or the identity cannot be verified."
---

# Check Account

## Procedure

1. Read `.clasp.json` and find the current project name.
2. Read `_governance/clasp-project-registry.md` and find the expected account and alias.
3. Run `clasp show-authorized-user --json`.
4. Compare the returned email with the registered alias.

## Verdicts

- `PASS`: project exists, alias is a real value, and emails match.
- `BLOCK`: project is absent, account is `TO_CONFIRM`, alias is missing, or emails differ.
- Never infer `PRO` or `PERSO` from an email domain alone.

## Recovery

```powershell
clasp logout
clasp login --no-localhost
clasp show-authorized-user --json
```

The skill is a pre-flight gate for `@deployer`; it does not run `clasp push`, `clasp version` or `clasp deploy`.
