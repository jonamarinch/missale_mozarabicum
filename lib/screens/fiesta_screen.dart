import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:missale_mozarabicum/models/app_settings.dart';
import 'package:missale_mozarabicum/models/fiesta.dart';
import 'package:missale_mozarabicum/models/texto.dart';
import 'package:missale_mozarabicum/widgets/render_texto_fiesta.dart';
import 'package:missale_mozarabicum/widgets/settings_botton.dart';
import 'package:missale_mozarabicum/providers/settings_selectors.dart';

/// Colección de textos revisados a partir de los Word
const String _coleccionTextos = 'textos_v2';

/// Color de la barra de desplazamiento, acorde con el botón de la portada
const Color _colorBarra = Color(0xFFB8AAA1);

/// Pantalla que muestra los textos de una fiesta
class FiestaScreen extends ConsumerStatefulWidget {
  final Fiesta fiesta;

  const FiestaScreen({super.key, required this.fiesta});

  @override
  ConsumerState<FiestaScreen> createState() => _FiestaScreenState();
}

/// Estado de la pantalla que gestiona carga y caché
class _FiestaScreenState extends ConsumerState<FiestaScreen> {
  List<Texto> _textos = [];
  bool _isLoading = true;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _claves = {};

  @override
  void initState() {
    super.initState();
    _loadTextos();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Carga los textos de Firestore para que las correcciones se vean enseguida.
  // La copia guardada solo se usa si no se puede conectar.
  Future<void> _loadTextos() async {
    final prefs = await SharedPreferences.getInstance();
    // La copia guarda todas las ediciones e idiomas; se filtran al mostrarlos
    final cacheKey = '${_coleccionTextos}_${widget.fiesta.codigo}';

    final fiestaId = widget.fiesta.codigo;
    final tiempoId = widget.fiesta.tiempo;

    final QuerySnapshot<Map<String, dynamic>> textosSnap;
    try {
      textosSnap = await FirebaseFirestore.instance
          .collection(_coleccionTextos)
          .where('asoc', arrayContainsAny: [fiestaId, tiempoId])
          .get();
    } catch (e) {
      final copia = prefs.getString(cacheKey);
      if (copia != null) {
        _textos = List<Texto>.from(jsonDecode(copia).map((e) => Texto.fromFirestore(e)));
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Se ordena aquí: así la colección no necesita un índice compuesto en Firestore
    _textos = textosSnap.docs
        .map((doc) => Texto.fromFirestore(doc.data()))
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));

    // Añadir el título al principio con todos los idiomas
    _textos.insert(
      0,
      Texto.titulo(
        widget.fiesta.nombre_es.toUpperCase(),
        widget.fiesta.nombre_en.toUpperCase(),
        widget.fiesta.nombre_la.toUpperCase(),
        widget.fiesta.codigo,
      ),
    );

    await prefs.setString(cacheKey, jsonEncode(_textos.map((t) => t.toJson()).toList()));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(FiestaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia la fiesta, recarga
    if (oldWidget.fiesta.codigo != widget.fiesta.codigo) {
      _loadTextos();
    }
  }

  /// Lleva la pantalla hasta el texto indicado
  void _irA(int indice) {
    final contexto = _claves[indice]?.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      alignment: 0.05,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _buscar(List<Texto> visibles, String idioma) async {
    final indice = await showSearch<int?>(
      context: context,
      delegate: _BuscadorMisa(visibles, idioma),
    );
    if (indice != null) {
      // Se espera a que se cierre el buscador antes de desplazar
      WidgetsBinding.instance.addPostFrameCallback((_) => _irA(indice));
    }
  }

  @override
  Widget build(BuildContext context) {
    final idiomaElegido = ref.watch(localeProvider).languageCode;
    final edicion = ref.watch(edicionProvider);

    // La edición original aún no tiene su propia traducción: mientras tanto se muestra el latín
    final sinTraduccion = edicion == edicionOriginal &&
        idiomaElegido != 'la' &&
        !_textos.any((t) => t.perteneceA(edicion) && t.ediciones.isNotEmpty &&
            t.textoPara(idiomaElegido, edicion).trim().isNotEmpty);
    final idioma = sinTraduccion ? 'la' : idiomaElegido;

    // Solo lo que pertenece a la edición y tiene texto en este idioma
    final visibles = _textos
        .where((t) => t.perteneceA(edicion) && t.textoPara(idioma, edicion).trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (visibles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar o ir a una parte',
              onPressed: () => _buscar(visibles, idioma),
            ),
          const SettingsAppBarButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : visibles.isEmpty
              ? const Center(child: Text('No hay textos para esta fiesta.'))
              : RawScrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  interactive: true,
                  thickness: 10,
                  minThumbLength: 56,
                  radius: const Radius.circular(8),
                  thumbColor: _colorBarra.withValues(alpha: 0.85),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sinTraduccion)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Text(
                              'La traducción al español de la edición original está en preparación. Mientras tanto se muestra el texto latino.',
                              style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (var i = 0; i < visibles.length; i++)
                          KeyedSubtree(
                            key: _claves.putIfAbsent(i, () => GlobalKey()),
                            child: renderTextoFiesta(
                              context: context,
                              ref: ref,
                              texto: visibles[i],
                              index: i,
                              textos: visibles,
                              languageCode: idioma,
                              edicion: edicion,
                              // Al cambiar de fila de la tabla del Word se deja un espacio
                              nuevaSeccion: i > 0 &&
                                  visibles[i].seccion != null &&
                                  visibles[i - 1].seccion != null &&
                                  visibles[i].seccion != visibles[i - 1].seccion,
                            ),
                          ),
                        // Espacio al final para leer cómodamente lo último
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ),
    );
  }
}

/// Quita acentos y mayúsculas para buscar sin tener que escribirlos
String _normalizar(String texto) {
  const de = 'áàäâéèëêíìïîóòöôúùüûñçæœǽ';
  const a = 'aaaaeeeeiiiioooouuuuncaoa';
  final buffer = StringBuffer();
  for (final c in texto.toLowerCase().split('')) {
    final i = de.indexOf(c);
    buffer.write(i >= 0 ? a[i] : c);
  }
  return buffer.toString();
}

/// Buscador de la Misa. Sin escribir nada, muestra el índice de secciones.
class _BuscadorMisa extends SearchDelegate<int?> {
  final List<Texto> textos;
  final String idioma;
  late final List<String> _planos = [
    for (final t in textos) Texto.sinMarcas(t.textoPara(idioma, edicionDe(t))).replaceAll('\n', ' '),
  ];

  _BuscadorMisa(this.textos, this.idioma)
      : super(searchFieldLabel: idioma == 'la' ? 'Quaerere…' : 'Buscar en la Misa…');

  /// Edición con la que se muestra un texto (solo afecta al español de la original)
  String edicionDe(Texto t) => t.ediciones.length == 1 ? t.ediciones.first : edicionIcae;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _lista(context);

  @override
  Widget buildSuggestions(BuildContext context) => _lista(context);

  Widget _lista(BuildContext context) {
    final consulta = _normalizar(query.trim());
    final resultados = <int>[];
    if (consulta.isEmpty) {
      // Índice: títulos de sección
      for (var i = 0; i < textos.length; i++) {
        if (textos[i].tipo == 5) resultados.add(i);
      }
    } else {
      for (var i = 0; i < textos.length; i++) {
        if (_normalizar(_planos[i]).contains(consulta)) resultados.add(i);
      }
    }
    if (resultados.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }
    return ListView.separated(
      itemCount: resultados.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, n) {
        final i = resultados[n];
        return ListTile(
          title: Text(_fragmento(_planos[i], consulta), maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: consulta.isEmpty ? null : Text(_seccionDe(i), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => close(context, i),
        );
      },
    );
  }

  /// Trozo del texto alrededor de lo buscado
  String _fragmento(String texto, String consulta) {
    if (consulta.isEmpty) return texto;
    final pos = _normalizar(texto).indexOf(consulta);
    final inicio = (pos - 40).clamp(0, texto.length);
    return '${inicio > 0 ? '…' : ''}${texto.substring(inicio)}';
  }

  /// Título de la sección en la que está el texto
  String _seccionDe(int i) {
    for (var j = i; j >= 0; j--) {
      if (textos[j].tipo == 5) return _planos[j];
    }
    return '';
  }
}
