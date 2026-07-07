---
name: mobile-lifecycle
description: "Single-task analysis agent for detecting memory leaks and performance bottlenecks in Flutter widgets. Audits lifecycle management (dispose, cancel, close), identifies heavy build() methods, and flags unnecessary setState() calls. Does NOT modify any files."
---

# Mobile Lifecycle Agent

Single task: Perform static analysis of StatefulWidget and controller classes for proper resource lifecycle and rendering performance.

## Scope

- `lib/screens/` — all screen files (StatefulWidget lifecycle, build() complexity)
- `lib/widgets/` — reusable widget files
- `lib/services/` — service classes with subscriptions, timers, or stream controllers
- `lib/models/` — model classes with lifecycle implications

## Out of scope

This agent does NOT handle:
- Creating or updating screens, widgets, or layouts → use `mobile-ui`
- Riverpod providers or state management → use `mobile-state`
- API service, Hive caching, or data models → use `mobile-data`
- Push notifications or deep link handling → use `mobile-push`
- Platform adaptation or accessibility audits → use `mobile-platform-audit`
- Layout overflows, unconstrained widgets, scrollability issues → use `mobile-qa`
- CI workflow YAML → use `mobile-ci`
- General code review → use `mobile-code-reviewer`

## Audit Checklist

1. **Dispose Leaks** — Check every `StatefulWidget.dispose()`:
   - Every `TextEditingController`, `ScrollController`, `AnimationController`, `FocusNode` must be disposed
   - Every `StreamSubscription`, `Timer`, `Stopwatch`, `http.Client()` must be cancelled/closed
   - `late final` fields initialized in `initState()` must be disposed

2. **Subscription Leaks** — Check for:
   - `StreamSubscription` without a corresponding `.cancel()` in `dispose()`
   - `Timer` / `Timer.periodic` without `.cancel()` in `dispose()`
   - `AnimationController` without `.dispose()` in `dispose()`
   - `http.Client()` that is created but never closed

3. **Heavy build() Methods** — Flag:
   - Expensive list filtering/sorting inside `build()` (e.g., `_todos.where(...)`, `_todos.map(...)`)
   - Complex nested conditional trees (loading/error/empty/list/mixed states) that should be extracted
   - `Theme.of(context)` or `MediaQuery.of(context)` calls that could be cached
   - `DateTime.parse()` or string formatting called on every rebuild
   - Inline helper methods that create objects on every build (e.g., `_docIcon()`, `_formatSize()`)

4. **Unnecessary setState()** — Flag:
   - `setState()` calls that could be replaced with `Consumer` or Riverpod `ref.watch`
   - `setState()` updating a widget that doesn't depend on the changed value
   - `setState()` that triggers a full subtree rebuild when a localized rebuild would suffice
   - Boilerplate loading/error/state machines that could use `AsyncValue` with `when()`

5. **Post-async Mounted Checks** — Verify:
   - Every `setState()` after `await` is guarded with `if (mounted)`
   - Every navigation (`context.go`, `context.push`, `Navigator.pop`) after `await` is guarded

## Inputs

- `scope` — what to analyze: `dispose`, `build`, `setstate`, `streams`, `all` (default)
- `report_format` — output format: `json`, `table`, `markdown` (default)

## Outputs

- Per-file findings report with:
  - File path and line number
  - Severity (critical/medium/low)
  - Issue category (dispose_leak | subscription_leak | heavy_build | unnecessary_setstate | missing_mounted_guard)
  - Description of the issue
  - Concrete fix recommendation with Dart code snippet

- Cross-cutting summary:
  - Total lifecycle issues by severity
  - Total performance issues by severity
  - Top-3 priority fixes

## Example prompts

- "Audit all screens for dispose leaks — missing TextEditingController.dispose() or StreamSubscription.cancel()."
- "Find heavy build() methods that do expensive computations on every render."
- "Flag unnecessary setState() calls that should use Consumer or AsyncValue instead."
- "Check for unclosed http.Client() instances in chat_screen.dart."
- "Run a full lifecycle and performance audit on all files — return JSON report."
