import 'dart:convert';
import 'dart:io';

import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';

Future<void> main() async {
  const CalibrationPdfRenderer renderer = CalibrationPdfRenderer();
  final CalibrationPdfResult result = await renderer.render(PaperSize.a4);
  final Directory outputDirectory = Directory('build/evidence');
  await outputDirectory.create(recursive: true);

  final File pdfFile = File('${outputDirectory.path}/calibration-a4-50mm.pdf');
  await pdfFile.writeAsBytes(result.document.bytes, flush: true);

  final Map<String, Object> geometry = <String, Object>{
    'paper': PaperSize.a4.id,
    'pageWidthMillimetres': PaperSize.a4.width.inMillimetres,
    'pageHeightMillimetres': PaperSize.a4.height.inMillimetres,
    'square': <String, double>{
      'leftMillimetres': _pointsToMillimetres(result.square.leftPoints),
      'topMillimetres': _pointsToMillimetres(result.square.topPoints),
      'widthMillimetres': _pointsToMillimetres(result.square.widthPoints),
      'heightMillimetres': _pointsToMillimetres(result.square.heightPoints),
    },
  };
  final File geometryFile = File(
    '${outputDirectory.path}/calibration-a4-50mm.geometry.json',
  );
  await geometryFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(geometry) + '\n',
    flush: true,
  );

  stdout.writeln(pdfFile.path);
  stdout.writeln(geometryFile.path);
}

double _pointsToMillimetres(double points) {
  return points *
      PhysicalLength.millimetresPerInch /
      PhysicalLength.pdfPointsPerInch;
}
