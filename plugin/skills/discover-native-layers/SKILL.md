---
name: discover-native-layers
description: Map platform-specific permissions and build configurations (Android/iOS).
---

# Discover Native Layers

Analyze OS-specific layers (AndroidManifest.xml, Info.plist).

## Workflow
1. Route the hub folder agent to plugin/skills for this specific skill folder.
2. Invoke "search" or "read" targeting Info.plist and build.gradle.kts.
3. Return the native layer summary.
