---
mode: agent
agent: mobile-state
name: mobile-state-prompt
description: "Prompt for the mobile-state agent. Creates or updates Riverpod providers, notifiers, state classes, and runs build_runner code generation."
---

### Requirements

1. **Providers:** Use Riverpod with code generation (`riverpod_annotation`, `riverpod_generator`). Use `@riverpod` annotation.
2. **Notifiers:** Use `Notifier` / `AsyncNotifier` for complex state with actions. Use `FutureProvider` / `StreamProvider` for async data.
3. **State Classes:** Use sealed classes or freezed for state unions. Each state class has idle, loading, success, error variants.
4. **Code Generation:** Run `dart run build_runner build --delete-conflicting-outputs` after creating/modifying providers.
5. **Dependencies:** Use `ref.watch` to depend on other providers. Keep provider dependency graph shallow.

### Constraints

- All providers use code generation — no manual `Provider` or `StateNotifierProvider`
- State classes immutable — use `copyWith` for updates
- Errors handled through state variants, not exceptions
- Run `build_runner` after changes and verify generated files compile

### Success Criteria

- `dart run build_runner build` completes without conflicts
- Generated `.g.dart` files compile without errors
- `flutter analyze` passes
- Provider state transitions correctly (idle → loading → success/error)

### Usage Template

```
Create an [provider_name] provider for [domain]:
- State type: [AsyncNotifier | FutureProvider | StreamProvider]
- Dependencies: [list of other providers]
- Actions: [methods like fetch, create, update, delete]
Show the diff and wait for my confirmation before applying.
```
