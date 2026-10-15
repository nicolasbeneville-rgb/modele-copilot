---
name: design-harmony
description: "Audit ergonomic coherence, typography hierarchy, spacing rhythm, color harmony, and modern UI polish. Use before publishing or refactoring a visual component."
---

# Design Harmony

## Rule
Read `docs/project/charte-graphique.md` before auditing.
Read the `ui-referentiel` skill (layers 1-2) in addition to the project charter.

## Checklist
- typography hierarchy
- spacing scale coherence
- badge and label sizing
- color token consistency
- dark mode consistency if supported
- restrained polish: shadows with an offset and a soft blur only; no gradient text; no decorative glass or blur; transitions only to express state (150-250 ms)

## Output
- pass / conditional / fail
- prioritized fixes
- optional distinctive-direction recommendation (never the generic templated look)

## Expert Execution Standard
- Always read the design charter before judging visual quality.
- Forbid arbitrary raw CSS and absolute coordinate layout for structural alignment unless the design system explicitly defines that pattern.
- Require utility-class, token-based, or strict Flexbox/Grid alignment for reusable UI structure.
- Before validating, provide a text layout plan, a contrast/readability check, and a performance sanity check for decorative effects.
