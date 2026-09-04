import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/app/photo_cut_app.dart';
import 'package:photo_cut/features/home/home_screen.dart';

void main() {
  testWidgets('renders the product promise and primary action', (tester) async {
    await tester.pumpWidget(const PhotoCutApp());

    expect(find.text('Photo Cut'), findsOneWidget);
    expect(find.text('Imprime fotos al tamaño exacto'), findsOneWidget);
    expect(find.text('Elegir foto'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.text('Probar PDF de ejemplo'), findsOneWidget);
  });

  testWidgets('primary action explains the current foundation state', (
    tester,
  ) async {
    await tester.pumpWidget(const PhotoCutApp());

    final Finder choosePhotoButton = find.text('Elegir foto');
    await tester.ensureVisible(choosePhotoButton);
    await tester.tap(choosePhotoButton);
    await tester.pump();

    expect(
      find.text('Base técnica lista. El selector de fotos llega en M2.'),
      findsOneWidget,
    );
  });

  testWidgets('development control opens the injected PDF spike', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          pdfSpikeBuilder: (BuildContext context) {
            return const Scaffold(body: Center(child: Text('PDF spike open')));
          },
        ),
      ),
    );

    final Finder spikeButton = find.text('Probar PDF de ejemplo');
    await tester.ensureVisible(spikeButton);
    await tester.tap(spikeButton);
    await tester.pumpAndSettle();

    expect(find.text('PDF spike open'), findsOneWidget);
  });
}
