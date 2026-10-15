---
name: ui-referentiel
description: "Shared UI/UX rules for any interface: icons, row actions, modals, forms, tables, accessibility, states. Use before coding or reviewing a screen, modal, table or form."
---

# UI Referentiel (status: trial)

Layers 1 and 2 live here. Layer 3 (palette, type, tone, one memorable element, usage profile, derogations) lives in the project `docs/project/charte-graphique.md`.
Precedence: layer 3 wins on visual values (colors, fonts); layers 1 and 2 win on behavior and accessibility. A project deviates from a rule only through a written derogation in its charter.
When auditing, list the violated rule ids (UIR-x.y). Rule ids are stable.

## Parameters (defaults, trial)
- Undo delay for a deletion: 10 s, "Annuler" reachable by keyboard.
- Row actions collapse from 3 to 2 icons (third in a "⋯" menu) below 768 px window width.
- Deletion icon: trash can, always red; meaning is carried by the shape.
- Field validation: on leaving the field, never while typing; error shown inline.
- Submit button: disabled until the form is valid (owner choice); keep the reason visible next to it, no tooltip on it, use aria-disabled.

## Layer 1 - Universal
- UIR-1.1 Icon-only control: accessible name (aria-label) plus tooltip on hover and keyboard focus.
- UIR-1.2 Contrast: 3:1 minimum for meaningful icons and borders, 4.5:1 for body text.
- UIR-1.3 Target size: 24x24 CSS px minimum (or compliant spacing); aim for 44x44 on important controls.
- UIR-1.4 Color is never the only signal: add shape, icon or text.
- UIR-1.5 Semantic HTML before ARIA; no clickable div/span; every field has a label.
- UIR-1.6 Visible keyboard focus (never outline-none without a replacement); not hidden by fixed elements.
- UIR-1.7 Errors: text next to the field, icon plus text, never in a tooltip, entered values kept; after a server-side submit error, an error summary with focus moved to it.
- UIR-1.8 One primary button per zone; label = action verb, sentence case, no punctuation.
- UIR-1.9 Destructive action: undo or confirmation, never immediate and irreversible.
- UIR-1.10 Data table: associated title, declared headers, readable first column, sticky header.
- UIR-1.11 Gestures (drag, pinch) have a click and keyboard alternative.
- UIR-1.12 Dates and numbers via Intl.*, no hard-coded format.
- UIR-1.13 Every interactive component defines: default, hover, focus, active, disabled, loading, error.
- UIR-1.14 Named design tokens (color, spacing, radius, duration); no raw values in components.
- UIR-1.15 Motion: 150-250 ms, only to express state; honor prefers-reduced-motion.
- UIR-1.16 Multi-row selection: row icons and row menus disabled; a bulk action bar appears.

## Layer 2 - Owner rules
- UIR-2.1 No table column titled "Action". Row actions are icons side by side, according to need.
- UIR-2.2 Validate = green check, edit = grey pencil, delete = red trash can, cross = cancel/close.
- UIR-2.3 Up to 3 row icons on desktop; 2 below 768 px (third in "⋯"). One single action: no icon, the row itself is the action.
- UIR-2.4 Usage profile declared per application (daily or occasional), overridable per view. Daily: icon-only for the closed set check / pencil / trash / "+" / cross. Occasional: icon plus visible label.
- UIR-2.5 Deletion: icon-only allowed if undoable (archive plus "Annuler" notification for the undo delay); otherwise visible label and in-place confirmation (the button becomes "Confirmer la suppression"), never a modal. Overrides the usage profile.
- UIR-2.6 Add: green square with "+" rather than the word "Ajouter" (occasional profile: word next to it).
- UIR-2.7 Never a modal inside a modal. A modal opens neither another modal nor a modal panel; menus and tooltips are fine. Repetitive or non-critical tasks do not use a modal.
- UIR-2.8 Row editing: non-modal side panel by default; in-place editing for a narrow table.
- UIR-2.9 Fewest clicks: every common journey has a click count in the spec; exceeding the target is a defect.
- UIR-2.10 Red and green are never distinguished by color alone: check and trash shapes are mandatory.
