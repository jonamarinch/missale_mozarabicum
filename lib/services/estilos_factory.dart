// lib/services/estilos_factory.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:missale_mozarabicum/services/app_text_styles.dart';
import 'package:missale_mozarabicum/services/tipos_texto.dart';
import 'package:missale_mozarabicum/services/tipo_texto_style.dart';

/// Construye los estilos de texto de la app adaptándose al tema actual
AppTextStyles buildAppTextStyles(
    TextTheme base, {
      bool isDarkMode = false,
      bool useSystemFont = false,
      double textScale = 1.0,
    }) {
  // Función para aplicar fuente según configuración
  TextStyle f(TextStyle s) {
    if (useSystemFont) {
      return s.copyWith(fontSize: (s.fontSize ?? 16) * textScale);
    } else {
      return GoogleFonts.cardo(
        textStyle: s.copyWith(fontSize: (s.fontSize ?? 16) * textScale),
      );
    }
  }

  // Colores que se adaptan al tema
  final primaryRed = isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFB00020);
  final textColor = isDarkMode ? Colors.white : Colors.black87;
  // Violeta litúrgico para las indicaciones de postura del pueblo
  final violeta = isDarkMode ? const Color(0xFFC9A3E6) : const Color(0xFF6A2C91);

  return AppTextStyles({
    TipoTexto.normal: TipoTextoStyle(
      style: f(base.bodyLarge ?? const TextStyle(fontSize: 17)).copyWith(
        color: textColor,
      ),
    ),
    TipoTexto.rubrica: TipoTextoStyle(
      style: f(base.bodyLarge ?? const TextStyle(fontSize: 17)).copyWith(
        color: primaryRed,
        fontStyle: FontStyle.italic,
      ),
    ),
    TipoTexto.semirrubrica: TipoTextoStyle(
      style: f(base.bodyLarge ?? const TextStyle(fontSize: 17)).copyWith(
        color: primaryRed,
      ),
    ),
    TipoTexto.rubricaCentrada: TipoTextoStyle(
      style: f(base.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
        color: primaryRed,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
    ),
    TipoTexto.rubricaCentradaNegritaMayusculas: TipoTextoStyle(
      style: f(base.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(
        color: primaryRed,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
      align: TextAlign.center,
      uppercase: true,
    ),
    TipoTexto.pueblo: TipoTextoStyle(
      style: f(base.bodyLarge ?? const TextStyle(fontSize: 15)).copyWith(
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    ),
    TipoTexto.coro: TipoTextoStyle(
      style: f(base.bodyLarge ?? const TextStyle(fontSize: 15)).copyWith(
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    ),
    TipoTexto.titulo: TipoTextoStyle(
      style: f(base.headlineSmall ?? const TextStyle(fontSize: 22)).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textColor,
      ),
      align: TextAlign.center,
    ),
    TipoTexto.indicacionPueblo: TipoTextoStyle(
      style: f(base.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(
        color: violeta,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
      align: TextAlign.center,
      uppercase: true,
    ),
  });
}

/// Provider que construye los estilos con la configuración actual
/// Debe ser usado en lugar de buildAppTextStylesAuto
AppTextStyles buildAppTextStylesWithSettings(
    BuildContext context, {
      required bool useSystemFont,
      required double textScale,
    }) {
  final brightness = Theme.of(context).brightness;
  final textTheme = Theme.of(context).textTheme;
  return buildAppTextStyles(
    textTheme,
    isDarkMode: brightness == Brightness.dark,
    useSystemFont: useSystemFont,
    textScale: textScale,
  );
}