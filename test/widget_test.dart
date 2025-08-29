// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multispace_cloner/main.dart';

void main() {
  testWidgets('MultiSpace app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MultiSpaceApp());

    // Verify that our app loads properly
    expect(find.text('MultiSpace'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Should navigate to app list screen or show permission dialog
    // This test just verifies the app doesn't crash
  });
}
