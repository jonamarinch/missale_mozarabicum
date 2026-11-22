// Versión de mozarabic.web.app: probar con y sin `--dart-define=VARIANTE=mozarabic`
import 'package:flutter_test/flutter_test.dart';
import 'package:missale_mozarabicum/config/variante.dart';
import 'package:missale_mozarabicum/models/texto.dart';

Texto texto(Map<String, dynamic> extra) => Texto.fromFirestore({
      'orden': 2890, 'tipo': 2, 'txt_es': 'Rúbrica', 'txt_en': 'Rubric', 'txt_la': 'Hic',
      'ediciones': ['original', 'icae'], 'original_es': 'Aquí', ...extra,
    });

void main() {
  final variante = kVariante == 'mozarabic';
  final oculto = texto({'ocultar_en': ['mozarabic']});
  final sustituido = texto({
    'sustituir_en': {'mozarabic': {'txt_es': 'Dichas estas palabras', 'txt_en': 'Having said'}},
  });

  test('oculta el texto solo en la ICAE de la versión', () {
    expect(oculto.perteneceA('icae'), !variante);
    expect(oculto.perteneceA('original'), isTrue);
  });

  test('sustituye español e inglés en la ICAE; el latín y la original no cambian', () {
    expect(sustituido.textoPara('es', 'icae'), variante ? 'Dichas estas palabras' : 'Rúbrica');
    expect(sustituido.textoPara('en', 'icae'), variante ? 'Having said' : 'Rubric');
    expect(sustituido.textoPara('la', 'icae'), 'Hic');
    expect(sustituido.textoPara('es', 'original'), 'Aquí');
  });

  test('la copia local conserva las marcas', () {
    final copia = Texto.fromFirestore(sustituido.toJson());
    expect(copia.sustituirEn, sustituido.sustituirEn);
    expect(Texto.fromFirestore(oculto.toJson()).ocultarEn, ['mozarabic']);
  });
}
