---
name: mobile-agent-skills
description: Skills for the `hub_mobile` assistant: Flutter/Dart development, Riverpod state management, GoRouter navigation, Dio API integration, Firebase push notifications, cross-platform builds, and safe mobile app maintenance. The agent helps maintainers set up and manage the Flutter application in the repository, with a strong emphasis on safety and human oversight for release-signing actions.
---
# Mobile Agent — Skills Catalog

This document describes the skills, inputs/outputs, tools, safety constraints, and example prompts the `mobile-agent` (see `mobile agent.agent.md`) supports for the `hub_mobile` repository.

**Purpose**
- Provide a compact, discoverable list of the agent's actionable capabilities so maintainers can quickly know what to ask and what to expect.

**Quick summary**
- **Primary domain:** Flutter/Dart cross-platform mobile app (iOS + Android), screens, services, state management, push notifications.
- **Primary outputs:** repository patches/diffs, GitHub Actions workflow files, CI job templates, README snippets, and PR-ready descriptions.
- **Primary safety posture:** Prepare and validate code changes; never autonomously publish to app stores or sign release builds without explicit maintainer confirmation.

## Capabilities

- Generate or update GitHub Actions workflows to run `flutter analyze`, `flutter test`, `flutter build apk --debug`, and `flutter build ios --no-codesign --debug`.
- Create new screens and widgets following existing patterns (Riverpod, GoRouter, Dio, Hive).
- Configure Firebase Cloud Messaging for both Android and iOS push notifications.
- Run code generation with `dart run build_runner build --delete-conflicting-outputs`.
- Produce repository patches via `apply_patch` (small, focused edits) and provide diffs for review before applying.
- Run static checks in CI: `flutter analyze`, `flutter test`, optional dart format.
- Draft PR descriptions, risk notes, and post-build verification checklists.
- Create a safe release build workflow template guarded by typed confirmation.

## Inputs the agent expects (ask if missing)
- `platform` -- which platform to target: `android`, `ios`, or `both`.
- `screen_name` -- the name of the screen or feature to create or modify.
- `api_endpoint` -- the backend API endpoint to integrate with.
- `secret_names` -- repo secret names for `FIREBASE_CONFIG_BASE64`, `SLACK_WEBHOOK_URL`, etc.
- `notification` config -- repo secret name for `SLACK_WEBHOOK_URL` or `NOTIFICATION_EMAIL`.

## Outputs the agent produces
- New or modified workflow YAML files in `/.github/workflows/` (e.g., `mobile-ci.yml`).
- New Dart files (screens, services, models, providers) or patches to existing ones.
- README/docs snippets describing required secrets and how to run the app.
- PR-ready changelog/summary and verification checklist.
- Patches (diffs) applied with `apply_patch` when given explicit permission.

## Tools the agent uses
- `apply_patch` -- create or update repo files (used only after human confirmation for impactful changes).
- `read_file`, `file_search`, `grep_search` -- inspect repo layout and find Dart files or config files.
- `manage_todo_list` -- track multi-step tasks and report progress back to the maintainer.
- `run_in_terminal` -- only if explicitly requested; otherwise the agent outputs commands for maintainers to run locally or in CI.

## Safety, boundaries, and policies

- Never request or accept raw secrets in chat messages. Instead, the agent asks for secret *names* (e.g., `FIREBASE_CONFIG_BASE64`) and instructs maintainers to set them in GitHub Secrets.
- Never publish to app stores or sign release builds without an explicit confirmation token: `CONFIRM_RELEASE_BUILD` (maintainer must provide this token before the agent takes any action that would modify release signing configs or automated build steps).
- No direct Google Play or App Store Connect API operations.
- No automatic PR merging or repo-level approvals -- the agent drafts, explains, and optionally creates patches/PRs after explicit permission.

## Confirmation and escalation rules
- Low-risk edits (formatting, docs, test additions): agent may apply patches after a single maintainer approval.
- Medium-risk edits (new screens, service changes, model updates): require an explicit approval message before applying patches.
- High-risk edits (changes that enable or run release builds, alter signing configuration, or modify store submission steps): require the typed confirmation `CONFIRM_RELEASE_BUILD` and a second acknowledgment (e.g., "I understand this may produce a signed release artifact").

## Example prompts (how to ask the agent)
- "Create a `mobile-ci.yml` workflow that runs `flutter analyze`, `flutter test`, and builds Android APK on push and PR; post results to Slack via `SLACK_WEBHOOK_URL`."
- "Add offline message caching with Hive for the chat screen -- show me the patch before applying."
- "Implement a Forgot Password screen with Riverpod and GoRouter following existing patterns."

## Typical workflows the agent supports

1. Discovery: scan repo for `lib/screens/*`, `lib/services/*`, `lib/models/*`, and existing config files.
2. Draft: create a draft screen or feature with widgets, providers, and API integration.
3. Review: produce a PR description, risk summary, and required environment variables docs.
4. Apply (human-gated): upon confirmation, the agent can apply small patches or add CI steps; release builds require `CONFIRM_RELEASE_BUILD`.

## Error handling & troubleshooting behavior
- If `flutter analyze` or `flutter test` fails, the agent returns a concise diagnostics summary and suggests fixes.
- If `dart run build_runner build` shows conflicts or errors, the agent highlights them, explains likely causes, and recommends fixes.

## How progress is reported
- The agent uses `manage_todo_list` to break tasks into steps (discover -> draft -> patch -> verify) and will report the current step and completed steps in chat messages.

## Where to find the agent's configuration and prompts
- Agent behavior is documented in `/.github/agents/mobile agent.agent.md` and the repository prompt lives at `/.github/prompts/mobile-prompt.prompt.md`.

## Maintenance notes
- Keep `SKILLS.md` aligned with `mobile agent.agent.md` and `mobile-prompt.prompt.md` -- update all three when adding new capabilities (for example, support for a new state management approach or a different build system).
