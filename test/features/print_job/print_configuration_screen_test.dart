import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('renders defaults and a live first-page preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PrintConfigurationScreen(image: _image())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preparar en Photo Cut'), findsOneWidget);
    expect(find.text('Paso 1 de 2 · Configura el documento'), findsOneWidget);
    expect(find.byKey(const Key('layout-page-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('layout-photo-0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('layout-photo-7')), findsOneWidget);
    expect(find.text('8 copias · 1 página'), findsOneWidget);
  });

  testWidgets('invalid input is accessible and disables review', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PrintConfigurationScreen(image: _image())),
    );
    await tester.pumpAndSettle();

    final Finder widthField = find.byKey(
      const ValueKey<String>('photo-width-millimetres'),
    );
    await _scrollTo(tester, widthField);
    await tester.enterText(widthField, '0');
    await tester.pump();

    expect(find.text('Introduce una medida mayor que 0.'), findsOneWidget);

    final Finder reviewButton = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, reviewButton);
    final FilledButton button = tester.widget<FilledButton>(reviewButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('copy count updates the live pagination summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PrintConfigurationScreen(image: _image())),
    );
    await tester.pumpAndSettle();

    final Finder copyField = find.byKey(const Key('copy-count'));
    await _scrollTo(tester, copyField);
    await tester.enterText(copyField, '40');
    await tester.pump();

    await _scrollTo(
      tester,
      find.byKey(const Key('layout-page-summary')),
      delta: -300,
    );
    expect(find.text('Página 1 de 2 · 40 copias'), findsOneWidget);
  });

  testWidgets('valid review emits the immutable configuration', (tester) async {
    PrintJobConfiguration? reviewed;
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          onReview: (
            BuildContext context,
            PrintJobConfiguration configuration,
          ) {
            reviewed = configuration;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder reviewButton = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, reviewButton);
    await tester.tap(reviewButton);
    await tester.pump();

    expect(reviewed, isNotNull);
    expect(reviewed?.photoWidth.inMillimetres, 35);
    expect(reviewed?.copyCount, 8);
  });
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

SelectedImage _image() {
  return SelectedImage(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    displayName: 'synthetic.png',
  );
}
