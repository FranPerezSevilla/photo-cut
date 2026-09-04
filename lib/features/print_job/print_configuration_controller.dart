import 'package:flutter/foundation.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_configuration_state.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

/// Owns validation and canonical physical values for the preparation screen.
final class PrintConfigurationController extends ChangeNotifier {
  factory PrintConfigurationController({
    required SelectedImage image,
    SheetLayoutEngine layoutEngine = const SheetLayoutEngine(),
    CropPlanner cropPlanner = const CropPlanner(),
    ImageProcessor imageProcessor = const DartImageProcessor(),
  }) {
    return PrintConfigurationController._(
      layoutEngine: layoutEngine,
      cropPlanner: cropPlanner,
      imageProcessor: imageProcessor,
      initialState: _initialState(image, layoutEngine),
    );
  }

  PrintConfigurationController._({
    required this._layoutEngine,
    required this._cropPlanner,
    required this._imageProcessor,
    required PrintConfigurationState initialState,
  }) : _state = initialState;

  final CropPlanner _cropPlanner;
  final ImageProcessor _imageProcessor;
  final SheetLayoutEngine _layoutEngine;
  bool _disposed = false;
  bool _inspectionAttempted = false;
  PrintConfigurationState _state;

  PrintConfigurationState get state => _state;

  Future<void> inspectImage() async {
    if (_inspectionAttempted || _disposed) {
      return;
    }
    _inspectionAttempted = true;
    _replace(_state.copyWith(isInspectingImage: true, imageError: null));

    try {
      final SourceImageSize sourceSize = await _imageProcessor.inspect(
        _state.configuration.image.bytes,
      );
      if (_disposed) {
        return;
      }
      _replaceWithPlanAndCrop(
        _state.copyWith(
          configuration: _state.configuration.copyWith(sourceSize: sourceSize),
          isInspectingImage: false,
          imageError: null,
        ),
      );
    } on Object {
      if (_disposed) {
        return;
      }
      _replace(
        _state.copyWith(
          isInspectingImage: false,
          imageError:
              'No se pudo leer la orientación o el tamaño de esta foto.',
        ),
      );
    }
  }

  void changeWidth(String input) {
    final _ParsedLength parsed = _parseLength(input, _state.unit);
    if (parsed.length == null) {
      _replace(_state.copyWith(widthInput: input, widthError: parsed.error));
      return;
    }
    _replaceWithPlanAndCrop(
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
    _replaceWithPlanAndCrop(
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
    _replaceWithPlanAndCrop(
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
    _replaceWithPlanAndCrop(
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
    _replaceWithPlanAndCrop(
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
    _replaceWithPlanAndCrop(
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
    _replaceWithPlanAndCrop(
      _state.copyWith(
        configuration: _state.configuration.copyWith(paperSize: paperSize),
      ),
    );
  }

  void changeFitMode(ImageFitMode mode) {
    _replaceWithPlanAndCrop(
      _state.copyWith(
        configuration: _state.configuration.copyWith(fitMode: mode),
      ),
    );
  }

  void changeColorMode(ImageColorMode mode) {
    _replace(
      _state.copyWith(
        configuration: _state.configuration.copyWith(colorMode: mode),
      ),
    );
  }

  void changeFocusX(double value) {
    _changeFocus(_state.configuration.focus.copyWith(x: value));
  }

  void changeFocusY(double value) {
    _changeFocus(_state.configuration.focus.copyWith(y: value));
  }

  void changeCutMarks(bool value) {
    _replace(
      _state.copyWith(
        configuration: _state.configuration.copyWith(showCutMarks: value),
      ),
    );
  }

  void _changeFocus(NormalizedPoint focus) {
    _replaceWithPlanAndCrop(
      _state.copyWith(
        configuration: _state.configuration.copyWith(focus: focus),
      ),
    );
  }

  void _replaceWithPlanAndCrop(PrintConfigurationState next) {
    PrintJobConfiguration configuration = next.configuration;
    final SourceImageSize? sourceSize = configuration.sourceSize;
    if (sourceSize != null) {
      final NormalizedCropRect cropRect =
          configuration.fitMode == ImageFitMode.fitInside
          ? NormalizedCropRect.full
          : _cropPlanner.plan(
              sourceSize: sourceSize,
              targetAspectRatio: configuration.photoAspectRatio,
              focus: configuration.focus,
            );
      configuration = configuration.copyWith(cropRect: cropRect);
    }

    try {
      final SheetPlan plan = _layoutEngine.createPlan(_specFor(configuration));
      _replace(
        next.copyWith(
          configuration: configuration,
          previewPlan: plan,
          layoutError: null,
        ),
      );
    } on StateError {
      _replace(
        next.copyWith(
          configuration: configuration,
          previewPlan: null,
          layoutError:
              'La foto no cabe en el papel con estas medidas y márgenes.',
        ),
      );
    }
  }

  void _replace(PrintConfigurationState value) {
    if (_disposed) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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
      fitMode: ImageFitMode.cropToFill,
      colorMode: ImageColorMode.color,
      focus: NormalizedPoint.center,
      cropRect: NormalizedCropRect.full,
      sourceSize: null,
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
      isInspectingImage: true,
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
