# LLM Token Matrix (Solo)

## Objective
- Keep quality high while reducing token cost in day-to-day coding sessions.
- Use model escalation only when needed.
- Reduce Git terminal-output noise with RTK.

## Default Matrix
| Level | Model | Default Use | Cost Rule |
|---|---|---|---|
| L1 | Claude Haiku 4.5 | Quick tasks, low-risk checks, short discussion | Use first for short tasks and draft work |
| L2 | Claude Sonnet 4.6 | Daily coding default (implement, debug, refactor) | Primary model for most sessions |
| L3 | Claude Opus 4.7 | Exceptional complex cases only | Use only after a failed L2 attempt |

## Escalation Rule
1. Start with Haiku for short and low-risk requests.
2. Move to Sonnet for normal coding and debugging.
3. Escalate to Opus only if at least one Sonnet attempt is insufficient.
4. Return to Sonnet after the complex step is resolved.

## Agents And Skills Note
- Agents and skills improve structure, context routing, and consistency.
- They do not fully replace model capability for deep reasoning tasks.
- Keep Opus for rare high-complexity decisions where Sonnet is not enough.

## RTK Operational Rule
- RTK is reserved for Git commands (`rtk git diff`, `rtk git status`, `rtk git log`).
- Run PowerShell commands and `.ps1` scripts directly; never wrap them with `rtk powershell`.
- Run tests, lint, and logs natively unless a separate output tool is explicitly required.

## Review Cadence
- Weekly check:
  - Opus usage ratio target: <= 15% of sessions.
  - Sessions where RTK was used for Git output.
  - Repeated escalation patterns (to refine prompts first).
