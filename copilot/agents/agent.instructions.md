# Agent Usage Instructions — Hub Mobile

This document describes how the project agent should behave when generating or modifying code.

Behavior rules:
- Prefer minimal, well-scoped changes. Avoid touching unrelated files.
- Respect existing architecture and folder conventions (`lib/models`, `lib/services`, `lib/screens`, `lib/widgets`, `lib/theme`).
- Use Dart best practices: null-safety, `const` widgets, `final` fields, and immutability where appropriate.
- Add tests for new logic and for bug fixes that modify behavior.
- When changing platform (android/ios) files, include detailed steps to reproduce and commands to verify.

Testing and verification:
- After making changes, include instructions for running `flutter pub get`, `flutter analyze`, and relevant `flutter test` commands.
- If a change affects the UI, include a brief manual verification checklist (screen steps, expected result).

Communication and PRs:
- Provide a 1–3 sentence PR summary and a short, imperative commit message.
- List files changed and explain the root cause for fixes.

Limits:
- Do not create new third-party native plugins without explicit user approval.
- Avoid large-scale UI redesigns unless requested.
