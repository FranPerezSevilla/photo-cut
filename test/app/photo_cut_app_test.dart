import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/app/photo_cut_app.dart';

void main() {
  testWidgets('renders the product promise and primary action', (tester) async {
    await tester.pumpWidget(const PhotoCutApp());

    expect(find.text('Photo Cut'), findsOneWidget);
    expect(find.text('Imprime fotos al tamaño exacto'), findsOneWidget);
    expect(find.text('Elegir foto'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('primary action explains the current foundation state', (
    tester,
  ) async {
    await tester.pumpWidget(const PhotoCutApp());

    await tester.tap(find.text('Elegir foto'));
    await tester.pump();

    expect(
      find.text('Base técnica lista. El selector de fotos llega en M2.'),
      findsOneWidget,
    );
  });
}
