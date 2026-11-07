// lib/widgets/render_texto_fiesta.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missale_mozarabicum/models/texto.dart';
import 'package:missale_mozarabicum/services/control_estilos.dart';
import 'package:missale_mozarabicum/services/tipo_texto_style.dart';
import 'package:missale_mozarabicum/services/tipos_texto.dart';
import 'build_texto_widgets.dart';

// Constante para el espaciado mínimo entre textos
const double _minVerticalSpacing = 8.0;

Widget renderTextoFiesta({
  required BuildContext context,
  required WidgetRef ref,
  required Texto texto,
  required int index,
  required List<Texto> textos,
  required String languageCode,
}) {
  final tipo = texto.tipoPara(languageCode);
  final TipoTextoStyle cfg = ControlEstilos.estiloPorTipo(
    context,
    ref,
    TipoTexto.values[tipo - 1],
  );

  final rawText = texto.getTextForLanguage(languageCode);
  final text = cfg.uppercase ? rawText.toUpperCase() : rawText;

  final siguiente = index + 1 < textos.length ? textos[index + 1] : null;
  final tipoActual = tipo;
  final tipoSiguiente = siguiente?.tipoPara(languageCode);

  final casoEspecial = (tipoActual == 4 && tipoSiguiente == 5) ||
      (tipoActual == 5 && tipoSiguiente == 4);

  // Tipo 1: Normal
  if (tipo == 1) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      ),
      child: buildTextoConCruces(text, cfg, context: context),
    );
  }
  // Tipo 3: Semirrubrica
  else if (tipo == 3) {
    final cfg3 = cfg.copyWith(
      style: cfg.style.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black
      ),
      highlightUntilPattern: RegExp(r'[.:;]'),
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFF6B6B)
          : const Color(0xFFB00020),
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      ),
      child: buildTextoConEstilo(text, cfg3, context: context),
    );
  }
  // Tipos 4, 5, 8: Rúbricas centradas y título
  else if (tipo == 4 || tipo == 5 || tipo == 8) {
    return Padding(
      padding: casoEspecial
          ? const EdgeInsets.only(
          top: 25,
          bottom: _minVerticalSpacing,
          left: 16,
          right: 16
      )
          : const EdgeInsets.only(
          top: 25,
          bottom: 25,
          left: 16,
          right: 16
      ),
      child: Text(text, style: cfg.style, textAlign: cfg.align),
    );
  }
  // Resto de tipos (2, 6, 7)
  else {
    return Padding(
      padding: tipo == 7
          ? const EdgeInsets.only(
        left: 30,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      )
          : EdgeInsets.only(
        left: 16,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      ),
      child: Text(text, style: cfg.style, textAlign: cfg.align),
    );
  }
}