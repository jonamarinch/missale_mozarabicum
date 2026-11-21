import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:missale_mozarabicum/models/fiesta.dart' as fiesta;
import 'package:missale_mozarabicum/screens/fiesta_screen.dart';
import 'package:missale_mozarabicum/screens/registro_screen.dart';
import 'package:missale_mozarabicum/services/liturgical_calendar.dart';
import 'package:missale_mozarabicum/widgets/settings_botton.dart';
import 'package:missale_mozarabicum/providers/settings_selectors.dart';
import 'package:missale_mozarabicum/providers/calendar_locale_fallback.dart';

/// Color de los domingos que se pueden elegir (violeta del Adviento)
const Color _violeta = Color(0xFF7B5EA7);

/// En el calendario solo se pueden elegir los domingos de Adviento (decisión del usuario,
/// 14/11/2026): el cálculo del resto de fiestas está por revisar.
Map<DateTime, String> _domingosAdviento(int year) => {
      for (final y in [year - 1, year, year + 1]) ...LiturgicalCalendar.domingosAdviento(y),
    };

/// Primer domingo de Adviento igual o posterior a hoy
DateTime _proximoDomingoAdviento(DateTime hoy) {
  final dia = DateTime(hoy.year, hoy.month, hoy.day);
  final fechas = _domingosAdviento(hoy.year).keys.where((d) => !d.isBefore(dia)).toList()..sort();
  return fechas.first;
}

/// Fecha elegida en el calendario: al abrir, el próximo domingo de Adviento
final selectedDateProvider = StateProvider<DateTime>((ref) => _proximoDomingoAdviento(DateTime.now()));

/// Fiesta de la fecha elegida (solo domingos de Adviento)
final fiestaProvider = FutureProvider.autoDispose<fiesta.Fiesta?>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final codigo = _domingosAdviento(date.year)[DateTime(date.year, date.month, date.day)];
  if (codigo == null) return null;
  return fiesta.getFiesta(codigo);
});

/// Pantalla principal: se elige un domingo de Adviento en el calendario
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final fiestaAsync = ref.watch(fiestaProvider);
    final idioma = ref.watch(localeProvider).languageCode;
    final calendarLocale = ref.watch(calendarLocaleForTableCalendarProvider);
    rememberLastValidCalendarLocale(ref);
    final colores = Theme.of(context).colorScheme;

    bool esDomingoAdviento(DateTime d) =>
        _domingosAdviento(d.year).containsKey(DateTime(d.year, d.month, d.day));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Missale Mozarabicum",
          style: TextStyle(fontFamily: 'Cardo', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        actions: [
          // Registro dominical (datos privados): solo en la app del móvil, no en la web pública
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Registro dominical',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistroScreen()),
              ),
            ),
          const SettingsAppBarButton(),
        ],
      ),
      // Se desplaza si no cabe, y se centra si sobra espacio
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity)),
            child: Center(
              // En pantallas anchas (ordenador) el calendario no se estira de lado a lado
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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

                    TableCalendar(
                      locale: calendarLocale,
                      firstDay: DateTime(DateTime.now().year - 1, 1, 1),
                      lastDay: DateTime(DateTime.now().year + 1, 12, 31),
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                      // Solo se pueden tocar los domingos de Adviento
                      enabledDayPredicate: esDomingoAdviento,
                      onDaySelected: (day, focusedDay) {
                        ref.read(selectedDateProvider.notifier).state = day;
                      },
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarFormat: CalendarFormat.month,
                      // Deja el gesto vertical libre para poder desplazar la pantalla
                      availableGestures: AvailableGestures.horizontalSwipe,
                      availableCalendarFormats: const {CalendarFormat.month: ''},
                      sixWeekMonthsEnforced: true,
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        titleTextStyle: TextStyle(fontSize: 17, color: colores.onSurface),
                        leftChevronIcon: Icon(Icons.chevron_left, color: colores.onSurface),
                        rightChevronIcon: Icon(Icons.chevron_right, color: colores.onSurface),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: colores.onSurface.withValues(alpha: 0.75)),
                        weekendStyle: TextStyle(color: colores.onSurface.withValues(alpha: 0.6)),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        isTodayHighlighted: false,
                        // Los días que no se pueden elegir quedan apagados
                        disabledTextStyle: TextStyle(color: colores.onSurface.withValues(alpha: 0.25)),
                        defaultTextStyle: TextStyle(color: colores.onSurface),
                        weekendTextStyle: TextStyle(color: colores.onSurface),
                        // Domingos de Adviento: en violeta; el elegido, relleno
                        selectedDecoration: const BoxDecoration(color: _violeta, shape: BoxShape.circle),
                        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (!esDomingoAdviento(day)) return null;
                          return Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _violeta, width: 2),
                              ),
                              child: Text('${day.day}',
                                  style: const TextStyle(color: _violeta, fontWeight: FontWeight.w700)),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nombre de la fiesta elegida
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 50),
                      child: fiestaAsync.when(
                        data: (f) => Text(
                          f == null ? _elegirTexto(idioma) : f.getNombreForLanguage(idioma),
                          style: const TextStyle(fontSize: 20, fontFamily: 'Cardo'),
                          textAlign: TextAlign.center,
                        ),
                        loading: () => const SizedBox(height: 20),
                        error: (e, _) => Text(
                          _sinConexionTexto(idioma),
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    FractionallySizedBox(
                      widthFactor: 0.5,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFb8aaa1),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          textStyle: const TextStyle(
                              fontFamily: 'Cardo', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 1.1),
                        ),
                        onPressed: fiestaAsync.maybeWhen(
                          data: (f) => f == null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FiestaScreen(fiesta: f)),
                                  ),
                          orElse: () => null,
                        ),
                        child: Text(_continuarTexto(idioma)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _elegirTexto(String idioma) {
    switch (idioma) {
      case 'en':
        return 'Choose a Sunday of Advent';
      case 'la':
        return 'Dominicam Adventus elige';
      default:
        return 'Elige un domingo de Adviento';
    }
  }

  String _continuarTexto(String idioma) {
    switch (idioma) {
      case 'en':
        return 'Continue';
      case 'la':
        return 'Procedere';
      default:
        return 'Continuar';
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
