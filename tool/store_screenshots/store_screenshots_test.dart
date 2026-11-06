import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/features/print_job/guided_print_wizard.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

const Key _captureKey = Key('store-screenshot-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders faithful Google Play screenshots from production widgets', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final Uint8List photoBytes = await _buildDemoPhoto();
    final SelectedImage selectedImage = SelectedImage(
      bytes: photoBytes,
      displayName: 'photo-cut-demo.png',
    );
    final _StoreImageProcessor imageProcessor = _StoreImageProcessor(
      photoBytes: photoBytes,
    );

    await _pump(
      tester,
      HomeScreen(
        imagePickerGateway: _StoreImagePicker(selectedImage),
        imageProcessor: imageProcessor,
        localeOverride: const Locale('en'),
        onLocaleChanged: (_) {},
      ),
    );
    await tester.tap(find.byKey(const Key('choose-photo')));
    await tester.pumpAndSettle();
    await _capture(tester, '01-home-selected.png');

    await _pump(
      tester,
      GuidedPrintWizard(
        image: selectedImage,
        imageProcessor: imageProcessor,
      ),
    );
    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await tester.pumpAndSettle();
    await _capture(tester, '02-size-10x15.png');

    await _pump(
      tester,
      GuidedPrintWizard(
        image: selectedImage,
        imageProcessor: imageProcessor,
      ),
    );
    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-framing-focus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);
    await _capture(tester, '03-framing-focus.png');

    await _pump(
      tester,
      GuidedPrintWizard(
        image: selectedImage,
        imageProcessor: imageProcessor,
      ),
    );
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    expect(find.text('A4'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    await _capture(tester, '04-sheet-a4.png');

    await _pump(
      tester,
      GuidedPrintWizard(
        image: selectedImage,
        imageProcessor: imageProcessor,
      ),
    );
    await _configureTenByFifteen(tester);
    await _capture(tester, '05-sheet-10x15.png');

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 4 of 4'), findsOneWidget);
    expect(find.textContaining('100 × 150 mm'), findsWidgets);
    await _capture(tester, '06-review.png');

    final Directory output = Directory('build/store-screenshots');
    final List<String> generated = output
        .listSync()
        .whereType<File>()
        .map((File file) => file.path.split(Platform.pathSeparator).last)
        .where((String name) => name.endsWith('.png'))
        .toList()
      ..sort();
    expect(
      generated,
      <String>[
        '01-home-selected.png',
        '02-size-10x15.png',
        '03-framing-focus.png',
        '04-sheet-a4.png',
        '05-sheet-10x15.png',
        '06-review.png',
      ],
    );
  });
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
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
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _configureTenByFifteen(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('size-preset-10x15')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('wizard-next')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('wizard-next')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('wizard-paper-photo-10x15')));
  await tester.pumpAndSettle();

  for (int i = 0; i < 7; i += 1) {
    await tester.tap(find.byKey(const Key('copies-minus')));
    await tester.pump();
  }
  await tester.pumpAndSettle();

  expect(find.text('Photo 10 × 15 cm'), findsOneWidget);
  expect(find.text('1'), findsWidgets);
}

Future<void> _capture(WidgetTester tester, String filename) async {
  await tester.pump();
  final RenderRepaintBoundary boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  final ui.Image image = await boundary.toImage(pixelRatio: 3);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) {
    throw StateError('Could not encode $filename');
  }

  final File file = File('build/store-screenshots/$filename');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
}

Future<Uint8List> _buildDemoPhoto() async {
  const int width = 1200;
  const int height = 800;
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  final ui.Rect bounds = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

  canvas.drawRect(
    bounds,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        const ui.Offset(0, 520),
        const <ui.Color>[
          ui.Color(0xFF73C9FF),
          ui.Color(0xFFDDF5FF),
        ],
      ),
  );

  canvas.drawCircle(
    const ui.Offset(930, 150),
    78,
    ui.Paint()..color = const ui.Color(0xFFFFE6A3),
  );

  final ui.Path distant = ui.Path()
    ..moveTo(0, 510)
    ..lineTo(210, 300)
    ..lineTo(390, 470)
    ..lineTo(590, 250)
    ..lineTo(820, 500)
    ..lineTo(1030, 315)
    ..lineTo(1200, 500)
    ..lineTo(1200, 800)
    ..lineTo(0, 800)
    ..close();
  canvas.drawPath(distant, ui.Paint()..color = const ui.Color(0xFF5679A3));

  final ui.Path foreground = ui.Path()
    ..moveTo(0, 585)
    ..lineTo(270, 410)
    ..lineTo(485, 560)
    ..lineTo(745, 365)
    ..lineTo(1030, 565)
    ..lineTo(1200, 455)
    ..lineTo(1200, 800)
    ..lineTo(0, 800)
    ..close();
  canvas.drawPath(foreground, ui.Paint()..color = const ui.Color(0xFF234A63));

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 590, 1200, 210),
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 590),
        const ui.Offset(0, 800),
        const <ui.Color>[
          ui.Color(0xFF2CBBC8),
          ui.Color(0xFF0B63A5),
        ],
      ),
  );

  final ui.Path shore = ui.Path()
    ..moveTo(0, 650)
    ..quadraticBezierTo(310, 610, 620, 660)
    ..quadraticBezierTo(930, 705, 1200, 635)
    ..lineTo(1200, 800)
    ..lineTo(0, 800)
    ..close();
  canvas.drawPath(
    shore,
    ui.Paint()..color = const ui.Color(0xFF163D45).withValues(alpha: 0.30),
  );

  for (int x = 20; x < 1200; x += 90) {
    final double treeHeight = 52 + (x % 170).toDouble() * 0.22;
    final ui.Path tree = ui.Path()
      ..moveTo(x.toDouble(), 610)
      ..lineTo(x + 24.0, 610 - treeHeight)
      ..lineTo(x + 48.0, 610)
      ..close();
    canvas.drawPath(tree, ui.Paint()..color = const ui.Color(0xFF174C3A));
  }

  final ui.Image image = await recorder.endRecording().toImage(width, height);
  final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) {
    throw StateError('Could not build store demo image');
  }
  return bytes.buffer.asUint8List();
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
    widthPixels: 1200,
    heightPixels: 800,
  );

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => _size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: photoBytes, size: _size);
  }
}
