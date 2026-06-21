// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cixiohub_mobile/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartHubApp());
    
    // Wait for any async operations
    await tester.pumpAndSettle();
    
    // Verify the app builds successfully
    expect(find.byType(SmartHubApp), findsOneWidget);
  });
}