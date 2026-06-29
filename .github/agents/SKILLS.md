---
name: mobile-agent-skills
description: Skills for the `hub_mobile` assistant: Flutter/Dart development, Riverpod state management, GoRouter navigation, Dio API integration, Firebase push notifications, cross-platform builds, and safe mobile app maintenance. The coordinator routes requests to single-task agents.
---

# Mobile Agent — Skills Catalog

This document describes the skills, inputs/outputs, tools, safety constraints, and example prompts the `mobile-agent` (see `mobile-agent.agent.md`) supports for the `hub_mobile` repository.

**Purpose**
- Provide a compact, discoverable list of the agent's actionable capabilities so maintainers can quickly know what to ask and what to expect.

**Quick summary**
- **Primary domain:** Flutter/Dart cross-platform mobile app (iOS + Android), screens, services, state management, push notifications.
- **Primary outputs:** repository patches/diffs, GitHub Actions workflow files, CI job templates, README snippets, and PR-ready descriptions.
- **Primary safety posture:** Prepare and validate code changes; never autonomously publish to app stores or sign release builds without explicit maintainer confirmation.

## Capabilities

### UI Screens & Widgets (handled by `mobile-ui` agent)
- Create or update Flutter screens in `lib/screens/`
- Build reusable widgets in `lib/widgets/`
- Configure GoRouter navigation
- Apply theme and platform-adaptive design

### State Management (handled by `mobile-state` agent)
- Create Riverpod providers with code generation
- Implement AsyncNotifier, FutureProvider, StreamProvider patterns
- Run `dart run build_runner build` for code generation
- Manage state with sealed classes for loading/success/error

### API, Data & Models (handled by `mobile-data` agent)
- Dio HTTP client with JWT interceptor
- Data models with JSON serialization
- Hive caching and local storage
- Domain-specific service classes

### Push Notifications (handled by `mobile-push` agent)
- Firebase Cloud Messaging setup for Android and iOS
- Foreground, background, terminated state handling
- Deep link routing from notification taps
- FCM token management

### CI Workflows (handled by `mobile-ci` agent)
- Flutter analyze, test, and build jobs
- Android APK and iOS simulator builds
- Code generation step with build_runner
- Dependency caching and artifact upload

### Infrastructure Skills (reusable guides in `.agents/skills/`)
- `flutter-implement-json-serialization` — Model JSON serialization
- `flutter-add-widget-test` — Widget testing
- `flutter-use-http-package` — HTTP API calls
- `flutter-build-responsive-layout` — Responsive layouts
- `flutter-apply-architecture-best-practices` — Clean architecture
- `flutter-add-widget-preview` — Widget previews
- `flutter-setup-declarative-routing` — GoRouter setup
- `flutter-fix-layout-issues` — Layout troubleshooting
- `flutter-add-integration-test` — Integration testing
- `flutter-setup-localization` — App localization

## Inputs the agent expects (ask if missing)
- `screen_name` — the screen or feature to create or modify
- `platform` — which platform to target: `android`, `ios`, or `both`
- `api_endpoint` — the backend API endpoint to integrate with
- `provider_name` — the Riverpod provider to create or modify
- `model_name` — the data model to create or modify

## Outputs the agent produces
- New or modified Dart files (screens, widgets, providers, services, models)
- GoRouter route configuration updates
- CI workflow YAML files in `/.github/workflows/`
- README/docs snippets describing required secrets
- PR-ready changelog/summary and verification checklist

## Tools the agent uses
- Repository editing tools for making focused edits
- File search and read tools to inspect repo layout
- Progress tracking tools to manage multi-step tasks

## Safety, boundaries, and policies

- Never request or accept raw secrets in chat messages. Instead, ask for secret *names* (e.g., `FIREBASE_CONFIG_BASE64`) and instruct maintainers to set them in GitHub Secrets.
- Never publish to app stores or sign release builds without an explicit confirmation token: `CONFIRM_RELEASE_BUILD`.
- No direct Google Play or App Store Connect API operations.
- No automatic PR merging or repo-level approvals — draft and explain only.

## Confirmation and escalation rules
- Low-risk edits (formatting, docs, test additions): apply patches after a single maintainer approval.
- Medium-risk edits (new screens, service changes, model updates): require explicit approval before applying.
- High-risk edits (changes that enable release builds, alter signing configuration): require `CONFIRM_RELEASE_BUILD` and a second acknowledgment.

## Example prompts (how to ask the agent)

### UI Screens
- "Create a Profile screen with avatar, name, email, and a Sign Out button."
- "Add a reusable AppBar widget with platform-adaptive styling."

### State Management
- "Create a Riverpod provider for the auth state with login, logout, and token refresh."
- "Run build_runner to generate code for the new providers."

### API & Data
- "Create a Workspace model with fromJson/toJson for the workspace API response."
- "Add a JWT interceptor to the Dio HTTP client for auth token management."

### Push Notifications
- "Set up Firebase Cloud Messaging for push notifications with foreground and background handling."
- "Configure deep link routing from notification taps to the correct GoRouter screen."

### CI Workflows
- "Create a mobile-ci.yml workflow with analyze, test, build-apk, and build-ios jobs."

## Agent Architecture

The coordinator (`mobile-agent`) routes to single-task agents:

| Agent | Responsibility |
|---|---|
| `mobile-ui` | Flutter screens, widgets, layouts |
| `mobile-state` | Riverpod providers and state management |
| `mobile-data` | API service, Hive caching, data models |
| `mobile-push` | FCM push notifications and deep links |
| `mobile-ci` | CI workflows for Flutter builds |
| `mobile-planner` | Implementation planning |
| `mobile-code-reviewer` | Code review before merge |

## How progress is reported
- Each agent breaks tasks into steps and reports current/completed steps

## Where to find configuration
- Agent configs: `/.github/agents/*.agent.md`
- Prompts: `/.github/prompts/*.prompt.md`
- Skills: `/.agents/skills/*/SKILL.md`
- Hooks: `/.github/hooks/*.json`
- General guidelines: `/.github/copilot-instructions.md`

## Maintenance notes
- Keep `SKILLS.md` aligned with individual agent files and prompts
- When adding a new skill, create `/.agents/skills/<name>/SKILL.md` and update this catalog
- When adding a new single-task agent, create the agent file, prompt file, register it in the coordinator's handoffs, and add to `opencode.jsonc`
