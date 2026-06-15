---
name: security-review
description: "Security review checklist for features handling user input, authentication, authorization, admin actions, API exposure, or secrets."
---

# Security Review

## Checklist
- Identity and authentication
- Authorization and access control
- Input validation
- Output escaping
- Secret handling
- Abuse paths and rate limiting
- Logging and auditability

## Output
- blocking risks
- recommended controls
- docs to update in security baseline

## Expert Execution Standard
- Order findings by severity and exploitability.
- Prefer root-cause mitigations over cosmetic client-side barriers.
- If a control changes user interaction, include keyboard access, readable feedback, and acceptable latency as part of the recommendation.

