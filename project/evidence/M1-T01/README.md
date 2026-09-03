# M1-T01 evidence

Task: model exact physical lengths and paper sizes.

The implementation is intentionally pure Dart. Evidence is provided by:

- `lib/core/units/physical_length.dart`
- `lib/core/units/paper_size.dart`
- `lib/core/units/units.dart`
- `test/core/units/physical_length_test.dart`
- `test/core/units/paper_size_test.dart`

The tests verify explicit constructors for millimetres, centimetres, inches and
PDF points; exact A4, US Letter and 10 x 15 cm dimensions; round-trip conversion
tolerance; and rejection of invalid, zero, non-finite and negative lengths.

No physical printer result is claimed by this task. The final pull-request head
must pass the complete Android and iOS CI workflow before merge.
