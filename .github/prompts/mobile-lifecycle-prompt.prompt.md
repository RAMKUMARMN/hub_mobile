---
mode: agent
agent: mobile-lifecycle
name: mobile-lifecycle-prompt
description:
  Prompt for the mobile-lifecycle agent. Analyzes Flutter StatefulWidget lifecycle management and build() performance to detect memory leaks and rendering bottlenecks.
---

### Analysis Checklist

#### 1. Dispose Leaks

For each file under `lib/screens/` and `lib/widgets/`:

- **Find `dispose()` method** — if it exists, verify it calls `.dispose()` or `.cancel()` on every field that implements a disposable interface:
  - `TextEditingController` → `.dispose()`
  - `ScrollController` → `.dispose()`
  - `AnimationController` → `.dispose()`
  - `FocusNode` → `.dispose()`
  - `StreamController` → `.close()`
  - `StreamSubscription` → `.cancel()`
  - `Timer` / `Timer.periodic` → `.cancel()`
  - `http.Client()` → `.close()`

- **If no `dispose()` exists** but the class owns any of the above, flag as **critical** — resource leak.

- **If `dispose()` exists but misses any owned resource**, flag that specific resource.

#### 2. Subscription Leaks

For each file:

- **Timers**: Check for `Timer(...)` or `Timer.periodic(...)` calls. Verify the returned `Timer?` field has a corresponding `.cancel()` in `dispose()`. Flag if the timer callback uses `setState` without `mounted` check.

- **Streams**: Check for `.listen()` or `.stream.listen()` calls. Verify the returned `StreamSubscription` has `.cancel()` in `dispose()`.

- **HTTP Clients**: Check for `http.Client()` instantiation. Verify `.close()` is called. Flag unscoped clients that are created per-method but never closed — they hold open connections.

#### 3. Heavy build() Methods

For each `build(BuildContext context)`:

- **List computations**: Flag any `.where()`, `.map()`, `.toList()`, `.sort()`, `.reversed` inside `build()` that recompute on every frame. Suggest extracting to a getter or using `useMemoized` / `compute`.

  Example finding:
  ```
  todos_screen.dart:130 — .where() on every build
  pending = _todos.where((t) => !t.completed).toList()
  → Extract to a getter: List<Todo> get _pending => _todos.where((t) => !t.completed).toList();
  ```

- **Nested branching**: Flag `build()` methods with >4 levels of conditional nesting (loading/error/empty/list). Suggest extracting each state into a separate private method.

- **Theme/MediaQuery**: Flag repeated `Theme.of(context)` or `MediaQuery.of(context)` calls — cache locally: `final theme = Theme.of(context);`

- **Expensive inline logic**: Flag `DateTime.parse()`, string formatting (e.g., `padLeft`, `toStringAsFixed`), or heavy switch/map lookups inside `build()`. Suggest extracting to a getter or `useMemoized`.

- **Object creation**: Flag helper widgets created inline that don't use `const`. Suggest extracting to `StatelessWidget` with `const` constructor.

#### 4. Unnecessary setState()

For each file:

- **Boilerplate state machines**: Flag screens that manage loading/error/data state with multiple `bool`/`String?` fields and `setState` calls. Suggest using Riverpod `AsyncValue` with `.when()` pattern for less code and fewer rebuilds.

- **Toggle-only setState**: Flag `setState()` calls that toggle a single UI feature (e.g., switch, checkbox) when the widget should use `Consumer` to scope the rebuild to just that feature.

- **Over-scoped rebuilds**: Flag `setState` in parent widgets that causes child widgets to rebuild unnecessarily. Children should be `const` or use `Consumer` for their data scopes.

#### 5. Post-async Guard Checks

- Every `setState()` after an `await` must be guarded: `if (mounted) setState(...)`
- Every navigation call (`.go()`, `.push()`, `.pop()`) after an `await` must be guarded: `if (mounted) context.go(...)`
- Flag any unguarded `setState` or navigation after async

### Constraints

- Read-only analysis — do not create, modify, or delete any files
- All findings must include file path and line number
- Every critical finding must include a concrete code snippet fix
- If `flutter analyze` is available, run it to detect dispose-related warnings

### Success Criteria

- Outputs a structured report (JSON or Markdown table)
- Each finding includes: `file`, `line`, `severity` (critical/medium/low), `category` (dispose_leak | subscription_leak | heavy_build | unnecessary_setstate | missing_mounted_guard), `widget`, `description`, `recommendation` (with code snippet)
- Cross-cutting summary with count of issues per category and severity
- Recommendations are actionable — copy-paste ready refactored code

### Usage Template

```
Analyze the Flutter app for memory leaks and performance bottlenecks.

Scope: [dispose|build|setstate|streams|all]
Report format: [json|table|markdown]

For each file under lib/screens/ and lib/widgets/:
1. Verify all disposable resources are properly released in dispose()
2. Check for unclosed timers, streams, and HTTP clients
3. Flag expensive computations in build() methods
4. Identify unnecessary setState() calls that trigger excess rebuilds
5. Verify mounted guards on all post-async state updates

Output a per-file findings report with line numbers and fix code snippets.
Do not modify any files — analysis only.
```
