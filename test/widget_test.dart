import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ouk_chaktrong/app.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const OukChaktrongApp());

    // Verify the app title is displayed
    expect(find.text('OUK CHAKTRONG'), findsOneWidget);
  });
}
