import 'package:flutter_test/flutter_test.dart';
import 'package:missale_mozarabicum/services/liturgical_calendar.dart';

void main() {
  test('domingos de Adviento de 2026', () {
    final d = LiturgicalCalendar.domingosAdviento(2026);
    // ignore: avoid_print
    print(d);
    expect(d[DateTime(2026, 11, 15)], 'adv1');
    expect(d[DateTime(2026, 12, 20)], 'adv6');
  });
}
