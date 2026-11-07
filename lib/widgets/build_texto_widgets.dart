import 'package:flutter/material.dart';
import 'package:missale_mozarabicum/services/tipo_texto_style.dart';

/// Marcas de formato dentro del texto: <r>rojo</>, <k>negro</>, <b>negrita</>,
/// <n>sin negrita</>, <i>cursiva</>. Se pueden combinar: <rn>(♦) </>por mi culpa.
final RegExp _marca = RegExp(r'<([rkbni]+)>(.*?)</>', dotAll: true);

/// Símbolos que siempre se dibujan en rojo y los que se reducen a la mitad
final RegExp _simbolos = RegExp('[✠♦]');

/// Construye el texto aplicando las marcas de formato sobre el estilo de su tipo
Widget buildTextoMarcado(String raw, TipoTextoStyle cfg, {required BuildContext context}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final rojo = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB00020);
  final negro = isDark ? Colors.white : Colors.black;

  final spans = <InlineSpan>[];

  void anadir(String texto, TextStyle estilo) {
    final visible = cfg.uppercase ? texto.toUpperCase() : texto;
    var inicio = 0;
    for (final m in _simbolos.allMatches(visible)) {
      if (m.start > inicio) {
        spans.add(TextSpan(text: visible.substring(inicio, m.start), style: estilo));
      }
      final simbolo = m.group(0)!;
      spans.add(TextSpan(
        // El selector U+FE0E evita que Android lo dibuje como emoji, con su propio color
        text: simbolo == '♦' ? '♦︎' : simbolo,
        style: simbolo == '♦'
            ? estilo.copyWith(color: rojo, fontSize: (estilo.fontSize ?? 16) * 0.5)
            : estilo.copyWith(color: rojo),
      ));
      inicio = m.end;
    }
    if (inicio < visible.length) {
      spans.add(TextSpan(text: visible.substring(inicio), style: estilo));
    }
  }

  TextStyle aplicar(String marcas) {
    var estilo = cfg.style;
    if (marcas.contains('r')) estilo = estilo.copyWith(color: rojo);
    if (marcas.contains('k')) estilo = estilo.copyWith(color: negro);
    if (marcas.contains('b')) estilo = estilo.copyWith(fontWeight: FontWeight.w700);
    if (marcas.contains('n')) estilo = estilo.copyWith(fontWeight: FontWeight.w400);
    if (marcas.contains('i')) estilo = estilo.copyWith(fontStyle: FontStyle.italic);
    return estilo;
  }

  var posicion = 0;
  for (final m in _marca.allMatches(raw)) {
    if (m.start > posicion) {
      anadir(raw.substring(posicion, m.start), cfg.style);
    }
    anadir(m.group(2)!, aplicar(m.group(1)!));
    posicion = m.end;
  }
  if (posicion < raw.length) {
    anadir(raw.substring(posicion), cfg.style);
  }

  return Text.rich(TextSpan(children: spans), textAlign: cfg.align);
}
