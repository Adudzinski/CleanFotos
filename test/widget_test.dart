import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cleanfotos_app/l10n/strings.dart';
import 'package:cleanfotos_app/theme/app_theme.dart';

void main() {
  test('all supported languages resolve', () {
    for (final code in ['en', 'es', 'de', 'fr', 'pt', 'it']) {
      expect(AppStrings.of(code).languageCode, code);
    }
    // Unknown language falls back to English.
    expect(AppStrings.of('xx').languageCode, 'en');
  });

  testWidgets('theme builds a scaffold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: Text('ok')),
    ));
    expect(find.text('ok'), findsOneWidget);
  });
}
