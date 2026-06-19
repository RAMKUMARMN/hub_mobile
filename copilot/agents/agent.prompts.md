# Agent Prompt Templates — Hub Mobile

Copy and fill these templates when asking the agent to perform tasks. Replace `{{}}` tokens.

1) Implement feature

Title: Implement {{short description}}
Context: Hub Mobile Flutter app. Relevant files: {{lib/path1}}, {{lib/path2}}
Requirements:
- Keep null-safety and existing folder structure.
- Add tests under `test/` covering the new behavior.
- Keep changes minimal and explain design choices.

Output:
- Patch (files changed and brief diff)
- PR title and description
- Commands to run locally

2) Fix build/runtime error

Error: {{paste full error output}}
Platform: `android|ios|web|desktop`
Reproduction steps: {{steps}}

Goal: Minimal, root-cause fix. Explain why the error happened and how to verify.

3) Refactor module/widget

Target: `{{WidgetOrModule}}` at `{{lib/path}}`
Goals: Improve readability/performance, preserve external behavior and public APIs, add tests if behavior changes.

4) Write tests

Target file(s): {{lib/path}}
Type: `unit|widget|integration`
Behaviors to cover: {{list}}

Deliverable: test files and commands to run them

5) PR / Commit message generator

Input: list of changed files and one-line summary of what changed
Output:
- PR title (imperative)
- PR description with bullet points and verification steps
- Conventional commit message
