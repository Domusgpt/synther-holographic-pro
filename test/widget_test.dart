import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synther_holographic_pro/main.dart';

void main() {
  testWidgets('Synther Professional loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SyntherApp());

    // Verify that the app loads successfully
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Allow the app to fully render
    await tester.pumpAndSettle();
    
    // Basic smoke test - verify app doesn't crash on startup
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}