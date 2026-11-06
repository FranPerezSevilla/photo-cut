import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/features/print_job/guided_print_wizard.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

final bool _runStoreScreenshots =
    Platform.environment['STORE_SCREENSHOTS'] == '1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 home with a selected photo', (WidgetTester tester) async {
    _configurePhone(tester);
    final _Fixture fixture = await _fixture();

    await _pump(
      tester,
      HomeScreen(
        imagePickerGateway: _StoreImagePicker(fixture.image),
        imageProcessor: fixture.processor,
        localeOverride: const Locale('en'),
        onLocaleChanged: (_) {},
      ),
    );
    await tester.tap(find.byKey(const Key('choose-photo')));
    await _pumpUi(tester);

    expect(find.text('Print photos at the exact size'), findsOneWidget);
    await _capture(tester, '01-home-selected.png');
  }, skip: !_runStoreScreenshots);

  testWidgets('02 real size step with 10 x 15 preset', (
    WidgetTester tester,
  ) async {
    _configurePhone(tester);
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 1 of 4'), findsOneWidget);
    expect(find.text('10 × 15 cm'), findsOneWidget);
    await _capture(tester, '02-size-10x15.png');
  }, skip: !_runStoreScreenshots);

  testWidgets('03 real focused framing editor', (WidgetTester tester) async {
    _configurePhone(tester);
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('open-framing-focus')));
    await _pumpUi(tester);

    expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);
    expect(find.text('Adjust framing'), findsOneWidget);
    await _capture(tester, '03-framing-focus.png');
  }, skip: !_runStoreScreenshots);

  testWidgets('04 real A4 sheet step', (WidgetTester tester) async {
    _configurePhone(tester);
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 3 of 4'), findsOneWidget);
    expect(find.text('A4'), findsOneWidget);
    await _capture(tester, '04-sheet-a4.png');
  }, skip: !_runStoreScreenshots);

  testWidgets('05 real 10 x 15 photo-paper sheet', (
    WidgetTester tester,
  ) async {
    _configurePhone(tester);
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await _configureTenByFifteen(tester);

    expect(find.text('Photo 10 × 15 cm'), findsOneWidget);
    await _capture(tester, '05-sheet-10x15.png');
  }, skip: !_runStoreScreenshots);

  testWidgets('06 real wizard review step', (WidgetTester tester) async {
    _configurePhone(tester);
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await _configureTenByFifteen(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 4 of 4'), findsOneWidget);
    expect(find.textContaining('100 × 150 mm'), findsWidgets);
    await _capture(tester, '06-review.png');
  }, skip: !_runStoreScreenshots);
}

void _configurePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(450, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<_Fixture> _fixture() async {
  final Uint8List photoBytes = base64Decode(
    (await File('test_resources/store-landscape.png.base64').readAsString())
        .trim(),
  );
  final SelectedImage image = SelectedImage(
    bytes: photoBytes,
    displayName: 'photo-cut-demo.png',
  );
  return _Fixture(
    image: image,
    processor: _StoreImageProcessor(photoBytes: photoBytes),
  );
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const PhotoCutScrollBehavior(),
      locale: const Locale('en'),
      supportedLocales: PhotoCutLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        PhotoCutLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
  await _pumpUi(tester);
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _configureTenByFifteen(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('size-preset-10x15')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-paper-photo-10x15')));
  await _pumpUi(tester);

  for (int i = 0; i < 7; i += 1) {
    await tester.tap(find.byKey(const Key('copies-minus')));
    await tester.pump();
  }
  await _pumpUi(tester);
}

Future<void> _capture(WidgetTester tester, String filename) async {
  await _pumpUi(tester);
  await expectLater(
    find.byType(Scaffold).last,
    matchesGoldenFile('generated/$filename'),
  );
}

final class _Fixture {
  const _Fixture({required this.image, required this.processor});

  final SelectedImage image;
  final _StoreImageProcessor processor;
}

final class _StoreImagePicker implements ImagePickerGateway {
  const _StoreImagePicker(this.image);

  final SelectedImage image;

  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    return ImageSelectionSuccess(image);
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    return const ImageSelectionCancelled();
  }
}

final class _StoreImageProcessor implements ImageProcessor {
  const _StoreImageProcessor({required this.photoBytes});

  final Uint8List photoBytes;

  static final SourceImageSize _size = SourceImageSize(
    widthPixels: 600,
    heightPixels: 400,
  );

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => _size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: photoBytes, size: _size);
  }
}
