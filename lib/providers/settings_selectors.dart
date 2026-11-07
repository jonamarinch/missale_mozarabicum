// lib/providers/settings_selectors.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missale_mozarabicum/models/app_settings.dart';

/// Locale actual (derivada de settingsProvider)
final localeProvider = Provider<Locale>((ref) {
  final async = ref.watch(settingsProvider);
  return async.maybeWhen(
    data: (s) => s.locale,
    orElse: () => const Locale('es', 'ES'),
  );
});

/// Edición actual (derivada de settingsProvider)
final edicionProvider = Provider<String>((ref) {
  final async = ref.watch(settingsProvider);
  return async.maybeWhen(
    data: (s) => s.edicion,
    orElse: () => edicionAdaptada,
  );
});

/// Theme mode actual (derivado de settingsProvider)
final themeModeProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(settingsProvider);
  return async.maybeWhen(
    data: (s) => s.themeMode,
    orElse: () => ThemeMode.system,
  );
});