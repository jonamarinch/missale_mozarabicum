import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:missale_mozarabicum/models/fiesta.dart' as fiesta;
import 'package:missale_mozarabicum/screens/fiesta_screen.dart';
import 'package:missale_mozarabicum/services/liturgical_calendar.dart';
import 'package:missale_mozarabicum/widgets/settings_botton.dart';
import 'package:missale_mozarabicum/providers/settings_selectors.dart';
import 'package:missale_mozarabicum/providers/calendar_locale_fallback.dart';

/// Fiestas que se pueden abrir por ahora: solo las revisadas y cargadas.
/// El resto del calendario no se muestra (decisión del usuario, 14/11/2026).
const List<String> fiestasDisponibles = ['adv1', 'adv2'];

/// Datos de las fiestas disponibles, en el orden de la lista
final fiestasDisponiblesProvider = FutureProvider<List<fiesta.Fiesta>>((ref) async {
  final lista = await Future.wait(fiestasDisponibles.map(fiesta.getFiesta));
  return lista.whereType<fiesta.Fiesta>().toList();
});

/// Pantalla principal: se elige uno de los domingos disponibles
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiestasAsync = ref.watch(fiestasDisponiblesProvider);
    final idioma = ref.watch(localeProvider).languageCode;
    // El latín no tiene formato de fecha propio: se usa el último idioma válido
    final localeFechas = ref.watch(calendarLocaleForTableCalendarProvider);
    rememberLastValidCalendarLocale(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Missale Mozarabicum",
          style: TextStyle(
            fontFamily: 'Cardo',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: const [SettingsAppBarButton()],
      ),
      // Se desplaza si no cabe, y se centra si sobra espacio
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Separador visual grande con cruz
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider(thickness: 2, color: Color(0xFFc00000), endIndent: 8)),
                      Text('✠', style: TextStyle(fontSize: 32, color: Color(0xFFc00000))),
                      Expanded(child: Divider(thickness: 2, color: Color(0xFFc00000), indent: 8)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _elegirTexto(idioma),
                  style: const TextStyle(fontSize: 20, fontFamily: 'Cardo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                fiestasAsync.when(
                  data: (fiestas) => fiestas.isEmpty
                      ? Text(_sinConexionTexto(idioma), textAlign: TextAlign.center)
                      : Column(
                          children: [
                            for (final f in fiestas)
                              _TarjetaFiesta(
                                datos: f,
                                nombre: f.getNombreForLanguage(idioma),
                                fecha: _fechaTexto(f.codigo, localeFechas),
                              ),
                          ],
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Text(
                    _sinConexionTexto(idioma),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Próxima fecha de la fiesta (hoy incluido), en el idioma de la app
  String _fechaTexto(String codigo, String locale) {
    final fecha = LiturgicalCalendar.proximaFecha(codigo, DateTime.now());
    if (fecha == null) return '';
    try {
      return DateFormat.yMMMMEEEEd(locale).format(fecha);
    } catch (_) {
      return DateFormat.yMMMMEEEEd('es').format(fecha);
    }
  }

  String _elegirTexto(String idioma) {
    switch (idioma) {
      case 'en':
        return 'Choose the Mass';
      case 'la':
        return 'Missam elige';
      default:
        return 'Elige la Misa';
    }
  }

  String _sinConexionTexto(String idioma) {
    switch (idioma) {
      case 'en':
        return 'Could not connect. Check your connection and try again.';
      case 'la':
        return 'Conexio deest.';
      default:
        return 'No se ha podido conectar. Comprueba la conexión y vuelve a intentarlo.';
    }
  }
}

/// Botón grande con el nombre de la fiesta y su fecha: al tocarlo se abre la Misa
class _TarjetaFiesta extends StatelessWidget {
  final fiesta.Fiesta datos;
  final String nombre;
  final String fecha;

  const _TarjetaFiesta({required this.datos, required this.nombre, required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFb8aaa1),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FiestaScreen(fiesta: datos)),
          ),
          child: Column(
            children: [
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cardo', fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (fecha.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(fecha, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
