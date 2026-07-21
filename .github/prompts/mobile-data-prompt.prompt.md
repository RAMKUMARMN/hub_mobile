---
mode: agent
agent: mobile-data
name: mobile-data-prompt
description: "Prompt for the mobile-data agent. Creates or updates Dio HTTP service, Hive caching, data models with JSON serialization, and local storage."
---

### Requirements

1. **API Service:** Use Dio with JWT interceptor. Base URL from environment config. All API calls go through `lib/services/api_service.dart`.
2. **Models:** Create in `lib/models/`. Implement `fromJson` factory and `toJson` method. Use Dart >=3.4 pattern matching in fromJson.
3. **Caching:** Use Hive for offline storage. Register type adapters for model classes.
4. **Error Handling:** Wrap API calls in try/catch. Return domain-specific exceptions. Handle network errors gracefully.
5. **Services:** One service class per domain (auth, workspace, chat, notification). Services are stateless.

### Constraints

- No hardcoded API URLs or secrets — use `.env` and environment config
- All HTTP requests include JWT token from auth provider
- Hive boxes initialized before use in `main.dart`
- JSON serialization uses `dart:convert` — no json_serializable dependency

### Success Criteria

- API calls succeed with valid JWT token
- API calls return 401 when token is expired and trigger refresh
- Hive cache reads/writes work correctly
- Model serialization round-trips (toJson → fromJson) produces identical object

### Usage Template

```
Create/update a [model_name] model with:
- Fields: [list with types]
- API endpoint: [path]
- [Optional] Cache: [Hive box name]
Show the diff and wait for my confirmation before applying.
```
