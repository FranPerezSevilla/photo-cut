import 'dart:typed_data';

import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/platform/pdf/pdf_render_result.dart';

/// App-owned PDF boundary used by final document creation and test fakes.
abstract interface class SheetPdfRenderer {
  Future<PdfRenderResult> render({
    required SheetPlan plan,
    required Uint8List imageBytes,
    bool showCutMarks = false,
  });
}
