# Prompt Templates for Hub Mobile

Use these templates to ask Copilot or the assistant to perform common coding tasks. Replace placeholders in `{{double braces}}`.

1) Implement feature

Task: {{short description}}
Context: Project is a Flutter app. Place new logic under `lib/`.
Requirements:
- Keep null-safety and existing folder structure.
- Add/update unit or widget tests under `test/`.
- Do not change unrelated files.

Files to change: {{path1}}, {{path2}} (optional)

Deliverables:
- Code patch (files and brief diff summary)
- Short PR description (1-2 sentences)
- Suggested commit message

2) Fix build or runtime error

Error: {{paste error output}}
Reproduction steps: {{how to reproduce}}

Goal: Provide a minimal fix, explain root cause, and list commands to verify the fix.

3) Refactor a widget or module

Refactor: `{{WidgetName}}` at `{{lib/path.dart}}`
Goals: Improve readability/performance while preserving behavior. Add widget tests if UI behavior changes.
Constraints: Keep API compatibility.

4) Write tests

Target: `{{lib/file.dart}}`
Type: `unit|widget|integration`
Coverage goals: {{functions or behaviors to cover}}

Deliverables: Test file(s) under `test/` and instructions to run them.

5) Create PR summary and commit message

Input: list of changed file paths and a short summary of intent.
Output:
- PR title (imperative tense)
- PR description with bullet list of changes and verification steps
- Conventional commit style message
