// Informes del registro dominical en PDF, mensuales o anuales (21/11/2026).
// Usa la fuente Cardo de la app, que tiene «€» y los acentos.
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:missale_mozarabicum/services/registro_service.dart';

final _euros = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);
String _e(int cent) => _euros.format(cent / 100);

String _media(Iterable<int?> valores) {
  final v = valores.whereType<int>().toList();
  return v.isEmpty ? '—' : (v.reduce((a, b) => a + b) / v.length).toStringAsFixed(0);
}

int _suma(Iterable<int?> valores) => valores.whereType<int>().fold(0, (a, b) => a + b);

/// Periodo del informe: un mes (`mes` de 1 a 12) o un año entero (`mes` null)
class PeriodoInforme {
  final int anio;
  final int? mes;
  const PeriodoInforme(this.anio, [this.mes]);

  DateTime get inicio => DateTime(anio, mes ?? 1, 1);
  DateTime get fin => mes == null ? DateTime(anio, 12, 31) : DateTime(anio, mes! + 1, 0);

  String get nombre {
    if (mes == null) return 'Año $anio';
    final m = DateFormat('MMMM', 'es').format(inicio);
    return '${m[0].toUpperCase()}${m.substring(1)} de $anio';
  }

  String get archivo => mes == null ? 'registro_$anio.pdf' : 'registro_${anio}_${mes.toString().padLeft(2, '0')}.pdf';
}

Future<Uint8List> informePdf({
  required PeriodoInforme periodo,
  required List<RegistroDomingo> todos,
  required int saldoInicialCent,
  String? Function(DateTime)? nombreDomingo,
}) async {
  final normal = pw.Font.ttf(await rootBundle.load('assets/fonts/Cardo-Regular.ttf'));
  final negrita = pw.Font.ttf(await rootBundle.load('assets/fonts/Cardo-Bold.ttf'));
  final tema = pw.ThemeData.withFont(base: normal, bold: negrita);

  final delPeriodo =
      todos.where((r) => !r.fecha.isBefore(periodo.inicio) && !r.fecha.isAfter(periodo.fin)).toList();
  final fondosAntes = fondosEnFecha(todos, saldoInicialCent, periodo.inicio.subtract(const Duration(days: 1)));
  final fondosDespues = fondosEnFecha(todos, saldoInicialCent, periodo.fin);
  final recibido = _suma(delPeriodo.map((r) => r.recibidoCent));
  final gastos = _suma(delPeriodo.map((r) => r.gastosCent));
  final ajustes = _suma(delPeriodo.map((r) => r.ajusteCent));
  final hayAjustes = delPeriodo.any((r) => r.ajusteCent != 0);

  const gris = PdfColor.fromInt(0xFFEFEAE6);
  final estiloCabecera = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
  const estiloCelda = pw.TextStyle(fontSize: 9);

  pw.Widget tabla(List<String> cabecera, List<List<String>> filas, {List<String>? total}) => pw.TableHelper.fromTextArray(
        headers: cabecera,
        data: [...filas, if (total != null) total],
        headerStyle: estiloCabecera,
        cellStyle: estiloCelda,
        headerDecoration: const pw.BoxDecoration(color: gris),
        cellAlignment: pw.Alignment.centerRight,
        cellAlignments: {0: pw.Alignment.centerLeft},
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      );

  pw.Widget dato(String etiqueta, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(etiqueta)),
          pw.Text(valor, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ]),
      );

  // Detalle por domingo
  var saldo = fondosAntes;
  final filasDomingos = <List<String>>[];
  for (final r in delPeriodo) {
    saldo += r.movimientoCent;
    final nombre = nombreDomingo?.call(r.fecha);
    filasDomingos.add([
      DateFormat('d MMM', 'es').format(r.fecha) + (nombre == null ? '' : '\n$nombre'),
      r.asistentes?.toString() ?? '—',
      r.comulgantes?.toString() ?? '—',
      _e(r.recibidoCent),
      _e(r.gastosCent),
      if (hayAjustes) r.ajusteCent == 0 ? '' : _e(r.ajusteCent),
      _e(saldo),
    ]);
  }

  // En el informe anual, además, un resumen mes a mes
  final filasMeses = <List<String>>[];
  if (periodo.mes == null) {
    for (var m = 1; m <= 12; m++) {
      final pm = PeriodoInforme(periodo.anio, m);
      final delMes = delPeriodo.where((r) => r.fecha.month == m).toList();
      if (delMes.isEmpty) continue;
      filasMeses.add([
        pm.nombre.split(' ').first,
        '${delMes.length}',
        _media(delMes.map((r) => r.asistentes)),
        _media(delMes.map((r) => r.comulgantes)),
        _e(_suma(delMes.map((r) => r.recibidoCent))),
        _e(_suma(delMes.map((r) => r.gastosCent))),
        _e(fondosEnFecha(todos, saldoInicialCent, pm.fin)),
      ]);
    }
  }

  final doc = pw.Document(title: 'Registro dominical · ${periodo.nombre}', author: 'Missale Mozarabicum');
  doc.addPage(pw.MultiPage(
    theme: tema,
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    header: (c) => c.pageNumber == 1
        ? pw.SizedBox()
        : pw.Text('Registro dominical · ${periodo.nombre}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
    footer: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Generado el ${DateFormat("d 'de' MMMM 'de' y", 'es').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.Text('Página ${c.pageNumber} de ${c.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ]),
    build: (c) => [
      pw.Text('Registro dominical', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.Text(periodo.nombre, style: const pw.TextStyle(fontSize: 15)),
      pw.SizedBox(height: 14),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
        child: pw.Column(children: [
          dato('Domingos apuntados', '${delPeriodo.length}'),
          dato('Asistentes (total · media por domingo)',
              '${_suma(delPeriodo.map((r) => r.asistentes))} · ${_media(delPeriodo.map((r) => r.asistentes))}'),
          dato('Comulgantes (total · media por domingo)',
              '${_suma(delPeriodo.map((r) => r.comulgantes))} · ${_media(delPeriodo.map((r) => r.comulgantes))}'),
          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
          dato('Fondos al empezar', _e(fondosAntes)),
          dato('Fondos recibidos', '+ ${_e(recibido)}'),
          dato('Gastos', '− ${_e(gastos)}'),
          if (hayAjustes) dato('Ajustes de caja', _e(ajustes)),
          dato('Fondos al terminar', _e(fondosDespues)),
        ]),
      ),
      if (filasMeses.isNotEmpty) ...[
        pw.SizedBox(height: 16),
        pw.Text('Mes a mes', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        tabla(['Mes', 'Domingos', 'Media asist.', 'Media comulg.', 'Recibido', 'Gastos', 'Fondos a fin de mes'], filasMeses),
      ],
      pw.SizedBox(height: 16),
      pw.Text('Domingo a domingo', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      if (filasDomingos.isEmpty)
        pw.Text('No hay domingos apuntados en este periodo.')
      else
        tabla(
          ['Domingo', 'Asistentes', 'Comulgantes', 'Recibido', 'Gastos', if (hayAjustes) 'Ajuste', 'Fondos'],
          filasDomingos,
          total: [
            'Total',
            '${_suma(delPeriodo.map((r) => r.asistentes))}',
            '${_suma(delPeriodo.map((r) => r.comulgantes))}',
            _e(recibido),
            _e(gastos),
            if (hayAjustes) _e(ajustes),
            _e(fondosDespues),
          ],
        ),
    ],
  ));
  return doc.save();
}
