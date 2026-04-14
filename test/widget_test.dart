import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kosmos3d/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KosmosApp());

    // Verify that the title is rendered
    expect(find.text('KOSMOS 3D'), findsWidgets);
  });
}
