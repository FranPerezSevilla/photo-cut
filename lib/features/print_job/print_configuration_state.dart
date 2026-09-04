import 'package:flutter/foundation.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';

const Object _keepConfigurationValue = Object();

/// Immutable presentation state for the app-owned preparation step.
@immutable
final class PrintConfigurationState {
  const PrintConfigurationState({
    required this.configuration,
    required this.unit,
    required this.widthInput,
    required this.heightInput,
    required this.copyCountInput,
    required this.marginInput,
    required this.gapInput,
    required this.previewPlan,
    this.widthError,
    this.heightError,
    this.copyCountError,
    this.marginError,
    this.gapError,
    this.layoutError,
  });

  final PrintJobConfiguration configuration;
  final String copyCountInput;
  final String? copyCountError;
  final String gapInput;
  final String? gapError;
  final String heightInput;
  final String? heightError;
  final String? layoutError;
  final String marginInput;
  final String? marginError;
  final SheetPlan? previewPlan;
  final LengthUnit unit;
  final String widthInput;
  final String? widthError;

  bool get canReview {
    return widthError == null &&
        heightError == null &&
        copyCountError == null &&
        marginError == null &&
        gapError == null &&
        layoutError == null &&
        previewPlan != null;
  }

  PrintConfigurationState copyWith({
    PrintJobConfiguration? configuration,
    LengthUnit? unit,
    String? widthInput,
    String? heightInput,
    String? copyCountInput,
    String? marginInput,
    String? gapInput,
    Object? previewPlan = _keepConfigurationValue,
    Object? widthError = _keepConfigurationValue,
    Object? heightError = _keepConfigurationValue,
    Object? copyCountError = _keepConfigurationValue,
    Object? marginError = _keepConfigurationValue,
    Object? gapError = _keepConfigurationValue,
    Object? layoutError = _keepConfigurationValue,
  }) {
    return PrintConfigurationState(
      configuration: configuration ?? this.configuration,
      unit: unit ?? this.unit,
      widthInput: widthInput ?? this.widthInput,
      heightInput: heightInput ?? this.heightInput,
      copyCountInput: copyCountInput ?? this.copyCountInput,
      marginInput: marginInput ?? this.marginInput,
      gapInput: gapInput ?? this.gapInput,
      previewPlan: identical(previewPlan, _keepConfigurationValue)
          ? this.previewPlan
          : previewPlan as SheetPlan?,
      widthError: identical(widthError, _keepConfigurationValue)
          ? this.widthError
          : widthError as String?,
      heightError: identical(heightError, _keepConfigurationValue)
          ? this.heightError
          : heightError as String?,
      copyCountError: identical(copyCountError, _keepConfigurationValue)
          ? this.copyCountError
          : copyCountError as String?,
      marginError: identical(marginError, _keepConfigurationValue)
          ? this.marginError
          : marginError as String?,
      gapError: identical(gapError, _keepConfigurationValue)
          ? this.gapError
          : gapError as String?,
      layoutError: identical(layoutError, _keepConfigurationValue)
          ? this.layoutError
          : layoutError as String?,
    );
  }
}
