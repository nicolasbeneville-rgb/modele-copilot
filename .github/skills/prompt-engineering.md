---
name: prompt-engineering
description: "Generate design or copy prompts for prototyping tools and content creation. Use for UI exploration, feature naming, empty states, and UX copy."
---

# Prompt Engineering

## Use When
- drafting prototype prompts
- generating UX copy
- exploring alternate layouts

## Rule
Use project docs for brand and tone; do not hardcode them in the skill.

## Expert Execution Standard
- Use CO-STAR for prompts intended to guide another AI assistant.
- For UI prompts, forbid arbitrary raw CSS and absolute coordinate layout unless the system explicitly documents it.
- Prefer utility-class systems or strict Flexbox/Grid primitives and ask for mathematically aligned spacing.
- For any visual prompt, include a text layout plan and accessibility/performance constraints in the prompt itself.
