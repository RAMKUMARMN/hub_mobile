---
mode: agent
agent: mobile-planner
name: mobile-planner-prompt
description: "Prompt for the mobile-planner agent. Generates structured implementation plans for new screens, state management, API integration, push notifications, or CI pipelines."
---

### Requirements

1. **Explore the codebase** to understand current file structure, existing patterns, and conventions.
2. **Produce a numbered step-by-step plan** covering each file change required.
3. **Identify dependencies** between steps (e.g., create model before provider, provider before screen).
4. **Risk assessment** — flag breaking changes, data loss risks, or build-breaking changes.
5. **Validation plan** — list `flutter analyze`, `flutter test`, `dart run build_runner build` commands for each stage.

### Constraints

- Do not implement code — output the plan only
- Reference specific file paths relative to repo root
- Follow existing conventions (Riverpod, GoRouter, Dio patterns)

### Output Format

```
## Implementation Plan: [Title]

### Step 1: [File path]
Action: create | modify | delete
Details: [what to add/change]

### Step 2: ...
...

### Risk Assessment
- [Critical/Medium/Low] risks identified
- [Specific items]

### Validation Checklist
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `dart run build_runner build` completes
```

### Usage Template

```
Plan the implementation of [describe task].
Consider [constraints or special requirements].
```
