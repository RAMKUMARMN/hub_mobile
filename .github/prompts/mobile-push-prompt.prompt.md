---
mode: agent
agent: mobile-push
name: mobile-push-prompt
description: "Prompt for the mobile-push agent. Configures Firebase Cloud Messaging push notifications and deep link handling in Flutter."
---

### Requirements

1. **FCM Setup:** Initialize Firebase in `main.dart`. Configure `firebase_messaging` plugin. Request notification permissions on iOS.
2. **Token Management:** Get FCM token on app start. Send token to backend API for targeting. Handle token refresh.
3. **Notification Handling:** Handle foreground (show in-app banner), background (tap opens app), and terminated (tap launches app) states.
4. **Deep Links:** Route notification taps to the correct GoRouter screen. Parse payload data for route parameters.
5. **Platform Channels:** Configure Android notification channels. Handle iOS notification permissions request.

### Constraints

- Firebase config files (google-services.json, GoogleService-Info.plist) loaded from CI secrets
- `firebase_core` initialized before any Firebase service
- Notification payload structure matches backend API contract
- Test on physical devices — simulators have limited push support

### Success Criteria

- FCM token is generated on app start
- Token is sent to the backend API
- Foreground notifications show an in-app banner
- Background notification tap navigates to correct screen
- Terminated state notification tap launches app and navigates to correct screen

### Usage Template

```
Set up FCM push notifications with:
- [Optional] Deep link routes: [list of GoRouter paths]
- [Optional] Android channels: [channel names]
Show the diff and wait for my confirmation before applying.
```
