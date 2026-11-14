// lib/widgets/render_texto_fiesta.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missale_mozarabicum/models/texto.dart';
import 'package:missale_mozarabicum/services/control_estilos.dart';
import 'package:missale_mozarabicum/services/tipo_texto_style.dart';
import 'package:missale_mozarabicum/services/tipos_texto.dart';
import 'build_texto_widgets.dart';

// Constante para el espaciado mínimo entre textos
const double _minVerticalSpacing = 5.0;

Widget renderTextoFiesta({
  required BuildContext context,
  required WidgetRef ref,
  required Texto texto,
  required int index,
  required List<Texto> textos,
  required String languageCode,
  required String edicion,
  bool nuevaSeccion = false,
}) {
  final hijo = _renderTexto(
    context: context, ref: ref, texto: texto, index: index, textos: textos,
    languageCode: languageCode, edicion: edicion,
  );
  // Espacio como en el Word: una línea en blanco donde el Word la tiene, o al cambiar de sección
  final hueco = texto.huecoPara(languageCode) > 0 || nuevaSeccion;
  return hueco ? Padding(padding: const EdgeInsets.only(top: _altoLineaBlanca), child: hijo) : hijo;
}

/// Alto de una línea en blanco del Word
const double _altoLineaBlanca = 18.0;

/// Alto con el que se ven las láminas; al tocarlas se abren a pantalla completa
const double _altoLamina = 210.0;

/// Láminas del Word (grabados del altar, ruedas de la fracción), centradas y una junto a otra
class _Laminas extends StatelessWidget {
  final List<String> nombres;

  const _Laminas({required this.nombres});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: _minVerticalSpacing * 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final nombre in nombres)
            GestureDetector(
              onTap: () => _ampliar(context, nombre),
              child: Image.asset(
                'assets/laminas/$nombre',
                height: _altoLamina,
                fit: BoxFit.contain,
                semanticLabel: 'Lámina',
                // Si falta la imagen (app antigua) no se muestra nada
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }

  void _ampliar(BuildContext context, String nombre) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.asset('assets/laminas/$nombre', fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _renderTexto({
  required BuildContext context,
  required WidgetRef ref,
  required Texto texto,
  required int index,
  required List<Texto> textos,
  required String languageCode,
  required String edicion,
}) {
  final tipo = texto.tipoPara(languageCode);
  final TipoTextoStyle cfg = ControlEstilos.estiloPorTipo(
    context,
    ref,
    TipoTexto.values[tipo - 1],
  );

  final rawText = texto.textoPara(languageCode, edicion);
  final text = rawText;

  // Lámina del Word: se dibuja la imagen, igual en todos los idiomas
  final laminas = Texto.laminasDe(rawText);
  if (laminas.isNotEmpty) {
    return _Laminas(nombres: laminas);
  }

  final siguiente = index + 1 < textos.length ? textos[index + 1] : null;
  final tipoActual = tipo;
  final tipoSiguiente = siguiente?.tipoPara(languageCode);

  // Una referencia (tipo 4) va pegada al título (5 u 8) que la precede: sin margen ni
  // el espacio que la tipografía reserva por encima y por debajo de la línea en esa unión
  final tipoAnterior = index > 0 ? textos[index - 1].tipoPara(languageCode) : 0;
  final pegadaArriba = tipoActual == 4 && (tipoAnterior == 5 || tipoAnterior == 8);
  final pegadaAbajo = (tipoActual == 5 || tipoActual == 8) && tipoSiguiente == 4;

  // Tipo 1: Normal
  if (tipo == 1) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      ),
      child: buildTextoMarcado(text, cfg, context: context),
    );
  }
  // Tipo 3: Semirrubrica
  else if (tipo == 3) {
    final cfg3 = cfg.copyWith(
      style: cfg.style.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      ),
      child: buildTextoMarcado(text, cfg3, context: context),
    );
  }
  // Tipos 4, 5, 8: Rúbricas centradas y título
  else if (tipo == 4 || tipo == 5 || tipo == 8) {
    return Padding(
      padding: EdgeInsets.only(
        top: pegadaArriba ? 0 : _minVerticalSpacing,
        bottom: pegadaAbajo ? 0 : _minVerticalSpacing,
        left: 16,
        right: 16,
      ),
      child: buildTextoMarcado(
        text, cfg, context: context,
        recortarArriba: pegadaArriba, recortarAbajo: pegadaAbajo,
      ),
    );
  }
  // Resto de tipos (2, 6, 7)
  else {
    return Padding(
      padding: tipo == 7
          ? const EdgeInsets.only(
        left: 30,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      )
          : EdgeInsets.only(
        left: 16,
        right: 16,
        top: _minVerticalSpacing,
        bottom: _minVerticalSpacing,
      ),
      child: buildTextoMarcado(text, cfg, context: context),
    );
  }
}