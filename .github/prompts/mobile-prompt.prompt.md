---
mode: agent
agent: mobile-agent
name: mobile-agent-prompt
description: "Coordinator prompt for the hub_mobile repository. Routes requests to the appropriate single-task agent based on the task domain."
---

This coordinator does NOT implement tasks directly. It identifies the task type and hands off:

| Task type | Agent | Prompt file |
|---|---|---|
| UI screens, widgets, layouts | `mobile-ui` | `mobile-ui-prompt.prompt.md` |
| Riverpod providers, state management | `mobile-state` | `mobile-state-prompt.prompt.md` |
| API service, Hive caching, data models | `mobile-data` | `mobile-data-prompt.prompt.md` |
| FCM push notifications, deep links | `mobile-push` | `mobile-push-prompt.prompt.md` |
| CI workflows for Flutter builds | `mobile-ci` | `mobile-ci-prompt.prompt.md` |
| Audit UI for platform adaptation, accessibility, navigation correctness | `mobile-platform-audit` | `mobile-platform-audit-prompt.prompt.md` |
| Analyze memory leaks, lifecycle disposal, build() performance | `mobile-lifecycle` | `mobile-lifecycle-prompt.prompt.md` |
| Detect layout overflows, unconstrained widgets, scrollability issues | `mobile-qa` | `mobile-qa-prompt.prompt.md` |
| Review code before merge | `mobile-code-reviewer` | `mobile-code-reviewer-prompt.prompt.md` |

If the request spans multiple domains, ask the user to break it into single-task prompts.
