import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui; // ⬅️ importante para detectar idioma del sistema

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ediciones del Misal
const String edicionOriginal = 'original';
const String edicionAdaptada = 'adaptada';

/// Idiomas disponibles por ahora: el inglés volverá cuando estén traducidos los textos.
Locale _idiomaDisponible(String? languageCode, String? countryCode) {
  if (languageCode == 'la') return const Locale('la', 'VA');
  return const Locale('es', 'ES');
}

/// -------- Modelo inmutable --------
@immutable
class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final double textScale;
  final bool useSystemFont;
  final String edicion;

  const AppSettings({
    this.locale = const Locale('es', 'ES'),
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.useSystemFont = false,
    this.edicion = edicionAdaptada,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    double? textScale,
    bool? useSystemFont,
    String? edicion,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      useSystemFont: useSystemFont ?? this.useSystemFont,
      edicion: edicion ?? this.edicion,
    );
  }

  Map<String, dynamic> toMap() => {
    'locale': {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
    },
    'themeMode': themeMode.index,
    'textScale': textScale,
    'useSystemFont': useSystemFont,
    'edicion': edicion,
  };

  factory AppSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AppSettings();
    final loc = (map['locale'] as Map?)?.cast<String, dynamic>();
    return AppSettings(
      locale: _idiomaDisponible(loc?['languageCode'] as String?, loc?['countryCode'] as String?),
      themeMode: ThemeMode
          .values[(map['themeMode'] as num?)?.toInt() ?? ThemeMode.system.index],
      textScale: (map['textScale'] as num?)?.toDouble() ?? 1.0,
      useSystemFont: map['useSystemFont'] as bool? ?? true,
      edicion: map['edicion'] == edicionOriginal ? edicionOriginal : edicionAdaptada,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AppSettings.fromJson(String? source) =>
      AppSettings.fromMap(source == null
          ? null
          : jsonDecode(source) as Map<String, dynamic>);
}

/// -------- Persistencia + Provider --------
const _kPrefsKey = 'app_settings_v1';

final settingsProvider =
AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late SharedPreferences _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_kPrefsKey);
    final stored = AppSettings.fromJson(raw);

    // Si no hay nada guardado, elegimos el idioma del sistema como inicial.
    if (raw == null) {
      final systemLocale = _systemLocaleOrFallback();
      final initial = stored.copyWith(locale: systemLocale);
      // opcional: persiste inmediatamente para que quede fijado
      unawaited(_persist(initial));
      return initial;
    }

    return stored;
  }

  /// Empieza en español, salvo que el sistema esté en latín.
  Locale _systemLocaleOrFallback() {
    final ui.Locale sys = ui.PlatformDispatcher.instance.locales.isNotEmpty
        ? ui.PlatformDispatcher.instance.locales.first
        : ui.PlatformDispatcher.instance.locale;
    return _idiomaDisponible(sys.languageCode.toLowerCase(), sys.countryCode);
  }

  Future<void> _persist(AppSettings s) async {
    await _prefs.setString(_kPrefsKey, s.toJson());
  }

  Future<void> _update(FutureOr<AppSettings> Function(AppSettings) recipe) async {
    final current = state.value ?? const AppSettings();
    final next = await recipe(current);
    state = AsyncData(next);
    unawaited(_persist(next));
  }

  // ---- Mutadores públicos ----
  Future<void> setLocale(Locale locale) =>
      _update((s) => s.copyWith(locale: locale));

  Future<void> setEdicion(String edicion) =>
      _update((s) => s.copyWith(edicion: edicion));

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setTextScale(double scale) =>
      _update((s) => s.copyWith(textScale: scale.clamp(0.8, 1.6)));

  Future<void> setUseSystemFont(bool value) =>
      _update((s) => s.copyWith(useSystemFont: value));

  Future<void> reset() async {
    state = const AsyncData(AppSettings());
    unawaited(_prefs.remove(_kPrefsKey));
  }

  // Para compatibilidad con settings_dialog.dart
  Future<void> resetToDefaults() => reset();
}