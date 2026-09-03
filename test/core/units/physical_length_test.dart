import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/physical_length.dart';

void main() {
  group('PhysicalLength', () {
    test('converts centimetres to canonical millimetres', () {
      final length = PhysicalLength.centimetres(3.5);

      expect(length.inMillimetres, closeTo(35, 0.0000001));
    });

    test('converts inches to millimetres and PDF points', () {
      final length = PhysicalLength.inches(1);

      expect(length.inMillimetres, closeTo(25.4, 0.0000001));
      expect(length.inPdfPoints, closeTo(72, 0.0000001));
    });

    test('converts PDF points to millimetres', () {
      final length = PhysicalLength.pdfPoints(72);

      expect(length.inMillimetres, closeTo(25.4, 0.0000001));
      expect(length.inInches, closeTo(1, 0.0000001));
    });

    test('round-trips all supported units within 0.001 millimetres', () {
      final original = PhysicalLength.millimetres(123.456789);
      final reconstructed = <PhysicalLength>[
        PhysicalLength.millimetres(original.inMillimetres),
        PhysicalLength.centimetres(original.inCentimetres),
        PhysicalLength.inches(original.inInches),
        PhysicalLength.pdfPoints(original.inPdfPoints),
      ];

      for (final length in reconstructed) {
        expect(
          length.inMillimetres,
          closeTo(original.inMillimetres, 0.001),
        );
      }
    });

    for (final invalidValue in <double>[
      0,
      -1,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      test('rejects invalid value $invalidValue for every constructor', () {
        expect(
          () => PhysicalLength.millimetres(invalidValue),
          throwsArgumentError,
        );
        expect(
          () => PhysicalLength.centimetres(invalidValue),
          throwsArgumentError,
        );
        expect(
          () => PhysicalLength.inches(invalidValue),
          throwsArgumentError,
        );
        expect(
          () => PhysicalLength.pdfPoints(invalidValue),
          throwsArgumentError,
        );
      });
    }

    test('compares canonical physical lengths', () {
      final shorter = PhysicalLength.centimetres(1);
      final longer = PhysicalLength.millimetres(11);

      expect(shorter.compareTo(longer), lessThan(0));
      expect(longer.compareTo(shorter), greaterThan(0));
      expect(shorter.compareTo(PhysicalLength.millimetres(10)), 0);
    });
  });
}
