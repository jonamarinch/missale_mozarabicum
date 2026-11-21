// Registro dominical de la parroquia: asistentes, comulgantes, fondos recibidos y gastos.
//
// Son datos privados: van en colecciones propias de Firestore (`registro_dominical` y
// `registro_config`) que solo pueden leer y escribir las cuentas con el permiso `registro`
// (reglas en config/firestore.rules del importador). Nunca se mezclan con los textos.
//
// Los importes se guardan en céntimos (enteros) para que las sumas sean exactas.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _coleccion = 'registro_dominical';
const _config = 'registro_config';
const _docCaja = 'caja';

/// Datos de un domingo. El ID del documento es la fecha: 'aaaa-mm-dd'.
class RegistroDomingo {
  final DateTime fecha;
  final int? asistentes;
  final int? comulgantes;
  final int recibidoCent;
  final int gastosCent;

  /// Corrección opcional para cuadrar con la caja real (positiva o negativa)
  final int ajusteCent;

  const RegistroDomingo({
    required this.fecha,
    this.asistentes,
    this.comulgantes,
    this.recibidoCent = 0,
    this.gastosCent = 0,
    this.ajusteCent = 0,
  });

  /// Lo que cambia la caja este domingo
  int get movimientoCent => recibidoCent - gastosCent + ajusteCent;

  factory RegistroDomingo.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return RegistroDomingo(
      fecha: fechaDeId(doc.id),
      asistentes: (d['asistentes'] as num?)?.toInt(),
      comulgantes: (d['comulgantes'] as num?)?.toInt(),
      recibidoCent: (d['recibido_cent'] as num?)?.toInt() ?? 0,
      gastosCent: (d['gastos_cent'] as num?)?.toInt() ?? 0,
      ajusteCent: (d['ajuste_cent'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> aMapa() => {
        'asistentes': asistentes,
        'comulgantes': comulgantes,
        'recibido_cent': recibidoCent,
        'gastos_cent': gastosCent,
        'ajuste_cent': ajusteCent,
        'actualizado': FieldValue.serverTimestamp(),
        'actualizado_por': FirebaseAuth.instance.currentUser?.email,
      };
}

/// Saldo de la caja antes del primer domingo apuntado
class CajaInicial {
  final int saldoCent;
  const CajaInicial(this.saldoCent);
}

String idDeFecha(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

DateTime fechaDeId(String id) {
  final p = id.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// Todos los domingos de un año civil
List<DateTime> domingosDelAnio(int anio) {
  var d = DateTime(anio, 1, 1);
  while (d.weekday != DateTime.sunday) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  final lista = <DateTime>[];
  while (d.year == anio) {
    lista.add(d);
    d = DateTime(d.year, d.month, d.day + 7);
  }
  return lista;
}

class RegistroService {
  final _db = FirebaseFirestore.instance;

  /// Todos los domingos apuntados, de cualquier año (son pocos: unos 52 al año)
  Stream<List<RegistroDomingo>> domingos() => _db
      .collection(_coleccion)
      .snapshots()
      .map((s) => s.docs.map(RegistroDomingo.desdeDoc).toList()..sort((a, b) => a.fecha.compareTo(b.fecha)));

  Stream<CajaInicial> cajaInicial() => _db
      .collection(_config)
      .doc(_docCaja)
      .snapshots()
      .map((s) => CajaInicial((s.data()?['saldo_inicial_cent'] as num?)?.toInt() ?? 0));

  Future<void> guardar(RegistroDomingo r) => _db.collection(_coleccion).doc(idDeFecha(r.fecha)).set(r.aMapa());

  Future<void> borrar(DateTime fecha) => _db.collection(_coleccion).doc(idDeFecha(fecha)).delete();

  Future<void> guardarCajaInicial(int saldoCent) => _db.collection(_config).doc(_docCaja).set({
        'saldo_inicial_cent': saldoCent,
        'actualizado': FieldValue.serverTimestamp(),
        'actualizado_por': FirebaseAuth.instance.currentUser?.email,
      });
}

/// Fondos que había al terminar cada domingo apuntado: saldo inicial más todos los
/// movimientos hasta ese domingo inclusive. Se recalcula entero cada vez, así que
/// cambiar un domingo antiguo corrige los fondos de todos los posteriores.
Map<String, int> fondosPorDomingo(List<RegistroDomingo> domingos, int saldoInicialCent) {
  final res = <String, int>{};
  var saldo = saldoInicialCent;
  for (final r in domingos) {
    saldo += r.movimientoCent;
    res[idDeFecha(r.fecha)] = saldo;
  }
  return res;
}

/// Fondos en una fecha cualquiera (aunque ese domingo no esté apuntado)
int fondosEnFecha(List<RegistroDomingo> domingos, int saldoInicialCent, DateTime fecha) {
  var saldo = saldoInicialCent;
  for (final r in domingos) {
    if (r.fecha.isAfter(fecha)) break;
    saldo += r.movimientoCent;
  }
  return saldo;
}

/// Convierte lo escrito («12,50», «1.200», «12.5», «-3») a céntimos. null si no es válido.
int? centimosDeTexto(String texto) {
  var t = texto.trim().replaceAll('€', '').replaceAll(' ', '');
  if (t.isEmpty) return 0;
  final negativo = t.startsWith('-');
  if (negativo) t = t.substring(1);
  // La coma es el decimal; un punto seguido de exactamente 3 cifras es separador de miles
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    t = t.replaceAll('.', '');
  }
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(t)) return null;
  final partes = t.split('.');
  final euros = int.parse(partes[0]);
  final cent = partes.length > 1 ? int.parse(partes[1].padRight(2, '0')) : 0;
  final total = euros * 100 + cent;
  return negativo ? -total : total;
}
