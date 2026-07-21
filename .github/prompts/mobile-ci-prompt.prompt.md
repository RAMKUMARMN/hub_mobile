---
mode: agent
agent: mobile-ci
name: mobile-ci-prompt
description: "Prompt for the mobile-ci agent. Creates or updates GitHub Actions CI workflows for Flutter builds with analyze, test, APK build, iOS build, and code generation."
---

### Requirements

1. **Workflow Layout:** Create `.github/workflows/mobile-ci.yml` with jobs for `analyze` (flutter analyze), `test` (flutter test), `build-android` (APK), and `build-ios` (simulator).
2. **Code Generation:** Add a step to run `dart run build_runner build --delete-conflicting-outputs` before analyze.
3. **Caching:** Cache Flutter SDK (`~/.pub-cache`), pub dependencies, and platform-specific caches.
4. **Artifacts:** Upload Android APK as a build artifact.
5. **Notifications:** Post build summary to Slack via `SLACK_WEBHOOK_URL` secret.

### Constraints

- Android builds use `flutter build apk --debug`
- iOS builds use `flutter build ios --no-codesign --debug` (macOS runner only)
- Run `flutter pub get` before build_runner
- Secrets referenced by name — never inline values

### Success Criteria

- Workflow triggers on push, pull_request, and workflow_dispatch
- `flutter analyze` passes
- `flutter test` passes
- Android APK builds and uploads as artifact
- iOS simulator build completes on macOS runner

### Usage Template

```
Create a CI workflow with:
- Platforms: [android, ios, both]
- Triggers: [push, PR, workflow_dispatch]
- [Optional] Notification: [Slack webhook secret]
Show the diff and wait for my confirmation before applying.
```
