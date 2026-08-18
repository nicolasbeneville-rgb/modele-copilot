---
name: validate-syntax
description: Validate Google Apps Script syntax (function/variable/closure patterns)
model: claude-3-5-sonnet
---

# Skill: Validate Syntax

## Purpose
Pre-flight syntax validation for Google Apps Script files before clasp push. Catches CommonJS + closure issues that Apps Script V8 runtime may flag at deploy time.

## Checks
1. **Function declarations**: Duplicates, missing brackets, invalid scope
2. **Variable patterns**: Unused declarations, undefined references, shadowing
3. **Global scope**: PropertiesService, ScriptApp references
4. **Closure patterns**: Nested functions, event handlers (onOpen, onEdit)
5. **Apps Script specifics**: Trigger registration, AuthMode validation

## Command
```powershell
Validate-AppsScriptSyntax -Path Code.js -Strict
```

## Output
```
[OK]     Code.js         ✅ No syntax issues
[WARN]   Utils.js        ⚠️  Unused variable: oldConfig (line 42)
[ERROR]  Admin.js        ❌ Duplicate function: validateUser (lines 15, 87)
```

## Exit Codes
- **0**: OK (safe to push)
- **1**: WARN (push ok, but review)
- **2**: ERROR (do not push)

## Integration
Called by agent-deployer dry-run stage. Can also be invoked standalone for linting before commit.
