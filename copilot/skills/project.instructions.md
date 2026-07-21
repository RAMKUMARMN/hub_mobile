# Copilot Instructions for Hub Mobile

Guiding rules for code generation, edits, and prompts when working on this project.

- Follow Dart null-safety and latest stable Flutter idioms.
- Keep public APIs stable: avoid renaming top-level classes or public methods unless requested.
- Place code in existing folders: `lib/models`, `lib/services`, `lib/screens`, `lib/widgets`, `lib/theme`.
- Prefer `const` widgets when possible and use `final` for fields that do not change.
- Keep UI changes visually minimal unless the task requests design changes.
- Add or update tests for any non-trivial logic (`test/` or widget tests).
- Run `flutter format` and `dart analyze` locally; ensure no analyzer errors are introduced.
- When modifying platform files (android/ios), explain the exact build or signing implications.
- Provide concise PR description and suggested commit message.

Commands to run locally:

```
flutter pub get
flutter analyze
flutter test
flutter format .
```
