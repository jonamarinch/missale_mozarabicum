import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missale_mozarabicum/models/app_settings.dart';

/// Ventana modal para configurar la aplicación
class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? const AppSettings();
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final tinta = Theme.of(context).colorScheme.onSurface;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: oscuro ? const Color(0xFF2E2826) : const Color(0xFFf9efee),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: tinta,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cardo',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            // Contenido
            Flexible(
              child: ColoredBox(
                color: oscuro ? const Color(0xFF221E1C) : const Color(0xFFfff8f7),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.menu_book,
                        title: 'Edición',
                      ),
                      const SizedBox(height: 12),
                      _EditionSelector(
                        currentEdition: settings.edicion,
                        onChanged: settingsNotifier.setEdicion,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: Icons.language,
                        title: 'Idioma',
                      ),
                      const SizedBox(height: 12),
                      _LanguageSelector(
                        currentLocale: settings.locale,
                        onChanged: settingsNotifier.setLocale,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: Icons.palette,
                        title: 'Apariencia',
                      ),
                      const SizedBox(height: 12),
                      _ThemeSelector(
                        currentTheme: settings.themeMode,
                        onChanged: settingsNotifier.setThemeMode,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: Icons.text_fields,
                        title: 'Texto',
                      ),
                      const SizedBox(height: 12),
                      _TextScaleSlider(
                        currentScale: settings.textScale,
                        onChanged: settingsNotifier.setTextScale,
                      ),
                      const SizedBox(height: 16),
                      _SystemFontSwitch(
                        useSystemFont: settings.useSystemFont,
                        onChanged: settingsNotifier.setUseSystemFont,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await settingsNotifier.resetToDefaults();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Configuración restablecida'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Restablecer valores por defecto'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para encabezados de sección
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cardo',
          ),
        ),
      ],
    );
  }
}

/// Selector de edición
class _EditionSelector extends StatelessWidget {
  final String currentEdition;
  final Function(String) onChanged;

  const _EditionSelector({
    required this.currentEdition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const ediciones = [
      {'id': edicionOriginal, 'nombre': 'Original', 'detalle': 'Texto latino original'},
      {'id': edicionIcae, 'nombre': 'ICAE', 'detalle': 'Edición de la parroquia, en latín y español'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: ediciones.map((edicion) {
          final id = edicion['id']!;
          final isSelected = currentEdition == id;

          return ListTile(
            leading: Radio<String>(
              value: id,
              groupValue: currentEdition,
              onChanged: (value) => value != null ? onChanged(value) : null,
              activeColor: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              edicion['nombre']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(edicion['detalle']!, style: const TextStyle(fontSize: 12)),
            onTap: () => onChanged(id),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

/// Selector de idioma
class _LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) onChanged;

  const _LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'code': 'es_ES', 'name': 'Español', 'locale': const Locale('es', 'ES')},
      {'code': 'la_VA', 'name': 'Latinum', 'locale': const Locale('la', 'VA')},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: languages.map((lang) {
          final locale = lang['locale'] as Locale;
          final isSelected = currentLocale == locale;

          return ListTile(
            leading: Radio<Locale>(
              value: locale,
              groupValue: currentLocale,
              onChanged: (value) => value != null ? onChanged(value) : null,
              activeColor: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              lang['name'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () => onChanged(locale),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

/// Selector de tema
class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onChanged;

  const _ThemeSelector({
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      {'mode': ThemeMode.system, 'name': 'Seguir sistema', 'icon': Icons.settings_system_daydream},
      {'mode': ThemeMode.light, 'name': 'Modo claro', 'icon': Icons.light_mode},
      {'mode': ThemeMode.dark, 'name': 'Modo oscuro', 'icon': Icons.dark_mode},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: themes.map((theme) {
          final mode = theme['mode'] as ThemeMode;
          final isSelected = currentTheme == mode;

          return ListTile(
            leading: Radio<ThemeMode>(
              value: mode,
              groupValue: currentTheme,
              onChanged: (value) => value != null ? onChanged(value) : null,
              activeColor: Theme.of(context).colorScheme.onSurface,
            ),
            title: Row(
              children: [
                Icon(
                  theme['icon'] as IconData,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  theme['name'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            onTap: () => onChanged(mode),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

/// Slider para escala de texto
class _TextScaleSlider extends StatelessWidget {
  final double currentScale;
  final Function(double) onChanged;

  const _TextScaleSlider({
    required this.currentScale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tamaño del texto'),
              Text(
                '${(currentScale * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.onSurface,
              thumbColor: Theme.of(context).colorScheme.onSurface,
              inactiveTrackColor: Colors.grey[300],
            ),
            child: Slider(
              value: currentScale,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pequeño', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Grande', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

/// Switch para usar fuente del sistema
class _SystemFontSwitch extends StatelessWidget {
  final bool useSystemFont;
  final Function(bool) onChanged;

  const _SystemFontSwitch({
    required this.useSystemFont,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.font_download,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usar fuente del sistema',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Utiliza la fuente predeterminada del dispositivo',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: useSystemFont,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}