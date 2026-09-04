import 'package:flutter/foundation.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_configuration_state.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

/// Owns validation and canonical physical values for the preparation screen.
final class PrintConfigurationController extends ChangeNotifier {
  PrintConfigurationController({
    required SelectedImage image,
    SheetLayoutEngine layoutEngine = const SheetLayoutEngine(),
  }) : _layoutEngine = layoutEngine,
       _state = _initialState(image, layoutEngine);

  final SheetLayoutEngine _layoutEngine;
  PrintConfigurationState _state;

  PrintConfigurationState get state => _state;

  void changeWidth(String input) {
    final _ParsedLength parsed = _parseLength(input, _state.unit);
    if (parsed.length == null) {
      _replace(_state.copyWith(widthInput: input, widthError: parsed.error));
      return;
    }
    _replaceWithPlan(
      _state.copyWith(
        configuration: _state.configuration.copyWith(photoWidth: parsed.length),
        widthInput: input,
        widthError: null,
      ),
    );
  }

  void changeHeight(String input) {
    final _ParsedLength parsed = _parseLength(input, _state.unit);
    if (parsed.length == null) {
      _replace(_state.copyWith(heightInput: input, heightError: parsed.error));
      return;
    }
    _replaceWithPlan(
      _state.copyWith(
        configuration: _state.configuration.copyWith(
          photoHeight: parsed.length,
        ),
        heightInput: input,
        heightError: null,
      ),
    );
  }

  void changeCopyCount(String input) {
    final int? parsed = int.tryParse(input.trim());
    if (parsed == null || parsed <= 0 || parsed > 999) {
      _replace(
        _state.copyWith(
          copyCountInput: input,
          copyCountError: 'Introduce un número entre 1 y 999.',
        ),
      );
      return;
    }
    _replaceWithPlan(
      _state.copyWith(
        configuration: _state.configuration.copyWith(copyCount: parsed),
        copyCountInput: input,
        copyCountError: null,
      ),
    );
  }

  void changeMargin(String input) {
    final _ParsedLength parsed = _parseLength(input, _state.unit);
    if (parsed.length == null) {
      _replace(_state.copyWith(marginInput: input, marginError: parsed.error));
      return;
    }
    _replaceWithPlan(
      _state.copyWith(
        configuration: _state.configuration.copyWith(margin: parsed.length),
        marginInput: input,
        marginError: null,
      ),
    );
  }

  void changeGap(String input) {
    final _ParsedLength parsed = _parseLength(input, _state.unit);
    if (parsed.length == null) {
      _replace(_state.copyWith(gapInput: input, gapError: parsed.error));
      return;
    }
    _replaceWithPlan(
      _state.copyWith(
        configuration: _state.configuration.copyWith(gap: parsed.length),
        gapInput: input,
        gapError: null,
      ),
    );
  }

  void changeUnit(LengthUnit unit) {
    if (unit == _state.unit) {
      return;
    }
    final PrintJobConfiguration configuration = _state.configuration;
    _replaceWithPlan(
      _state.copyWith(
        unit: unit,
        widthInput: _formatLength(configuration.photoWidth, unit),
        heightInput: _formatLength(configuration.photoHeight, unit),
        marginInput: _formatLength(configuration.margin, unit),
        gapInput: _formatLength(configuration.gap, unit),
        widthError: null,
        heightError: null,
        marginError: null,
        gapError: null,
      ),
    );
  }

  void changePaperSize(PaperSize paperSize) {
    _replaceWithPlan(
      _state.copyWith(
        configuration: _state.configuration.copyWith(paperSize: paperSize),
      ),
    );
  }

  void changeCutMarks(bool value) {
    _replace(
      _state.copyWith(
        configuration: _state.configuration.copyWith(showCutMarks: value),
      ),
    );
  }

  void _replaceWithPlan(PrintConfigurationState next) {
    try {
      final SheetPlan plan = _layoutEngine.createPlan(
        _specFor(next.configuration),
      );
      _replace(next.copyWith(previewPlan: plan, layoutError: null));
    } on StateError {
      _replace(
        next.copyWith(
          previewPlan: null,
          layoutError:
              'La foto no cabe en el papel con estas medidas y márgenes.',
        ),
      );
    }
  }

  void _replace(PrintConfigurationState value) {
    _state = value;
    notifyListeners();
  }

  static PrintConfigurationState _initialState(
    SelectedImage image,
    SheetLayoutEngine layoutEngine,
  ) {
    final PrintJobConfiguration configuration = PrintJobConfiguration(
      image: image,
      photoWidth: PhysicalLength.millimetres(35),
      photoHeight: PhysicalLength.millimetres(45),
      paperSize: PaperSize.a4,
      copyCount: 8,
      margin: PhysicalLength.millimetres(8),
      gap: PhysicalLength.millimetres(2),
      showCutMarks: true,
    );
    final SheetPlan plan = layoutEngine.createPlan(_specFor(configuration));
    return PrintConfigurationState(
      configuration: configuration,
      unit: LengthUnit.millimetres,
      widthInput: '35',
      heightInput: '45',
      copyCountInput: '8',
      marginInput: '8',
      gapInput: '2',
      previewPlan: plan,
    );
  }

  static SheetLayoutSpec _specFor(PrintJobConfiguration configuration) {
    return SheetLayoutSpec(
      paperSize: configuration.paperSize,
      photoWidth: configuration.photoWidth,
      photoHeight: configuration.photoHeight,
      copyCount: configuration.copyCount,
      margin: configuration.margin,
      gap: configuration.gap,
    );
  }

  static _ParsedLength _parseLength(String input, LengthUnit unit) {
    final String normalised = input.trim().replaceAll(',', '.');
    final double? value = double.tryParse(normalised);
    if (value == null || !value.isFinite || value <= 0) {
      return const _ParsedLength(error: 'Introduce una medida mayor que 0.');
    }
    return _ParsedLength(length: unit.toPhysicalLength(value));
  }

  static String _formatLength(PhysicalLength length, LengthUnit unit) {
    final double value = unit.fromPhysicalLength(length);
    String text = value.toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}

final class _ParsedLength {
  const _ParsedLength({this.length, this.error});

  final String? error;
  final PhysicalLength? length;
}
