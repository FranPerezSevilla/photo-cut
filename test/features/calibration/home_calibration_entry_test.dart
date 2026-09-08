import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('home keeps print scale test secondary and available before purchase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          imagePickerGateway: _CancelledImagePickerGateway(),
          calibrationBuilder: (BuildContext context) {
            return const Scaffold(
              body: Center(child: Text('Print scale test route open')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elegir foto'), findsOneWidget);
    expect(find.text('Prueba de escala de impresión'), findsNothing);
    expect(find.byKey(const Key('more-actions')), findsOneWidget);

    await tester.tap(find.byKey(const Key('more-actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-calibration')), findsOneWidget);
    expect(find.text('Prueba de escala de impresión'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-calibration')));
    await tester.pumpAndSettle();

    expect(find.text('Print scale test route open'), findsOneWidget);
  });
}

final class _CancelledImagePickerGateway implements ImagePickerGateway {
  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    return const ImageSelectionCancelled();
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    return const ImageSelectionCancelled();
  }
}
