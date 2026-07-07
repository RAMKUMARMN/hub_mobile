---
mode: agent
agent: mobile-platform-audit
name: mobile-platform-audit-prompt
description:
  Prompt for the mobile-platform-audit agent. Audits Flutter widget files for platform adaptation, accessibility, and navigation correctness without making any changes.
---

### Audit Checklist

#### 1. Platform Adaptation

For each `.dart` file under `lib/screens/` and `lib/widgets/`:

- **Material-only widgets:** Flag any use of `Scaffold`, `AppBar`, `FilledButton`, `NavigationBar`, `FloatingActionButton`, `TabBar`, `BottomNavigationBar`, `Drawer`, `SnackBar`, `AlertDialog`, `Chip`, `Switch`, `Checkbox`, `Slider`, `Radio`, `DropdownButton`, `PopupMenuButton`, `LinearProgressIndicator`, `CircularProgressIndicator`, `RefreshIndicator`, `Stepper`, `BottomSheet`, `ExpansionTile`, `DataTable`.
  - For each flagged widget, suggest:
    - If a Cupertino equivalent exists (`CupertinoButton` for `FilledButton`, `CupertinoNavigationBar` for `AppBar`, `CupertinoPageScaffold` for `Scaffold`), recommend it for iOS.
    - Or use `Theme.of(context).platform == TargetPlatform.iOS` branching.
    - Or use the `adaptive` property where available (e.g., `FloatingActionButton.adaptive`).

- **File-level check:** Record whether the file imports `'package:flutter/cupertino.dart'` alongside `'package:flutter/material.dart'`.

#### 2. Accessibility

For each `.dart` file under `lib/screens/` and `lib/widgets/`:

- **Interactive elements:** Check every `FilledButton`, `TextButton`, `OutlinedButton`, `IconButton`, `TextFormField`, `TextField`, `Checkbox`, `Switch`, `Slider`, `DropdownButton`, `InkWell`, `GestureDetector` has:
  - Either a `Semantics()` wrapper with `label` property
  - Or `semanticLabel` on the widget (e.g., `IconButton(semanticLabel: "...")`, `Image.asset(semanticLabel: "...")`)
  - Or `Tooltip` message that can serve as an accessibility label
  - Or `label` in `InputDecoration` for text fields

- **Decorative images:** Flag `Image.asset` or `Image.network` calls that are purely decorative but lack `ExcludeSemantics(child: Image.asset(...))` wrapping.

- **Navigation destinations:** Verify that `NavigationDestination` widgets have label text set.

- **Report format:** For each missing Semantics, include: file path, line number, widget type, and a suggested `Semantics(label: "...")` template.

#### 3. Navigation Patterns

For each `.dart` file and `lib/main.dart`:

- **Back gesture:** Check if `PopScope` (or deprecated `WillPopScope`) is used on iOS-specific screens. Flag screens that should intercept back but don't.
- **Platform branching:** Flag any custom back logic that does not consider `Platform.isIOS` vs Android's back button behavior.
- **Pop consistency:** Check whether the app uses `Navigator.pop()` or `context.pop()` consistently. Mixed usage is a flag.
- **`main.dart`:** Verify that the router setup uses a single `MaterialApp.router` — flag if no Cupertino-compatible alternative is offered.

#### 4. Theming

For `lib/theme/` and `lib/main.dart`:

- **Platform-aware theme:** Check if `main.dart` switches theme based on `Theme.of(context).platform` or `defaultTargetPlatform`. If only `MaterialApp.router` with no branching, flag it.
- **Cupertino overrides:** Check for any `CupertinoThemeData` configuration. If absent, recommend adding it.
- **Hardcoded values:** Flag any color, text style, or padding that does not use `Theme.of(context)` — suggest using theme values instead.

### Constraints

- Read-only audit — do not create, modify, or delete any files
- All findings must include file path and line number
- Use `flutter analyze` to verify findings if needed (run, do not fix)
- Recommendations should cite specific Flutter/Dart API names and patterns

### Success Criteria

- Outputs a structured report (JSON or Markdown table) with:
  - Per-file findings categorised as `platform`, `accessibility`, `navigation`, `theming`
  - Each finding includes: `file`, `line`, `widget`, `issue`, `recommendation`, `severity` (high/medium/low)
  - Cross-cutting summary: total findings per category, overall adaptation score
- Report is actionable — every finding has a concrete fix recommendation with code snippet

### Usage Template

```
Audit the Flutter UI for platform adaptation, accessibility, and navigation.

Scope: [screens|widgets|theme|all]
Report format: [json|table|markdown]

For each file, check:
1. Material-only widgets that should be adaptive for iOS
2. Missing Semantics labels on interactive elements
3. Back-gesture and navigation pattern issues
4. Theme adaptation gaps

Output a per-file findings report with file:line references and fix recommendations.
Do not modify any files — analysis only.
```
