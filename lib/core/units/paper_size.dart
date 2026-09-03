import 'package:photo_cut/core/units/physical_length.dart';

/// A named paper preset with exact physical dimensions in portrait orientation.
final class PaperSize {
  PaperSize._({
    required this.id,
    required this.width,
    required this.height,
  });

  static final PaperSize a4 = PaperSize._(
    id: 'a4',
    width: PhysicalLength.millimetres(210),
    height: PhysicalLength.millimetres(297),
  );

  static final PaperSize usLetter = PaperSize._(
    id: 'us-letter',
    width: PhysicalLength.inches(8.5),
    height: PhysicalLength.inches(11),
  );

  static final PaperSize photo10x15 = PaperSize._(
    id: 'photo-10x15',
    width: PhysicalLength.centimetres(10),
    height: PhysicalLength.centimetres(15),
  );

  static final List<PaperSize> presets = List<PaperSize>.unmodifiable(
    <PaperSize>[a4, usLetter, photo10x15],
  );

  final String id;
  final PhysicalLength width;
  final PhysicalLength height;

  static PaperSize byId(String id) {
    for (final paperSize in presets) {
      if (paperSize.id == id) {
        return paperSize;
      }
    }

    throw ArgumentError.value(id, 'id', 'Unknown paper-size preset');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaperSize &&
            other.id == id &&
            other.width == width &&
            other.height == height;
  }

  @override
  int get hashCode => Object.hash(id, width, height);

  @override
  String toString() {
    return 'PaperSize($id, '
        '${width.inMillimetres}mm x ${height.inMillimetres}mm)';
  }
}
