import 'package:flutter/material.dart';

enum ConfigurationHelpTopic {
  fitMode,
  framing,
  colorMode,
  width,
  height,
  unit,
  paper,
  copies,
  margin,
  gap,
  cutMarks,
}

final class ConfigurationHelpContent {
  const ConfigurationHelpContent({
    required this.title,
    required this.whatItDoes,
    required this.whenToUse,
    required this.example,
    required this.documentImpact,
  });

  final String documentImpact;
  final String example;
  final String title;
  final String whatItDoes;
  final String whenToUse;
}

const Map<ConfigurationHelpTopic, ConfigurationHelpContent>
_configurationHelp = <ConfigurationHelpTopic, ConfigurationHelpContent>{
  ConfigurationHelpTopic.fitMode: ConfigurationHelpContent(
    title: 'Rellenar o encajar',
    whatItDoes:
        'Decide cómo entra la foto dentro del tamaño físico que has elegido.',
    whenToUse:
        'Usa Rellenar si quieres ocupar toda la foto impresa. Usa Encajar si prefieres conservar la imagen completa.',
    example:
        'Una foto panorámica en 35 × 45 mm: Rellenar recorta los lados; Encajar mantiene todo y puede dejar bordes blancos.',
    documentImpact: 'Cambia el contenido del PDF, pero no el tamaño físico elegido.',
  ),
  ConfigurationHelpTopic.framing: ConfigurationHelpContent(
    title: 'Encuadre',
    whatItDoes:
        'Elige qué zona de la imagen se conserva cuando Rellenar necesita recortar.',
    whenToUse:
        'Ajústalo si una cara, un objeto o una parte importante queda demasiado cerca del borde o fuera de la foto.',
    example:
        'Si la persona está a la derecha, mueve el encuadre hacia la derecha para conservarla dentro del recorte.',
    documentImpact: 'Cambia qué píxeles aparecen en el PDF.',
  ),
  ConfigurationHelpTopic.colorMode: ConfigurationHelpContent(
    title: 'Color o blanco y negro',
    whatItDoes:
        'Decide si Photo Cut mantiene los colores originales o convierte la imagen a escala de grises.',
    whenToUse:
        'Elige blanco y negro cuando quieras que el propio PDF quede ya preparado sin depender de la impresora.',
    example:
        'Seleccionar Blanco y negro hace que la vista previa y el PDF final se generen en grises.',
    documentImpact: 'Cambia los píxeles del PDF antes de abrir la impresión del sistema.',
  ),
  ConfigurationHelpTopic.width: ConfigurationHelpContent(
    title: 'Ancho de la foto',
    whatItDoes: 'Define la anchura física final de cada copia impresa.',
    whenToUse: 'Introduce la medida que necesitas realmente sobre el papel.',
    example: 'Para una foto de 35 × 45 mm, el ancho es 35 mm.',
    documentImpact: 'Cambia el tamaño físico de cada copia en el PDF.',
  ),
  ConfigurationHelpTopic.height: ConfigurationHelpContent(
    title: 'Alto de la foto',
    whatItDoes: 'Define la altura física final de cada copia impresa.',
    whenToUse: 'Introduce la medida que necesitas realmente sobre el papel.',
    example: 'Para una foto de 35 × 45 mm, el alto es 45 mm.',
    documentImpact: 'Cambia el tamaño físico de cada copia en el PDF.',
  ),
  ConfigurationHelpTopic.unit: ConfigurationHelpContent(
    title: 'Unidad de medida',
    whatItDoes: 'Cambia cómo introduces y ves ancho, alto, margen y separación.',
    whenToUse: 'Elige mm, cm o pulgadas según las medidas que tengas a mano.',
    example: '35 mm y 3,5 cm representan exactamente el mismo ancho.',
    documentImpact:
        'No cambia el tamaño por sí sola: Photo Cut conserva la misma medida física al cambiar de unidad.',
  ),
  ConfigurationHelpTopic.paper: ConfigurationHelpContent(
    title: 'Tamaño del papel',
    whatItDoes: 'Define el tamaño de la hoja del PDF donde se colocan las copias.',
    whenToUse: 'Debe coincidir con el papel que vas a cargar en la impresora.',
    example: 'Si imprimes sobre una hoja A4 normal, selecciona A4.',
    documentImpact: 'Cambia el tamaño de página y la distribución del PDF.',
  ),
  ConfigurationHelpTopic.copies: ConfigurationHelpContent(
    title: 'Número de copias',
    whatItDoes: 'Indica cuántas veces se repetirá la misma fotografía.',
    whenToUse: 'Pon el total de copias que quieres obtener, aunque ocupen varias páginas.',
    example: '40 copias pueden generar más de una página automáticamente.',
    documentImpact: 'Cambia cuántas copias y páginas contiene el PDF.',
  ),
  ConfigurationHelpTopic.margin: ConfigurationHelpContent(
    title: 'Margen',
    whatItDoes: 'Reserva una distancia mínima entre las copias y el borde del papel.',
    whenToUse:
        'Normalmente puedes dejar el valor por defecto. Auméntalo si tu impresora no puede imprimir cerca de los bordes.',
    example: '8 mm mantiene las fotos alejadas del borde exterior de la hoja.',
    documentImpact: 'Puede cambiar cuántas copias caben en cada página.',
  ),
  ConfigurationHelpTopic.gap: ConfigurationHelpContent(
    title: 'Separación',
    whatItDoes: 'Deja espacio entre una copia y la siguiente.',
    whenToUse:
        'Normalmente puedes dejar el valor por defecto. Auméntalo si quieres más espacio para cortar.',
    example: '2 mm deja una pequeña franja entre dos fotos contiguas.',
    documentImpact: 'Puede cambiar la distribución y el número de páginas.',
  ),
  ConfigurationHelpTopic.cutMarks: ConfigurationHelpContent(
    title: 'Marcas de corte',
    whatItDoes: 'Añade guías finas alrededor de cada copia para facilitar el recorte.',
    whenToUse: 'Actívalas si vas a cortar las fotos manualmente después de imprimir.',
    example: 'Las líneas indican por dónde cortar sin cambiar los 35 × 45 mm de la foto.',
    documentImpact: 'Añade guías al PDF sin cambiar el tamaño exterior de cada copia.',
  ),
};

ConfigurationHelpContent configurationHelpFor(ConfigurationHelpTopic topic) {
  return _configurationHelp[topic]!;
}

final class ConfigurationHelpButton extends StatelessWidget {
  const ConfigurationHelpButton({
    super.key,
    required this.topic,
    this.buttonKey,
  });

  final Key? buttonKey;
  final ConfigurationHelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final ConfigurationHelpContent content = configurationHelpFor(topic);
    return IconButton(
      key: buttonKey ?? ValueKey<String>('help-${topic.name}'),
      icon: const Icon(Icons.help_outline, size: 20),
      tooltip: 'Ayuda: ${content.title}',
      visualDensity: VisualDensity.compact,
      onPressed: () => _showHelp(context, content),
    );
  }
}

Future<void> _showHelp(
  BuildContext context,
  ConfigurationHelpContent content,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            key: const Key('configuration-help-sheet'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(content.title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              _HelpSection(title: 'Qué hace', body: content.whatItDoes),
              _HelpSection(title: 'Cuándo usarlo', body: content.whenToUse),
              _HelpSection(title: 'Ejemplo', body: content.example),
              _HelpSection(title: 'En el documento', body: content.documentImpact),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

final class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String body;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 3),
          Text(body),
        ],
      ),
    );
  }
}
