import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/print_job/configuration_help.dart';

void main() {
  test('every configuration topic has complete offline help', () {
    for (final ConfigurationHelpTopic topic in ConfigurationHelpTopic.values) {
      final ConfigurationHelpContent content = configurationHelpFor(topic);
      expect(content.title.trim(), isNotEmpty, reason: topic.name);
      expect(content.whatItDoes.trim(), isNotEmpty, reason: topic.name);
      expect(content.whenToUse.trim(), isNotEmpty, reason: topic.name);
      expect(content.example.trim(), isNotEmpty, reason: topic.name);
      expect(content.documentImpact.trim(), isNotEmpty, reason: topic.name);
    }
  });

  testWidgets('help button opens a self-contained explanation sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfigurationHelpButton(
            topic: ConfigurationHelpTopic.margin,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('help-margin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('configuration-help-sheet')), findsOneWidget);
    expect(find.text('Margen'), findsOneWidget);
    expect(find.text('Qué hace'), findsOneWidget);
    expect(find.text('Cuándo usarlo'), findsOneWidget);
    expect(find.text('Ejemplo'), findsOneWidget);
    expect(find.text('En el documento'), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);
  });
}
