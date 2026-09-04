import 'package:photo_cut/core/units/physical_length.dart';

/// Units exposed by the Photo Cut configuration form.
enum LengthUnit {
  millimetres,
  centimetres,
  inches;

  String get label {
    return switch (this) {
      LengthUnit.millimetres => 'Milímetros',
      LengthUnit.centimetres => 'Centímetros',
      LengthUnit.inches => 'Pulgadas',
    };
  }

  String get shortLabel {
    return switch (this) {
      LengthUnit.millimetres => 'mm',
      LengthUnit.centimetres => 'cm',
      LengthUnit.inches => 'in',
    };
  }

  PhysicalLength toPhysicalLength(num value) {
    return switch (this) {
      LengthUnit.millimetres => PhysicalLength.millimetres(value),
      LengthUnit.centimetres => PhysicalLength.centimetres(value),
      LengthUnit.inches => PhysicalLength.inches(value),
    };
  }

  double fromPhysicalLength(PhysicalLength value) {
    return switch (this) {
      LengthUnit.millimetres => value.inMillimetres,
      LengthUnit.centimetres => value.inCentimetres,
      LengthUnit.inches => value.inInches,
    };
  }
}
