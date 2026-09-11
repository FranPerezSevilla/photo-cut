import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/theme/photo_cut_brand.dart';

void main() {
  testWidgets('hero branding stays inside a compact phone-safe box', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 140,
              child: Center(
                child: PhotoCutBrand(light: true, hero: true),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('photo-cut-brand-icon')), findsOneWidget);
    expect(find.byKey(const Key('photo-cut-wordmark')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final Rect icon = tester.getRect(
      find.byKey(const Key('photo-cut-brand-icon')),
    );
    final Rect wordmark = tester.getRect(
      find.byKey(const Key('photo-cut-wordmark')),
    );

    expect(icon.height, lessThanOrEqualTo(84));
    expect(wordmark.bottom, lessThanOrEqualTo(140));
  });
}
