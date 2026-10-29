import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kosmos3d/main.dart' as app;

void main() {
  testWidgets('App starts with its providers and saved preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_seen_setup': true});
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('kosmos_smoke_'),
    ))!;
    addTearDown(() => directory.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    await tester.runAsync(() async {
      app.main();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.text('KOSMOS 3D'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
