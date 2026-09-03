import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';

Future<void> main() async {
  final SheetPlan plan = const SheetLayoutEngine().createPlan(
    SheetLayoutSpec(
      paperSize: PaperSize.a4,
      photoWidth: PhysicalLength.millimetres(35),
      photoHeight: PhysicalLength.millimetres(45),
      copyCount: 8,
      margin: PhysicalLength.millimetres(8),
      gap: PhysicalLength.millimetres(2),
    ),
  );
  final Uint8List imageBytes = base64Decode(
    File('test_resources/synthetic-35x45.png.base64').readAsStringSync().trim(),
  );
  final PdfRenderResult result = await const ExactSizePdfRenderer().render(
    plan: plan,
    imageBytes: imageBytes,
  );

  final Directory evidenceDirectory = Directory('build/evidence');
  await evidenceDirectory.create(recursive: true);
  final File pdfFile = File('${evidenceDirectory.path}/sample-35x45-a4.pdf');
  final File geometryFile = File(
    '${evidenceDirectory.path}/sample-35x45-a4.geometry.json',
  );

  await pdfFile.writeAsBytes(result.bytes, flush: true);
  await geometryFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(result.geometryToJson())}\n',
    flush: true,
  );

  stdout.writeln(
    'Generated ${pdfFile.path}: ${result.pages.length} page, '
    '${result.pages.single.photoBoxes.length} photo boxes, '
    '${result.bytes.length} bytes.',
  );
  stdout.writeln('Geometry: ${geometryFile.path}');
}
