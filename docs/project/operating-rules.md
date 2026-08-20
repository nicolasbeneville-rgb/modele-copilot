# Operating Rules

## Deployment Rule
- Never deploy without explicit GO from requester in chat.

## Clasp Account Rule
- Clasp account for this project: `[PRO|PERSO|TO_CONFIRM]` - `[email ou alias attendu]`
- Any `clasp push`, `clasp version`, or `clasp deploy` with another account is blocked.
- If `clasp` returns `The caller does not have permission`, stop deployment and re-authenticate with the declared account.

## Documentation Rule
- Update decision-log for major decisions.
- Keep one source of truth per topic.
- Update existing docs before creating new ones.

## Security Rule
- Review identity, authorization, data exposure, and abuse paths before release.

## Robustness Rule
- Define fallback behavior before marking a feature complete.
- Document concurrency, caching, and quota constraints when relevant.

## Startup Rule
- Initialize mandatory startup assets before implementation begins.
- Assign one owner agent per startup asset.

## LLM Cost Rule
- Apply `docs/project/llm-token-matrix.md` as the default LLM and token policy.
- Use `Claude Sonnet 4.6` as the default model for daily coding.
- Use `Claude Haiku 4.5` for quick, low-risk tasks and short discussions.
- Use `Claude Opus 4.7` only for exceptional complex cases after an insufficient Sonnet attempt.

## RTK Rule
- Use RTK only for Git commands where output compression is useful (`rtk git diff`, `rtk git status`, `rtk git log`).
- Run PowerShell commands and `.ps1` scripts directly in native PowerShell; do not use `rtk powershell`.
- Run tests, lint, logs, and other non-Git commands natively unless another runner is explicitly documented.
