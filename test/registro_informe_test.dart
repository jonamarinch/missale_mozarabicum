import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:missale_mozarabicum/services/registro_informe.dart';
import 'package:missale_mozarabicum/services/registro_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('es'));

  final d = [
    RegistroDomingo(fecha: DateTime(2026, 10, 25), asistentes: 40, comulgantes: 30, recibidoCent: 12050, gastosCent: 3000),
    RegistroDomingo(fecha: DateTime(2026, 11, 15), asistentes: 52, comulgantes: 41, recibidoCent: 10000, gastosCent: 2000, ajusteCent: -500),
    RegistroDomingo(fecha: DateTime(2026, 11, 22), asistentes: 48, recibidoCent: 8000),
  ];

  test('periodos', () {
    expect(const PeriodoInforme(2026, 11).nombre, 'Noviembre de 2026');
    expect(const PeriodoInforme(2026, 2).fin, DateTime(2026, 2, 28));
    expect(const PeriodoInforme(2026).nombre, 'Año 2026');
  });

  test('informe mensual y anual en PDF', () async {
    for (final p in [const PeriodoInforme(2026, 11), const PeriodoInforme(2026), const PeriodoInforme(2025, 3)]) {
      final pdf = await informePdf(periodo: p, todos: d, saldoInicialCent: 100000);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      expect(pdf.length, greaterThan(1000));
    }
  });
}
