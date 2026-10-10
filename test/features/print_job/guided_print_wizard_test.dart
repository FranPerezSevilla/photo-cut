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
    expect(find.byKey(const Key('size-preset-26x32')), findsOneWidget);
    expect(find.text('26 × 32 mm'), findsOneWidget);

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
    expect(find.text('A4'), findsOneWidget);
    expect(find.text('210 × 297 mm'), findsOneWidget);
    expect(find.text('Carta (US Letter)'), findsOneWidget);
    expect(find.text('Foto 10 × 15 cm'), findsOneWidget);
    expect(find.byKey(const Key('wizard-paper-custom')), findsOneWidget);
    expect(find.byKey(const Key('wizard-paper-orientation')), findsOneWidget);
    expect(find.byKey(const Key('paper-orientation-auto')), findsOneWidget);
    expect(find.byKey(const Key('wizard-copy-count')), findsOneWidget);
    expect(find.byKey(const Key('copies-plus')), findsOneWidget);
    expect(find.byKey(const Key('wizard-advanced-options')), findsOneWidget);
    expect(find.byKey(const Key('wizard-step-scroll')), findsNothing);
  });

  testWidgets('refreshes sheet validation after backtracking and correction', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    Finder lengthField(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextFormField),
    );

    FilledButton nextButton() => tester.widget<FilledButton>(
      find.byKey(const Key('wizard-next')),
    );

    await tester.enterText(
      lengthField(const Key('wizard-width-input')),
      '400',
    );
    await tester.enterText(
      lengthField(const Key('wizard-height-input')),
      '400',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 3 de 4'), findsOneWidget);
    expect(nextButton().onPressed, isNull);

    await tester.tap(find.byKey(const Key('wizard-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 3 de 4'), findsOneWidget);
    expect(nextButton().onPressed, isNull);

    await tester.tap(find.byKey(const Key('wizard-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('size-preset-26x32')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 3 de 4'), findsOneWidget);
    expect(nextButton().onPressed, isNotNull);
  });

  testWidgets('warns only on Next for an unusually small photo size', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    final Finder widthField = find.descendant(
      of: find.byKey(const Key('wizard-width-input')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(widthField, '9');
    await tester.pump();

    expect(find.byKey(const Key('unusual-photo-size-dialog')), findsNothing);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unusual-photo-size-dialog')), findsOneWidget);
    expect(find.text('Comprueba este tamaño'), findsOneWidget);
    expect(find.textContaining('inferior a 10 mm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unusual-photo-size-review')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unusual-photo-size-dialog')), findsNothing);
    expect(find.textContaining('Paso 1 de 4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unusual-photo-size-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
  });

  testWidgets('warns and can continue for an unusually large photo size', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    final Finder widthField = find.descendant(
      of: find.byKey(const Key('wizard-width-input')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(widthField, '1001');
    await tester.pump();

    expect(find.byKey(const Key('unusual-photo-size-dialog')), findsNothing);

    final FilledButton nextButton = tester.widget<FilledButton>(
      find.byKey(const Key('wizard-next')),
    );
    expect(nextButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unusual-photo-size-dialog')), findsOneWidget);
    expect(find.textContaining('superior a 1000 mm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unusual-photo-size-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
  });

  testWidgets('explains both anomalies for a mixed extreme photo size', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('wizard-width-input')),
        matching: find.byType(TextFormField),
      ),
      '9',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('wizard-height-input')),
        matching: find.byType(TextFormField),
      ),
      '1001',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('inferior a 10 mm'), findsOneWidget);
    expect(find.textContaining('supera los 1000 mm'), findsOneWidget);
  });

  testWidgets('10 mm and 1000 mm boundaries do not show an unusual-size warning', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('wizard-width-input')),
        matching: find.byType(TextFormField),
      ),
      '10',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('wizard-height-input')),
        matching: find.byType(TextFormField),
      ),
      '1000',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unusual-photo-size-dialog')), findsNothing);
    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
  });

  testWidgets('numeric inputs keep focus across typing and deletion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    Finder textField(Key key) {
      return find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextFormField),
      );
    }

    EditableText editable(Key key) {
      return tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(EditableText),
        ),
      );
    }

    Future<void> editWithoutLosingFocus(
      Key key,
      List<String> edits,
    ) async {
      final Finder field = textField(key);
      expect(field, findsOneWidget);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pump();
      expect(editable(key).focusNode.hasFocus, isTrue);

      for (final String value in edits) {
        tester.testTextInput.enterText(value);
        await tester.pump();
        expect(
          editable(key).focusNode.hasFocus,
          isTrue,
          reason: 'Focus was lost after editing $key to "$value".',
        );
        expect(editable(key).controller.text, value);
      }
    }

    await editWithoutLosingFocus(
      const Key('wizard-width-input'),
      <String>['1', '18', '180', '18', '1', '', '26'],
    );
    await editWithoutLosingFocus(
      const Key('wizard-height-input'),
      <String>['3', '32', '3', '', '32'],
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await tester.pumpAndSettle();
    expect(editable(const Key('wizard-width-input')).controller.text, '100');
    expect(editable(const Key('wizard-height-input')).controller.text, '150');

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('wizard-paper-custom')));
    await tester.pumpAndSettle();

    await editWithoutLosingFocus(
      const Key('wizard-paper-width-input'),
      <String>['1', '12', '120', '12', '', '120'],
    );
    await editWithoutLosingFocus(
      const Key('wizard-paper-height-input'),
      <String>['1', '18', '180', '18', '', '180'],
    );

    await tester.ensureVisible(find.byKey(const Key('wizard-advanced-options')));
    await tester.tap(find.byKey(const Key('wizard-advanced-options')));
    await tester.pumpAndSettle();

    await editWithoutLosingFocus(
      const Key('wizard-margin-input'),
      <String>['1', '12', '1', '', '8'],
    );
    await editWithoutLosingFocus(
      const Key('wizard-gap-input'),
      <String>['1', '12', '1', '', '2'],
    );
  });

  testWidgets('custom paper can be entered in the sheet step', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('wizard-paper-custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wizard-custom-paper-editor')), findsOneWidget);
    expect(find.byKey(const Key('wizard-step-scroll')), findsOneWidget);

    final Finder paperFields = find.descendant(
      of: find.byKey(const Key('wizard-custom-paper-editor')),
      matching: find.byType(TextFormField),
    );
    expect(paperFields, findsNWidgets(2));
    await tester.enterText(paperFields.at(0), '120');
    await tester.pumpAndSettle();

    final Finder refreshedFields = find.descendant(
      of: find.byKey(const Key('wizard-custom-paper-editor')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(refreshedFields.at(1), '180');
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('paper-orientation-landscape')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('paper-orientation-landscape')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Personalizado · 120 × 180 mm'), findsOneWidget);
    expect(find.textContaining('Horizontal'), findsOneWidget);
  });

  testWidgets('paper orientation can be forced to landscape', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paper-orientation-landscape')));
    await tester.pumpAndSettle();

    final ChoiceChip landscape = tester.widget<ChoiceChip>(
      find.byKey(const Key('paper-orientation-landscape')),
    );
    expect(landscape.selected, isTrue);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('A4 · Horizontal'), findsOneWidget);
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
