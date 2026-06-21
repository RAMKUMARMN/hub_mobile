// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cixiohub_mobile/main.dart';

void main() {
  // ✅ Setup Firebase mocks before running tests
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const SmartHubApp());
    
    // Wait for async operations
    await tester.pumpAndSettle();
    
    // Just verify the app builds
    expect(find.byType(SmartHubApp), findsOneWidget);
  });
}