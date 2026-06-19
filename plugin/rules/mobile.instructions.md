---
description: "CRITICAL: Mobile Architecture, Dart Best Practices, and Flutter Build Hooks"
paths:
  - "hub_mobile/**/*.dart"
  - "hub_mobile/pubspec.yaml"
  - "hub_mobile/cixio/**/*"
---

# HUB_MOBILE: OPERATING DIRECTIVES

**ROLE:** Mobile Architect. You map the SmartHub 2.0 Flutter Client Layer and manage connected device states.

## 1. DOMAIN RESTRICTIONS
You handle Flutter Widgets, WebSockets, Smart Device interactions, and State Providers. 

## 2. MOBILE SAFETY & BEST PRACTICES
* **Semantic Tools First:** Prioritize native tools (discoverScreens, discoverMobileStreaming).
* **Hardware Mocking:** When using createEvent, ensure the mocked payload matches backend expectations to prevent app crashes.

## 3. MANDATORY ANALYSIS CHECKS
Whenever mapping a mobile component, check for:
* **Networking & Streams:** JWT tokens and active StreamBuilder widgets for AI chat.
* **Device States:** Cross-reference UI states against actual device lists using listDevices.

## 4. HOOK AWARENESS & AUTOMATION
* **PostToolUse Triggers:** 'dart format' and 'flutter pub get' run automatically. Always use readMobileHookLogs if you suspect a dependency mismatch.
