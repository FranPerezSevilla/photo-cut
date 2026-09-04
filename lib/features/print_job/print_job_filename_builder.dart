import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';

/// Builds stable, share-safe PDF filenames from immutable print settings.
final class PrintJobFilenameBuilder {
  const PrintJobFilenameBuilder();

  String build(PrintJobConfiguration configuration) {
    final String stem = _safeStem(configuration.image.displayName);
    final String width = _formatMillimetres(
      configuration.photoWidth.inMillimetres,
    );
    final String height = _formatMillimetres(
      configuration.photoHeight.inMillimetres,
    );
    final String colour = configuration.colorMode == ImageColorMode.grayscale
        ? 'bn'
        : 'color';

    return 'photo-cut-$stem-${width}x${height}mm-'
        '${configuration.copyCount}copias-'
        '${configuration.paperSize.id}-$colour.pdf';
  }

  static String _safeStem(String filename) {
    final int extensionIndex = filename.lastIndexOf('.');
    final String rawStem = extensionIndex > 0
        ? filename.substring(0, extensionIndex)
        : filename;
    String value = _foldSpanish(rawStem.toLowerCase());
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    value = value.replaceAll(RegExp(r'^-+|-+$'), '');
    if (value.length > 32) {
      value = value.substring(0, 32).replaceAll(RegExp(r'-+$'), '');
    }
    return value.isEmpty ? 'foto' : value;
  }

  static String _foldSpanish(String value) {
    const Map<String, String> replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    String result = value;
    for (final MapEntry<String, String> replacement in replacements.entries) {
      result = result.replaceAll(replacement.key, replacement.value);
    }
    return result;
  }

  static String _formatMillimetres(double value) {
    String text = value.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text.replaceAll('.', '_');
  }
}
