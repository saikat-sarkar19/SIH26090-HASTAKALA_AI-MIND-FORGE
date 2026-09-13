// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hastakala/main.dart';

void main() {
  testWidgets('Hastakala app smoke test - displays general splash screen with Get Started', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HastakalaApp());
    await tester.pumpAndSettle();

    // Verify splash screen content
    expect(find.textContaining('Traditional Artisans'), findsOneWidget);
    // Verify general Get Started button
    expect(find.textContaining('Get Started'), findsOneWidget);
  });
}
