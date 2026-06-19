# Mobile — CixioHub Flutter App

Cross-platform Flutter app for CixioHub. One codebase targets both **iOS** and **Android**.

## Setup

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Copy and edit the `.env` file (already included with defaults):
   ```
   API_BASE_URL=http://localhost:8000
   ```
4. Run:
   ```bash
   # List available devices
   flutter devices

   # Run on iOS Simulator
   flutter run -d ios

   # Run on Android Emulator
   flutter run -d android
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point, router setup
├── config/
│   └── app_config.dart          # API URL and constants
├── models/
│   ├── user.dart
│   ├── message.dart
│   └── document.dart            # TODO: implement
├── services/
│   ├── api_service.dart         # Dio HTTP client with auth interceptor
│   ├── auth_service.dart        # Login, register, logout
│   └── notification_service.dart # TODO: FCM token registration
└── screens/
    ├── auth/
    │   ├── login_screen.dart    # Complete
    │   └── register_screen.dart # Complete
    ├── chat/
    │   └── chat_screen.dart     # Partial — SSE streaming TODO
    ├── documents/
    │   └── documents_screen.dart # TODO
    ├── todos/
    │   └── todos_screen.dart    # TODO
    └── profile/
        └── profile_screen.dart  # TODO
```

## What Students Need to Complete

| File | Status | Task |
|------|--------|------|
| `screens/chat/chat_screen.dart` | Partial | Implement SSE streaming (see TODO comments) |
| `screens/documents/documents_screen.dart` | Stub | Implement file list + upload |
| `screens/todos/todos_screen.dart` | Stub | Implement todo CRUD |
| `screens/profile/profile_screen.dart` | Stub | Implement profile load/edit + avatar |
| `services/api_service.dart` | Partial | Implement token refresh on 401 |
| `main.dart` | Partial | Initialize Firebase for push notifications |

## Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com/
2. Add Android app: package `com.cixiohub.app`, download `google-services.json` → `android/app/`
3. Add iOS app: bundle `com.cixiohub.app`, download `GoogleService-Info.plist` → `ios/Runner/`
4. Uncomment Firebase initialization in `main.dart`

## SSE Streaming (Chat)

The backend sends chat responses as Server-Sent Events. In Flutter, use the `http` package:

```dart
import 'package:http/http.dart' as http;

final request = http.Request('POST', Uri.parse('$apiUrl/chat/sessions/$sessionId/messages'));
request.headers['Authorization'] = 'Bearer $token';
request.headers['Content-Type'] = 'application/json';
request.body = jsonEncode({'content': content, 'use_rag': useRag});

final streamedResponse = await http.Client().send(request);
await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
  for (final line in chunk.split('\n')) {
    if (line.startsWith('data: ') && line != 'data: [DONE]') {
      final data = jsonDecode(line.substring(6));
      // data['delta'] contains the token
    }
  }
}
```
