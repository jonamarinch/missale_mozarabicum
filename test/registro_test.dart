import 'package:flutter_test/flutter_test.dart';
import 'package:missale_mozarabicum/services/registro_service.dart';

void main() {
  test('importes escritos a céntimos', () {
    expect(centimosDeTexto('12,50'), 1250);
    expect(centimosDeTexto('12.5'), 1250);
    expect(centimosDeTexto('1.200'), 120000);
    expect(centimosDeTexto('1.200,30 €'), 120030);
    expect(centimosDeTexto('-5'), -500);
    expect(centimosDeTexto(''), 0);
    expect(centimosDeTexto('abc'), null);
    expect(centimosDeTexto('1,234'), null);
  });

  test('los fondos se recalculan al cambiar un domingo antiguo', () {
    final d = [
      RegistroDomingo(fecha: DateTime(2026, 11, 15), recibidoCent: 10000, gastosCent: 2000),
      RegistroDomingo(fecha: DateTime(2026, 11, 22), recibidoCent: 5000, gastosCent: 1000, ajusteCent: -500),
    ];
    final f = fondosPorDomingo(d, 100000);
    expect(f['2026-11-15'], 108000);
    expect(f['2026-11-22'], 111500);
    expect(fondosEnFecha(d, 100000, DateTime(2026, 11, 18)), 108000);
    expect(fondosEnFecha(d, 100000, DateTime(2026, 11, 1)), 100000);
  });

  test('domingos del año', () {
    final l = domingosDelAnio(2026);
    expect(l.first, DateTime(2026, 1, 4));
    expect(l.length, 52);
    expect(l.every((x) => x.weekday == DateTime.sunday), true);
  });
}
