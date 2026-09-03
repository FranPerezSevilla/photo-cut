/// A strictly positive physical distance stored canonically in millimetres.
///
/// Constructors encode the source unit in their name so callers never pass an
/// ambiguous numeric length across a domain boundary.
final class PhysicalLength implements Comparable<PhysicalLength> {
  PhysicalLength._(this._millimetres);

  factory PhysicalLength.millimetres(num value) {
    return PhysicalLength._(
      _validatedMillimetres(value, unitName: 'millimetres'),
    );
  }

  factory PhysicalLength.centimetres(num value) {
    final centimetres = _validatedValue(value, unitName: 'centimetres');
    return PhysicalLength._(centimetres * millimetresPerCentimetre);
  }

  factory PhysicalLength.inches(num value) {
    final inches = _validatedValue(value, unitName: 'inches');
    return PhysicalLength._(inches * millimetresPerInch);
  }

  factory PhysicalLength.pdfPoints(num value) {
    final points = _validatedValue(value, unitName: 'PDF points');
    return PhysicalLength._(
      points * millimetresPerInch / pdfPointsPerInch,
    );
  }

  static const double millimetresPerCentimetre = 10;
  static const double millimetresPerInch = 25.4;
  static const double pdfPointsPerInch = 72;

  final double _millimetres;

  double get inMillimetres => _millimetres;

  double get inCentimetres => _millimetres / millimetresPerCentimetre;

  double get inInches => _millimetres / millimetresPerInch;

  double get inPdfPoints => inInches * pdfPointsPerInch;

  @override
  int compareTo(PhysicalLength other) {
    return _millimetres.compareTo(other._millimetres);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PhysicalLength && other._millimetres == _millimetres;
  }

  @override
  int get hashCode => _millimetres.hashCode;

  @override
  String toString() => 'PhysicalLength(${_millimetres}mm)';

  static double _validatedMillimetres(
    num value, {
    required String unitName,
  }) {
    return _validatedValue(value, unitName: unitName);
  }

  static double _validatedValue(
    num value, {
    required String unitName,
  }) {
    final convertedValue = value.toDouble();
    if (!convertedValue.isFinite || convertedValue <= 0) {
      throw ArgumentError.value(
        value,
        unitName,
        'Physical length must be finite and greater than zero',
      );
    }
    return convertedValue;
  }
}
