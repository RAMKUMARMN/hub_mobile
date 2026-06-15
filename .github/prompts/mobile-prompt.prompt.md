---
mode: agent
agent: mobile-agent
name: mobile-agent-prompt
description:
  A system prompt for the `hub_mobile` assistant. It defines the agent's role as a focused cross-platform mobile helper for the repository, outlines allowed tools, behavior rules, response format, safety heuristics, and developer hints to ensure safe and effective assistance with Flutter development, build tasks, and platform integration.
---

### Requirements:

1.  **Flutter Development and Testing:**
    *   The workflow should support running the Flutter app on emulators/simulators via `flutter run` for local development.
    *   It must include steps to run static analysis (`flutter analyze`) and tests (`flutter test`) before merging.
    *   Builds should be tested for both Android (`flutter build apk`) and iOS (`flutter build ios`) targets.
    *   Support for environment-specific configurations using `flutter_dotenv` and build flavors.
    *   Secrets (e.g., API URLs, Firebase config) must be managed through environment variables and never hardcoded.

2.  **State Management and Routing:**
    *   State management should use Riverpod (`flutter_riverpod`) with code generation (`riverpod_annotation`, `riverpod_generator`).
    *   Navigation should use GoRouter for declarative routing with deep link support.
    *   API calls should use Dio with auth interceptors for JWT token management.
    *   Local caching should use Hive for offline support.

3.  **Push Notifications:**
    *   Firebase Cloud Messaging must be configured for both Android and iOS push notification delivery.
    *   Notification handling should support foreground, background, and terminated state scenarios.
    *   Deep linking from notification taps should route to the correct app screen.

4.  **Cross-Platform Considerations:**
    *   Platform-specific code should use Dart conditional imports or the `dart:io` platform checks.
    *   UI must adapt to both Android (Material) and iOS (Cupertino) design conventions where appropriate.
    *   File/image picker integrations must handle both Android and iOS permission models.
    *   Code generation must be run with `dart run build_runner build --delete-conflicting-outputs` after model changes.

### Constraints:

*   **Language:** Dart (>=3.4.0).
*   **Framework:** Flutter SDK 3.x.
*   **State Management:** Riverpod with code generation.
*   **Routing:** GoRouter.
*   **HTTP Client:** Dio with JWT interceptor.
*   **Local Storage:** Hive, shared_preferences.
*   **Push Notifications:** Firebase Cloud Messaging.
*   **Code Generation:** build_runner, riverpod_generator.
*   **CI/CD Platform:** GitHub Actions (preferred).
*   **Security:** Never hardcode secrets or API keys. Use environment variables and `.env` files.
*   **Reproducibility:** Builds must be reproducible for the same commit and configuration.

### Success Criteria:

*   The app launches successfully on both Android emulator and iOS simulator via `flutter run`.
*   All static analysis checks pass (`flutter analyze`) with zero errors.
*   All tests pass (`flutter test`) without failures.
*   Builds complete successfully for both Android (`flutter build apk --debug`) and iOS (`flutter build ios --no-codesign --debug`).
*   API calls work correctly with JWT authentication on both platforms.
*   Push notifications are received and handled correctly on both Android and iOS.
*   Code generation runs cleanly with `dart run build_runner build` without conflicts.

### Usage Template (copy-paste)

Below are ready-to-use prompt templates you can paste to the `mobile-agent` chat to generate workflows, patches, and documentation. Replace bracketed values before sending.

- CI workflow setup:

```
Generate a GitHub Actions workflow `/.github/workflows/mobile-ci.yml` with these behaviours:
- Triggers: `push` to `main`, `pull_request`, `workflow_dispatch`.
- Jobs: `analyze` (flutter analyze), `test` (flutter test), `build-android` (flutter build apk --debug), `build-ios` (flutter build ios --no-codesign --debug).
- Caching: Cache Flutter, pub, and platform-specific dependencies.
- Artifacts: Upload the Android APK as a build artifact.
- Notifications: post summary to Slack via `SLACK_WEBHOOK_URL`.

Inputs to set: `SLACK_WEBHOOK_URL`, `FIREBASE_CONFIG_BASE64` (for google-services.json and GoogleService-Info.plist) stored as GitHub Secrets.

Deliverables: workflow file, README snippet for secrets and usage, PR body template, and a verification checklist. Provide diffs and wait for approval before applying changes.
```

- Add a new screen:

```
Add a new "Profile" screen to the mobile app following existing patterns:
- Create a new screen file at `lib/screens/profile/profile_screen.dart`.
- Add routing in GoRouter configuration.
- Display the user's avatar, name, email, and a "Sign Out" button.
- Fetch user data via `GET /api/v1/users/me` using the Dio service instance.
- Use Riverpod for state management.
- Follow the existing code style and widget patterns (see `lib/screens/chat/chat_screen.dart` for reference).
- Run `flutter analyze` after changes to verify code quality.

Show diffs and wait for my confirmation before applying patches.
```

- Implement offline caching:

```
Add offline caching for the chat screen using Hive. When the app is offline:
1. Show cached messages from the last active session.
2. Display a "You are offline" banner at the top.
3. Queue outgoing messages and send them when connectivity is restored.
4. Use Hive boxes for local storage of messages.

Follow existing patterns from `lib/services/` and `lib/models/message.dart`. Show the implementation plan and diffs before applying any changes.
```

### Chat example (copy-paste)

Use these short chat transcripts to interact with the `mobile-agent`. Paste, edit the bracketed values, and send.

- CI setup flow:

```
User: Create a CI workflow for the Flutter app that runs analyze and test on push and PR. Also build the Android APK as an artifact. Show diffs and wait for my confirmation.
```

Agent (expected):
- Scans repository for existing workflow and config files.
- Produces draft workflow YAML and shows a unified diff.
- Asks: "Do you want me to apply these changes to the repo? (yes/no)"

User:
```
yes
```

- New feature request:

```
User: Implement a "Forgot Password" flow. Add a screen with an email input field that calls `POST /api/v1/auth/forgot-password`. Show a success message and a link back to login. Follow existing patterns (Riverpod, GoRouter, Dio). Show the diff before applying.
```

Agent (expected):
- Reviews existing auth screens for style and pattern alignment.
- Creates the new screen, shows the diff, and asks for confirmation.

User (to approve):
```
I confirm the proposed changes. Please apply them.
```

If the agent needs missing inputs (e.g., the API endpoint for forgot password), it will ask a single targeted question such as: "Please confirm the API endpoint URL for the forgot password flow."
