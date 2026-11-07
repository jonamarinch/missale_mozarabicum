import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:missale_mozarabicum/models/fiesta.dart';
import 'package:missale_mozarabicum/models/texto.dart';
import 'package:missale_mozarabicum/widgets/render_texto_fiesta.dart';
import 'package:missale_mozarabicum/widgets/settings_botton.dart';
import 'package:missale_mozarabicum/providers/settings_selectors.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTextos();
  }

  // Carga los textos de Firestore para que las correcciones se vean enseguida.
  // La copia guardada solo se usa si no se puede conectar.
  Future<void> _loadTextos() async {
    print('[TAG] Entrando en _loadTextos');

    // Obtener el idioma actual
    final currentLocale = ref.read(localeProvider);
    final languageCode = currentLocale.languageCode;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'textos_${widget.fiesta.codigo}_$languageCode';

    final fiestaId = widget.fiesta.codigo;
    final tiempoId = widget.fiesta.tiempo;

    print('[TAG] Consultando Firestore: fiestaId=$fiestaId, tiempoId=$tiempoId, idioma=$languageCode');

    final QuerySnapshot<Map<String, dynamic>> textosSnap;
    try {
      textosSnap = await FirebaseFirestore.instance
          .collection('textos')
          .where('asoc', arrayContainsAny: [fiestaId, tiempoId])
          .orderBy('orden')
          .get();
    } catch (e) {
      print('[TAG] No se pudo consultar Firestore: $e');
      final copia = prefs.getString(cacheKey);
      if (copia != null) {
        print('[TAG] Cargando copia guardada para idioma: $languageCode');
        _textos = List<Texto>.from(jsonDecode(copia).map((e) => Texto.fromFirestore(e)));
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    print('[TAG] textosSnap.docs.length: ${textosSnap.docs.length}');

    // Eliminar duplicados (asumiendo que la combinación de 'orden' y 'txt' es única)
    final uniqueDocs = {
      for (var doc in textosSnap.docs) doc.id: doc,
    }.values.toList();

    print('[TAG] uniqueDocs.length: ${uniqueDocs.length}');

    _textos = uniqueDocs
        .map((doc) => Texto.fromFirestore(doc.data()))
        .toList();

    print('[TAG] _textos.length: ${_textos.length}');

    // Añadir el título al principio con todos los idiomas
    Texto titulo = Texto.titulo(
        widget.fiesta.nombre_es.toUpperCase(),
        widget.fiesta.nombre_en.toUpperCase(),
        widget.fiesta.nombre_la.toUpperCase(),
        widget.fiesta.codigo
    );
    _textos.insert(0, titulo);

    // Guardamos los textos en caché con el idioma
    final jsonTextos = jsonEncode(_textos.map((t) => t.toJson()).toList());
    await prefs.setString(cacheKey, jsonTextos);

    print('[TAG] Hecho - guardado en caché para idioma: $languageCode');

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

  // Método para detectar cambios de idioma y recargar si es necesario
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider); // Idioma actual

    // Detectar cambios de idioma y recargar si es necesario
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous != null && previous.languageCode != next.languageCode) {
        print('[TAG] Idioma cambió de ${previous.languageCode} a ${next.languageCode}, recargando textos...');
        _loadTextos();
      }
    });

    return Scaffold(
      appBar: AppBar(
        // Botón de configuración en el AppBar
        actions: const [
          SettingsAppBarButton(),
        ],
      ),
      body: _isLoading
      // Indicador de carga
          ? const Center(child: CircularProgressIndicator())
      // Texto si no hay resultados
          : _textos.isEmpty
          ? const Center(child: Text('No hay textos para esta fiesta.'))
      // Lista de textos
          : ListView.builder(
        itemCount: _textos.length,
        itemBuilder: (context, index) {
          final texto = _textos[index];

          return renderTextoFiesta(
            context: context,
            ref: ref,
            texto: texto,
            index: index,
            textos: _textos,
            languageCode: currentLocale.languageCode, // Pasar el idioma
          );
        },
      ),
    );
  }
}