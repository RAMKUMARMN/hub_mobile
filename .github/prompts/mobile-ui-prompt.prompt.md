---
mode: agent
agent: mobile-ui
name: mobile-ui-prompt
description: "Prompt for the mobile-ui agent. Creates or updates Flutter screens, widgets, layouts, and themes following the project's patterns."
---

### Requirements

1. **Screens:** Create in `lib/screens/<domain>/`. One file per screen. Use `const` constructors where possible.
2. **Widgets:** Extract reusable widgets into `lib/widgets/`. Keep focused and composable.
3. **Platform Adaptation:** Use Material widgets by default. Use Cupertino widgets for iOS-specific patterns where appropriate.
4. **Routing:** Register new screens in GoRouter configuration in `lib/router/`.
5. **State Access:** Use Riverpod `ref.watch` / `ref.read` for state — never pass state through constructors.
6. **Theming:** Use theme colors and text styles from `lib/theme/`. Avoid hardcoded values.

### Constraints

- Dart >=3.4 features (records, patterns, switch expressions)
- Null safety throughout
- No hardcoded strings — use localized strings from `lib/l10n/` where available
- Run `flutter analyze` after changes to verify code quality

### Success Criteria

- Screen renders on both Android emulator and iOS simulator
- `flutter analyze` passes with zero errors
- GoRouter navigation works for all routes
- Platform-adaptive UI behaves correctly on both platforms

### Usage Template

```
Create a [screen_name] screen with:
- Fields: [list of UI elements]
- Navigation: [route path]
- [Optional] Platform: [Android/iOS/both]
Show the diff and wait for my confirmation before applying.
```
