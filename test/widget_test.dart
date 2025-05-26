// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mylucky/main.dart';

void main() {
  testWidgets('MyLucky app basic test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyLuckyApp());

    // Verify that our app shows the main screen elements.
    expect(find.text('MyLucky'), findsOneWidget);
    expect(find.text('뽑기 시작'), findsOneWidget);

    // Verify that the start button exists
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
