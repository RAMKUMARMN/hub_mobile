---
name: discover-cixio-registries
description: Map the internal shared registries inside the cixio/ folder.
---

# Discover Shared Registries

Analyze the cixio/registries/ and cixio/src/ TypeScript configurations.

## Workflow
1. Route the hub folder agent to plugin/skills for this specific skill folder.
2. Invoke "search" or "read" targeting apiRegistry.json and toolRegistry.ts.
3. Return the registry mappings.
