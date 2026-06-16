---
applyTo: "**/*.dart"
---
# Project coding standards for Dart (Flutter)

Apply the [general coding guidelines](./general-coding.instructions.md) to all code.

## Dart Guidelines
- Use Dart >=3.4 features: records, patterns, switch expressions
- Use null safety features: `?`, `!`, `late`, `required`
- Prefer `final` over `var` for immutable declarations
- Use factory constructors for complex object creation
- Use sealed classes for state unions and result types
- Run `dart format` before committing

## Flutter Guidelines
- Use Riverpod with code generation for all state management
- Use GoRouter for all navigation (including deep link handling)
- Use Dio with JWT interceptor for all API calls
- Use `build_runner` for code generation after model/provider changes
- Keep widgets focused — extract reusable widgets into `lib/widgets/`
- Use `const` constructors where possible for performance
- Use platform-adaptive widgets (Material on Android, Cupertino on iOS)

## Project Structure
- Screens in `lib/screens/` — one file per screen
- Services in `lib/services/` — API, auth, notifications, storage
- Models in `lib/models/` — data classes with JSON serialization
- Providers in `lib/providers/` — Riverpod providers
- Reusable widgets in `lib/widgets/`

## Push Notification Guidelines
- Firebase Cloud Messaging handles both Android and iOS push
- Handle foreground, background, and terminated states
- Deep link from notification taps via GoRouter
- Test on physical devices — simulators have limited push support
