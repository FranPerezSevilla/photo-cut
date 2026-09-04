import 'dart:typed_data';

import 'package:photo_cut/core/units/physical_length.dart';

/// In-memory PDF plus the physical page size needed by native print services.
final class PrintDocument {
  PrintDocument({
    required Uint8List bytes,
    required this.filename,
    required this.pageWidth,
    required this.pageHeight,
  }) : bytes = Uint8List.fromList(bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'PDF bytes must not be empty');
    }
    if (filename.trim() != filename ||
        filename.length <= 4 ||
        !filename.toLowerCase().endsWith('.pdf') ||
        filename.contains('/') ||
        filename.contains('\\')) {
      throw ArgumentError.value(
        filename,
        'filename',
        'Filename must be a plain non-empty PDF filename',
      );
    }
  }

  final Uint8List bytes;
  final String filename;
  final PhysicalLength pageHeight;
  final PhysicalLength pageWidth;

  String get documentName => filename.substring(0, filename.length - 4);
}
