import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/physical_length.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  group('PrintDocument', () {
    test('copies input bytes and exposes a display name', () {
      final Uint8List source = Uint8List.fromList(<int>[37, 80, 68, 70]);
      final PrintDocument document = _document(bytes: source);
      source[0] = 0;

      expect(document.bytes, <int>[37, 80, 68, 70]);
      expect(document.documentName, 'sample');
    });

    test('rejects empty bytes and unsafe filenames', () {
      expect(() => _document(bytes: Uint8List(0)), throwsArgumentError);
      expect(() => _document(filename: '../sample.pdf'), throwsArgumentError);
      expect(() => _document(filename: 'sample.txt'), throwsArgumentError);
    });
  });

  test('a fake gateway records print and share requests', () async {
    final PrintDocument document = _document();
    final _FakePrintGateway gateway = _FakePrintGateway();

    expect(await gateway.printPdf(document), isTrue);
    expect(await gateway.sharePdf(document), isTrue);
    expect(gateway.printed, same(document));
    expect(gateway.shared, same(document));
  });
}

PrintDocument _document({Uint8List? bytes, String filename = 'sample.pdf'}) {
  return PrintDocument(
    bytes: bytes ?? Uint8List.fromList(<int>[37, 80, 68, 70]),
    filename: filename,
    pageWidth: PhysicalLength.millimetres(210),
    pageHeight: PhysicalLength.millimetres(297),
  );
}

final class _FakePrintGateway implements PrintGateway {
  PrintDocument? printed;
  PrintDocument? shared;

  @override
  Future<bool> printPdf(PrintDocument document) async {
    printed = document;
    return true;
  }

  @override
  Future<bool> sharePdf(PrintDocument document) async {
    shared = document;
    return true;
  }
}
