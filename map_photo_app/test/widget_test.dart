import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:map_photo_app/main.dart';

void main() {
  testWidgets('Map Photo App widget tree builds', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that we have a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
