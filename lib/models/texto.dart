// Modelo de datos para representar un texto a imprimir
class Texto {
  final double orden;
  final bool ordinario;
  final int tipo;
  final String txt_es;
  final String txt_en;
  final String txt_la;
  final List<String> fiestas;
  final List<String> tiempos;
  /// Ediciones en las que aparece ('original', 'adaptada'). Vacía: en todas (el título).
  final List<String> ediciones;
  /// Tipo del latín, solo si difiere del tipo general
  final int? tipoLa;
  /// Fila de la tabla del Word: al cambiar de sección se deja un espacio
  final int? seccion;
  /// Traducción al español de la edición original
  final String originalEs;
  /// Líneas en blanco que hay antes del texto en el Word (español y latín)
  final int hueco;
  final int huecoLa;

  // Constructor con todos los campos requeridos para garantizar inmutabilidad.
  Texto({
    required this.orden,
    required this.ordinario,
    required this.tipo,
    required this.txt_es,
    required this.txt_en,
    required this.txt_la,
    required this.fiestas,
    required this.tiempos,
    this.ediciones = const [],
    this.tipoLa,
    this.seccion,
    this.originalEs = '',
    this.hueco = 0,
    this.huecoLa = 0,
  });

  // Constructor para títulos
  factory Texto.titulo(String textoEs, String textoEn, String textoLa, String codigo) {
    return Texto(
      orden: 0, // Orden de los títulos
      ordinario: false, // El título es un propio
      tipo: 8, // Tipo 'Título'
      txt_es: textoEs,
      txt_en: textoEn,
      txt_la: textoLa,
      fiestas: [codigo], // Asociado a la fiesta actual
      tiempos: [''],
    );
  }

  /// Texto que se muestra según idioma y edición. El español de la ICAE no se usa en la original.
  String textoPara(String languageCode, String edicion) {
    if (languageCode == 'la') return txt_la;
    // El título de la fiesta no tiene edición: vale para todas
    if (edicion == 'original' && ediciones.isNotEmpty) return languageCode == 'es' ? originalEs : '';
    return getTextForLanguage(languageCode);
  }

  /// Líneas en blanco antes del texto, según el idioma
  int huecoPara(String languageCode) => languageCode == 'la' ? huecoLa : hueco;

  /// Texto sin las marcas de formato, para buscar
  static String sinMarcas(String texto) => texto.replaceAll(RegExp(r'</?[rkbni]*>'), '');

  /// Indica si el texto se muestra en la edición indicada
  bool perteneceA(String edicion) => ediciones.isEmpty || ediciones.contains(edicion);

  /// Tipo con el que se muestra en cada idioma: el latín puede no llevar ℣ y tener otro formato
  int tipoPara(String languageCode) => languageCode == 'la' ? (tipoLa ?? tipo) : tipo;

  // Método para obtener el texto según el idioma
  String getTextForLanguage(String languageCode) {
    switch (languageCode) {
      case 'es':
        return txt_es;
      case 'en':
        return txt_en;
      case 'la':
        return txt_la;
      default:
        return txt_es; // Por defecto español
    }
  }

  /// Convierte el objeto Texto en un mapa JSON (para guardar en caché)
  Map<String, dynamic> toJson() => {
    'orden': orden,
    'ordinario': ordinario,
    'tipo': tipo,
    'txt_es': txt_es,
    'txt_en': txt_en,
    'txt_la': txt_la,
    'fiestas': fiestas,
    'tiempos': tiempos,
    'ediciones': ediciones,
    'tipo_la': tipoLa,
    'seccion': seccion,
    'original_es': originalEs,
    'hueco': hueco,
    'hueco_la': huecoLa,
  };

  // Fábrica para crear un Texto a partir de un documento de Firestore
  factory Texto.fromFirestore(Map<String, dynamic> data) {
    return Texto(
      orden: data['orden'].toDouble() ?? 0.0,
      ordinario: data['ordinario'] ?? true,
      tipo: data['tipo'] ?? 0,
      txt_es: data['txt_es'] ?? '',
      txt_en: data['txt_en'] ?? '',
      txt_la: data['txt_la'] ?? '',
      fiestas: List<String>.from(data['fiestas'] ?? []),
      tiempos: List<String>.from(data['tiempos'] ?? []),
      ediciones: List<String>.from(data['ediciones'] ?? []),
      tipoLa: data['tipo_la'] as int?,
      seccion: data['seccion'] as int?,
      originalEs: data['original_es'] ?? '',
      hueco: (data['hueco'] as num?)?.toInt() ?? 0,
      huecoLa: (data['hueco_la'] as num?)?.toInt() ?? 0,
    );
  }
}