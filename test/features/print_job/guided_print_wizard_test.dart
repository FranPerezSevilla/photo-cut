import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/guided_print_wizard.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  testWidgets('keeps normal phone steps compact with fixed navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(find.byKey(const Key('wizard-fixed-navigation')), findsOneWidget);
    expect(find.byKey(const Key('wizard-step-static')), findsOneWidget);
    expect(find.byKey(const Key('wizard-step-scroll')), findsNothing);
    expect(find.textContaining('Paso 1 de 4'), findsOneWidget);
    expect(find.text('¿Qué tamaño quieres imprimir?'), findsOneWidget);
    expect(find.byKey(const Key('size-preset-35x45')), findsOneWidget);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
    expect(find.byKey(const Key('wizard-fit-mode')), findsOneWidget);
    expect(find.byKey(const Key('wizard-step-scroll')), findsNothing);

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
    expect(find.byKey(const Key('wizard-step-scroll')), findsNothing);
  });

  testWidgets('refreshes the live preview after returning from framing', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final SelectedImage image = SelectedImage(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAACMAAAAtCAIAAACrsUV+AAAARElEQVR42u3V'
        'sREAEBREwc+oQyXKEQkUqAwVaUFCtK+Bnbnk0m4tvpTjVyQSiUR6VRm9Wo9E'
        'IpFIl68Ra1qPRCKRSHcdIZ4DvGdT4rYAAAAASUVORK5CYII=',
      ),
      displayName: 'synthetic.png',
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

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    MemoryImage livePreviewProvider() {
      final Finder previewImage = find.descendant(
        of: find.byKey(const Key('wizard-live-preview')),
        matching: find.byType(Image),
      );
      expect(previewImage, findsWidgets);
      return tester.widget<Image>(previewImage.first).image as MemoryImage;
    }

    final MemoryImage before = livePreviewProvider();
    expect(before.bytes, isNotEmpty);

    await tester.tap(find.byKey(const Key('open-framing-focus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);

    final Slider slider = tester.widget<Slider>(
      find.byKey(const Key('framing-zoom-slider')),
    );
    slider.onChanged!(1.5);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar encuadre'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('framing-focus-screen')), findsNothing);
    final MemoryImage after = livePreviewProvider();
    expect(after.bytes, isNotEmpty);
    expect(identical(after.bytes, before.bytes), isFalse);
    expect(find.textContaining('1.5×'), findsWidgets);
  });

  testWidgets('small screens retain scroll as an accessibility fallback', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: GuidedPrintWizard(
          image: SelectedImage(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            displayName: 'foto.jpg',
          ),
          imageProcessor: const _FakeImageProcessor(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wizard-step-scroll')), findsOneWidget);
    expect(find.byKey(const Key('wizard-fixed-navigation')), findsOneWidget);
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
