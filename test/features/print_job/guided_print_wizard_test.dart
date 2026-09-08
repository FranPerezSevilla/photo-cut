import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/guided_print_wizard.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  testWidgets('keeps compact preview while advancing through four focused steps', (
    WidgetTester tester,
  ) async {
    final SelectedImage image = SelectedImage(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      displayName: 'foto.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GuidedPrintWizard(
          image: image,
          imageProcessor: const _FakeImageProcessor(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wizard-live-preview')), findsOneWidget);
    expect(find.textContaining('Paso 1 de 4'), findsOneWidget);
    expect(find.text('¿Qué tamaño quieres imprimir?'), findsOneWidget);
    expect(find.byKey(const Key('size-preset-35x45')), findsOneWidget);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
    expect(find.byKey(const Key('wizard-fit-mode')), findsOneWidget);

    await tester.tap(find.text('Foto completa'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-inside-static-notice')), findsOneWidget);
    expect(find.byKey(const Key('visual-framing-editor')), findsNothing);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 3 de 4'), findsOneWidget);
    expect(find.byKey(const Key('wizard-copy-count')), findsOneWidget);
    expect(find.byKey(const Key('copies-plus')), findsOneWidget);
    expect(find.byKey(const Key('wizard-advanced-options')), findsOneWidget);
  });
}

final class _FakeImageProcessor implements ImageProcessor {
  const _FakeImageProcessor();

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async {
    return SourceImageSize(widthPixels: 4000, heightPixels: 3000);
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) {
    throw UnimplementedError();
  }
}
