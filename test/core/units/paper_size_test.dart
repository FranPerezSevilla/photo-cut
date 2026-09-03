import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/paper_size.dart';

void main() {
  group('PaperSize', () {
    test('exposes exact A4 dimensions', () {
      expect(PaperSize.a4.width.inMillimetres, closeTo(210, 0.0000001));
      expect(PaperSize.a4.height.inMillimetres, closeTo(297, 0.0000001));
    });

    test('exposes exact US Letter dimensions', () {
      expect(PaperSize.usLetter.width.inInches, closeTo(8.5, 0.0000001));
      expect(PaperSize.usLetter.height.inInches, closeTo(11, 0.0000001));
      expect(PaperSize.usLetter.width.inMillimetres, closeTo(215.9, 0.0000001));
      expect(
        PaperSize.usLetter.height.inMillimetres,
        closeTo(279.4, 0.0000001),
      );
    });

    test('exposes exact 10 x 15 centimetre dimensions', () {
      expect(PaperSize.photo10x15.width.inCentimetres, closeTo(10, 0.0000001));
      expect(PaperSize.photo10x15.height.inCentimetres, closeTo(15, 0.0000001));
    });

    test('lists stable presets and resolves them by ID', () {
      expect(PaperSize.presets.map((paperSize) => paperSize.id), <String>[
        'a4',
        'us-letter',
        'photo-10x15',
      ]);
      expect(PaperSize.byId('a4'), same(PaperSize.a4));
      expect(PaperSize.byId('us-letter'), same(PaperSize.usLetter));
      expect(PaperSize.byId('photo-10x15'), same(PaperSize.photo10x15));
    });

    test('rejects an unknown preset ID', () {
      expect(() => PaperSize.byId('unknown'), throwsArgumentError);
    });

    test('does not expose a mutable preset collection', () {
      expect(() => PaperSize.presets.add(PaperSize.a4), throwsUnsupportedError);
    });
  });
}
