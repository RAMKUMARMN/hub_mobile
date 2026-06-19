---
name: discover-flutter-screens
description: Map the Flutter screen viewports and routing architecture.
---

# Discover Flutter Screens

Analyze lib/screens/ to map the mobile UI navigation tree.

## Focus Areas
- Auth Screens (login_screen.dart, register_screen.dart)
- Feature Screens (chat_screen.dart, documents_screen.dart, todos_screen.dart)

## Workflow
1. Route the hub folder agent to plugin/skills for this specific skill folder.
2. Invoke the native "discoverScreens" tool.
3. Return the compiled routing map.
