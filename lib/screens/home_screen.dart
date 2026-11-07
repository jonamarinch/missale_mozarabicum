import 'package:flutter/material.dart';
import 'package:missale_mozarabicum/services/liturgical_calendar.dart';
import 'package:missale_mozarabicum/models/fiesta.dart' as fiesta;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:missale_mozarabicum/screens/fiesta_screen.dart';
import 'package:missale_mozarabicum/widgets/settings_botton.dart';
import 'package:missale_mozarabicum/providers/settings_selectors.dart';
import 'package:missale_mozarabicum/providers/calendar_locale_fallback.dart';

// Provider para seleccionar fecha
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
// Provider para la fiesta
final fiestaProvider = FutureProvider.autoDispose<fiesta.Fiesta?>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final codigo = LiturgicalCalendar.getFiestaDesde(date);
  if (codigo.isEmpty) return null;
  return fiesta.getFiesta(codigo);
});

/// Pantalla principal donde se elige una fecha y se muestra la fiesta correspondiente
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Fiestas cuyos textos están revisados y se pueden abrir por ahora
  static const Set<String> _fiestasDisponibles = {'adv1'};

  // Indica si la fiesta que corresponde a la fecha ya se puede abrir
  bool _esFiestaDisponible(DateTime date) {
    final codigo = LiturgicalCalendar.getFiestaDesde(date);
    return _fiestasDisponibles.contains(codigo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final fiestaAsync = ref.watch(fiestaProvider);
    final currentLocale = ref.watch(localeProvider); // Idioma actual

    // Verificar si la fiesta de la fecha elegida ya se puede abrir
    final esAccesible = _esFiestaDisponible(selectedDate);

    // Usar el provider existente para manejar el locale del calendario
    final calendarLocale = ref.watch(calendarLocaleForTableCalendarProvider);

    // Configurar el listener para recordar el último locale válido
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
        // Botón de configuración en el AppBar
        actions: const [
          SettingsAppBarButton(),
        ],
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFc00000),
                        endIndent: 8,
                      ),
                    ),
                    const Text(
                      '✠',
                      style: TextStyle(
                        fontSize: 32,
                        color: Color(0xFFc00000),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFc00000),
                        indent: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Calendario
              TableCalendar(
                locale: calendarLocale,
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                onDaySelected: (day, focusedDay) {
                  ref.read(selectedDateProvider.notifier).state = day;
                },

                calendarFormat: CalendarFormat.month,
                // Deja el gesto vertical libre para poder desplazar la pantalla
                availableGestures: AvailableGestures.horizontalSwipe,
                availableCalendarFormats: const {
                  CalendarFormat.month: '',
                },

                sixWeekMonthsEnforced: true,

                headerVisible: true, // Controla la visibilidad de la cabecera (mes, botones)

                headerStyle: HeaderStyle(
                  titleCentered: true,
                ),

                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  isTodayHighlighted: false,
                  selectedDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.black87),
                  weekendTextStyle: TextStyle(color: Colors.black54),
                  selectedTextStyle: TextStyle(color: Colors.blue),
                ),
              ),

              const SizedBox(height: 40),

              // Texto indicativo de la fiesta
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: fiestaAsync.when(
                  data: (fiesta) {
                    if (fiesta == null) {
                      return _getNoFiestaText(currentLocale.languageCode);
                    }

                    final nombreFiesta = fiesta.getNombreForLanguage(currentLocale.languageCode);
                    return Text(
                      _getFiestaProximaText(currentLocale.languageCode, nombreFiesta),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cardo',
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                  loading: () => const SizedBox(height: 20),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botón para acceder a la siguiente pantalla
              FractionallySizedBox(
                widthFactor: 0.4, // Ocupa el 40% del ancho del padre
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFb8aaa1), // Color acorde a tu estética
                    foregroundColor: Colors.white, // Color del texto
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Esquinas redondeadas
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Cardo',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                  // Sólo se habilita si la fiesta ya se puede abrir
                  onPressed: esAccesible
                      ? fiestaAsync.maybeWhen(
                        data: (fiesta) => fiesta != null
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FiestaScreen(fiesta: fiesta),
                              ),
                            );
                          }
                        : null,
                    orElse: () => null,
                  ) : null, // null desactiva el botón
                  child: Text(_getContinuarText(currentLocale.languageCode)),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  // Funciones auxiliares para los textos traducidos
  Widget _getNoFiestaText(String languageCode) {
    final text = _getNoFiestaString(languageCode);
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontFamily: 'Cardo',
      ),
      textAlign: TextAlign.center,
    );
  }

  String _getNoFiestaString(String languageCode) {
    switch (languageCode) {
      case 'es':
        return "No se ha encontrado fiesta";
      case 'en':
        return "No feast found";
      case 'la':
        return "Festum non inventum";
      default:
        return "No se ha encontrado fiesta";
    }
  }

  String _getFiestaProximaText(String languageCode, String nombreFiesta) {
    switch (languageCode) {
      case 'es':
        return "Fiesta próxima: $nombreFiesta";
      case 'en':
        return "Next feast: $nombreFiesta";
      case 'la':
        return "Festum proximum: $nombreFiesta";
      default:
        return "Fiesta próxima: $nombreFiesta";
    }
  }

  String _getContinuarText(String languageCode) {
    switch (languageCode) {
      case 'es':
        return "Continuar";
      case 'en':
        return "Continue";
      case 'la':
        return "Procedere";
      default:
        return "Continuar";
    }
  }
}