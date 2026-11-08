import 'package:flutter/material.dart';
import 'package:missale_mozarabicum/services/tipo_texto_style.dart';

/// Marcas de formato dentro del texto: <r>rojo</>, <k>negro</>, <b>negrita</>,
/// <n>sin negrita</>, <i>cursiva</>. Se pueden combinar: <rn>(♦) </>por mi culpa.
final RegExp _marca = RegExp(r'<([rkbni]+)>(.*?)</>', dotAll: true);

/// Símbolos que siempre se dibujan en rojo y los que se reducen a la mitad
final RegExp _simbolos = RegExp('[✠♦]');

/// Elemento de lista del Word: la viñeta indica el nivel (● primero, ○ segundo, ■ tercero)
final RegExp _elementoLista = RegExp(r'^((?:<[rkbni]+>)?)([●○■]) ');
const _vinetas = ['●', '○', '■'];

/// Construye el texto aplicando las marcas de formato sobre el estilo de su tipo.
/// Si lleva líneas con viñeta, las dibuja con sangría francesa como en el Word.
Widget buildTextoMarcado(
  String raw,
  TipoTextoStyle cfg, {
  required BuildContext context,
  bool recortarArriba = false,
  bool recortarAbajo = false,
}) {
  final lineas = _partirLineas(raw);
  if (!lineas.any(_elementoLista.hasMatch)) {
    return _textoMarcado(raw, cfg,
        context: context, recortarArriba: recortarArriba, recortarAbajo: recortarAbajo);
  }

  // Sangrías del Word: la viñeta de cada nivel va donde empieza el texto del nivel anterior
  final paso = (cfg.style.fontSize ?? 16) * 1.5;
  final hijos = <Widget>[];
  final normales = <String>[];
  void cerrarNormales() {
    if (normales.isEmpty) return;
    hijos.add(_textoMarcado(normales.join('\n'), cfg, context: context));
    normales.clear();
  }

  for (final linea in lineas) {
    final m = _elementoLista.firstMatch(linea);
    if (m == null) {
      normales.add(linea);
      continue;
    }
    cerrarNormales();
    final nivel = _vinetas.indexOf(m.group(2)!);
    final apertura = m.group(1)!;
    final resto = apertura + linea.substring(m.end);
    hijos.add(Padding(
      padding: EdgeInsets.only(left: paso * 2 * nivel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: paso,
            child: _textoMarcado(
              apertura.isEmpty ? m.group(2)! : '$apertura${m.group(2)!}</>',
              cfg, context: context,
            ),
          ),
          Expanded(
            child: _textoMarcado(
              apertura.isNotEmpty && resto == apertura ? '' : _cerrarSiAbierta(resto),
              cfg, context: context,
            ),
          ),
        ],
      ),
    ));
  }
  cerrarNormales();
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: hijos);
}

/// Parte el texto en líneas, cerrando y reabriendo las marcas que pasan de una línea a otra
List<String> _partirLineas(String raw) {
  final salida = <String>[];
  String? abierta;
  for (var linea in raw.split('\n')) {
    if (abierta != null) linea = '<$abierta>$linea';
    abierta = null;
    final ultimaApertura = RegExp(r'<([rkbni]+)>').allMatches(linea).lastOrNull;
    final ultimoCierre = linea.lastIndexOf('</>');
    if (ultimaApertura != null && ultimaApertura.start > ultimoCierre) {
      abierta = ultimaApertura.group(1);
      linea = '$linea</>';
    }
    salida.add(linea);
  }
  return salida;
}

/// Una marca abierta sin cerrar se cierra al final de la línea
String _cerrarSiAbierta(String linea) {
  final ultimaApertura = RegExp(r'<([rkbni]+)>').allMatches(linea).lastOrNull;
  if (ultimaApertura != null && ultimaApertura.start > linea.lastIndexOf('</>')) return '$linea</>';
  return linea;
}

Widget _textoMarcado(
  String raw,
  TipoTextoStyle cfg, {
  required BuildContext context,
  bool recortarArriba = false,
  bool recortarAbajo = false,
}) {
  // Para pegar una línea a otra se ajusta la altura a la letra y se quita el espacio sobrante
  final compacto = recortarArriba || recortarAbajo;
  if (compacto) {
    cfg = cfg.copyWith(style: cfg.style.copyWith(height: 1.0));
  }
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

  return Text.rich(
    TextSpan(children: spans),
    textAlign: cfg.align,
    textHeightBehavior: compacto
        ? TextHeightBehavior(
            applyHeightToFirstAscent: !recortarArriba,
            applyHeightToLastDescent: !recortarAbajo,
          )
        : null,
  );
}
