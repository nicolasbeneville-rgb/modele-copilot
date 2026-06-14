# Learning Loop Skill

**Invoke this skill after every successfully completed task, bug fix, feature implementation, or architectural decision.**

## Purpose
Capture and codify lessons learned in real-time. Convert implicit knowledge into explicit decision records, enabling continuous model improvement and knowledge reuse across projects.

## Workflow

### At Task Completion
When you finish a task or resolve a bug:

1. **Extract the lesson** — Ask yourself:
   - What did I learn about this codebase, pattern, or tool?
   - What trap or pitfall did I avoid?
   - What worked well or failed?
   - Is this lesson project-specific or generic?

2. **Log to Decision Log** — Add an entry to `docs/project/decision-log.md`:
   ```markdown
   ### YYYY-MM-DD - [Brief Lesson Title]
   - Decision: what was learned or decided
   - Rationale: why this matters
   - Impact: scope and consequence
   - Tags: [RETRO-MODELE] if generic, [PROJECT_SPECIFIC] if local only
   - Owner: your name
   ```

3. **Tag for Model Reuse** — If the lesson is **generic and reusable across projects**:
   - Prefix the entry with **💡 [RETRO-MODELE]**
   - This signals the lesson should be incorporated into `modele-copilot` or VS Code user prompts.
   - Example: "💡 [RETRO-MODELE] - Always validate JSON schema before API calls"

4. **Examples of Generic Lessons (should be tagged [RETRO-MODELE])**:
   - Performance anti-patterns (e.g., N+1 queries, unbounded loops)
   - Security shortcuts taken and regretted (e.g., missing input validation)
   - Git workflow pitfalls (e.g., rebasing vs. merging strategies)
   - Deployment gotchas (e.g., environment variable precedence, cache invalidation)
   - Testing gaps that caused production bugs
   - API contract fragility (e.g., JSON schema drift)
   - Documentation anti-patterns (e.g., docs that rot)

5. **Examples of Project-Specific Lessons (tag [PROJECT_SPECIFIC])**:
   - Quirks of a legacy codebase
   - Specific team conventions
   - Constraints of a particular SaaS platform (e.g., Google Apps Script quotas)
   - Project-scoped business rules

## Decision Log Format (Use in docs/project/decision-log.md)

### Minimal Example
```markdown
### 2026-06-14 - Avoid rewriting files for small edits
- Decision: Use multi_replace_string_in_file for all edits ≤5 lines; never regenerate entire files.
- Rationale: Reduces token overhead by 60-80% and preserves merge history.
- Impact: Faster iterations, cleaner diffs, easier git blame.
- Tags: 💡 [RETRO-MODELE], token-optimization
- Owner: Copilot
```

### Full Example (with generic lesson)
```markdown
### 2026-06-14 - JSON schema validation before API dispatch
- Decision: Always validate request body against schema BEFORE calling external API.
- Rationale: Caught malformed request that caused 500 errors. Validation prevented 3 API calls.
- Impact: Faster error feedback, reduced API quota burn, better observability.
- Tags: 💡 [RETRO-MODELE], security, performance, quality-gates
- Owner: Dev Team
```

## Process Automation

This skill is **self-invoked** by the Copilot agent:
- After each bug fix → immediately log the lesson.
- After each feature completion → summarize the learning.
- At session end → check if any lessons were missed and backfill them.

**Manual override**: If you disagree with a logged lesson, edit `decision-log.md` directly or ask for a review.

## Model Sync

Periodically, lessons tagged **💡 [RETRO-MODELE]** are:
- Reviewed for correctness and clarity.
- Integrated into `.github/copilot-instructions.md` (as guardrails, patterns, or anti-patterns).
- Synchronized to VS Code user prompts via `sync-to-user-prompts.ps1`.
- Shared with the broader `nicolasbeneville-rgb/modele-copilot` community (if applicable).

---

## Quick Checklist

- [ ] Task completed successfully
- [ ] Lesson extracted (what, why, impact)
- [ ] Entry added to `docs/project/decision-log.md`
- [ ] Generic lessons tagged with 💡 [RETRO-MODELE]
- [ ] Owner assigned
