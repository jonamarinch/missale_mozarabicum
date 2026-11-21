import 'package:cloud_firestore/cloud_firestore.dart';

/// Fiestas cargadas y revisadas en Firestore. Las demás de Adviento se pueden abrir desde el
/// calendario, pero la Misa avisa de que aún solo tiene los textos comunes.
const List<String> fiestasCargadas = ['adv1', 'adv2', 'adv3', 'adv4', 'adv5', 'adv6', 'nav1'];

// Modelo de datos para representar una fiesta litúrgica
class Fiesta {
  /// Código identificador único de la fiesta (ej: 'cua1', 'pas3', etc.)
  final String codigo;
  /// Nombre de la fiesta en español
  final String nombre_es;
  /// Nombre de la fiesta en inglés
  final String nombre_en;
  /// Nombre de la fiesta en latín
  final String nombre_la;
  /// Tiempo litúrgico al que pertenece (ej: 'cua', 'adv')
  final String tiempo;
  /// Constructor de la clase Fiesta
  Fiesta({
    required this.codigo,
    required this.nombre_es,
    required this.nombre_en,
    required this.nombre_la,
    required this.tiempo,
  });
  /// Método para obtener el nombre según el idioma
  String getNombreForLanguage(String languageCode) {
    switch (languageCode) {
      case 'es':
        return nombre_es;
      case 'en':
        return nombre_en;
      case 'la':
        return nombre_la;
      default:
        return nombre_es; // Por defecto español
    }
  }
  /// Fábrica para crear una Fiesta a partir de un documento de Firestore
  factory Fiesta.fromFirestore(String id, Map<String, dynamic> data) {
    return Fiesta(
      codigo: id,
      nombre_es: data['nom_es'] ?? '',
      nombre_en: data['nom_en'] ?? '',
      nombre_la: data['nom_la'] ?? '',
      tiempo: data['tiempo'] ?? '',
    );
  }
  /// Convierte el objeto Fiesta en un mapa JSON (para guardar en caché)
  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre_es': nombre_es,
    'nombre_en': nombre_en,
    'nombre_la': nombre_la,
    'tiempo': tiempo,
  };
  /// Crea una Fiesta a partir de un mapa JSON (al leer de caché local)
  factory Fiesta.fromJson(Map<String, dynamic> json) {
    return Fiesta(
      codigo: json['codigo'],
      nombre_es: json['nombre_es'] ?? '',
      nombre_en: json['nombre_en'] ?? '',
      nombre_la: json['nombre_la'] ?? '',
      tiempo: json['tiempo'],
    );
  }
}

// --- Nueva función para obtener una fiesta por código ---
Future<Fiesta?> getFiesta(String? codigo) async {
  if (codigo == null || codigo.isEmpty) return null;

  final db = FirebaseFirestore.instance;
  // Ajusta el nombre de la colección si en tu proyecto es otro
  final doc = await db.collection('fiestas').doc(codigo).get();

  if (!doc.exists) return null;
  final data = doc.data() as Map<String, dynamic>;
  return Fiesta.fromFirestore(doc.id, data);
}