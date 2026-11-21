// Pantalla del registro dominical (solo en la app del móvil, no en la web).
// Pide la clave del registro; solo la cuenta con el permiso `registro` ve y apunta datos.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:missale_mozarabicum/services/liturgical_calendar.dart';
import 'package:missale_mozarabicum/services/registro_informe.dart';
import 'package:missale_mozarabicum/services/registro_service.dart';

final _euros = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);
String euros(int cent) => _euros.format(cent / 100);

/// Importe en céntimos como texto editable: 1250 → «12,50»
String _textoDeCent(int cent) => cent == 0 ? '' : (cent / 100).toStringAsFixed(2).replaceAll('.', ',');

String _fechaLarga(DateTime f) => DateFormat("d 'de' MMMM 'de' y", 'es').format(f);

/// «1.º domingo de Adviento» si la fecha es uno; si no, null
String? _nombreDomingo(DateTime f) {
  final codigo = LiturgicalCalendar.domingosAdviento(f.year)[DateTime(f.year, f.month, f.day)] ??
      LiturgicalCalendar.domingosAdviento(f.year + 1)[DateTime(f.year, f.month, f.day)];
  if (codigo == null) return null;
  return '${codigo.substring(3)}.º domingo de Adviento';
}

class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const _Acceso();
        return _ComprobarPermiso(user: user);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Inicio de sesión con una clave única (decisión del usuario, 21/11/2026): hay una sola
// cuenta compartida, con correo fijo; solo se escribe la clave. La clave no está en el código:
// se pone o se cambia desde el ordenador con src/clave_registro.js del importador.
// ---------------------------------------------------------------------------

const _correoRegistro = 'registro@missalemozarabicum.web.app';

class _Acceso extends StatefulWidget {
  const _Acceso();

  @override
  State<_Acceso> createState() => _AccesoState();
}

class _AccesoState extends State<_Acceso> {
  final _clave = TextEditingController();
  bool _ocupado = false;
  bool _verClave = false;
  String? _error;

  Future<void> _entrar() async {
    if (_clave.text.isEmpty) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _correoRegistro, password: _clave.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensajeError(e.code));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Clave incorrecta.';
      case 'network-request-failed':
        return 'No hay conexión a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un poco y vuelve a probar.';
      default:
        return 'No se ha podido entrar ($codigo).';
    }
  }

  @override
  void dispose() {
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro dominical')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Estos datos son privados. Escribe la clave para verlos o apuntarlos.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _clave,
            obscureText: !_verClave,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Clave',
              suffixIcon: IconButton(
                icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                onPressed: () => setState(() => _verClave = !_verClave),
              ),
            ),
            onSubmitted: (_) => _entrar(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _ocupado ? null : _entrar, child: const Text('Entrar')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permiso: la cuenta debe tener `registro: true`, que se da desde el ordenador
// ---------------------------------------------------------------------------

class _ComprobarPermiso extends StatefulWidget {
  final User user;
  const _ComprobarPermiso({required this.user});

  @override
  State<_ComprobarPermiso> createState() => _ComprobarPermisoState();
}

class _ComprobarPermisoState extends State<_ComprobarPermiso> {
  late Future<bool> _permiso = _comprobar();

  /// Pide un pase nuevo a Firebase para enterarse si se acaba de dar el permiso
  Future<bool> _comprobar() async {
    final t = await widget.user.getIdTokenResult(true);
    return t.claims?['registro'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permiso,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == true) return const _Registro();
        return Scaffold(
          appBar: AppBar(title: const Text('Registro dominical')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                snap.hasError
                    ? 'No se ha podido comprobar el permiso. ¿Hay conexión a internet?'
                    : 'Esta cuenta todavía no tiene permiso para el registro.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _permiso = _comprobar()),
                child: const Text('Comprobar de nuevo'),
              ),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de domingos del año
// ---------------------------------------------------------------------------

class _Registro extends StatefulWidget {
  const _Registro();

  @override
  State<_Registro> createState() => _RegistroState();
}

class _RegistroState extends State<_Registro> {
  final _servicio = RegistroService();
  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;

  /// Vista por meses (por defecto) o por años
  bool _porMes = true;

  PeriodoInforme get _periodo => PeriodoInforme(_anio, _porMes ? _mes : null);

  void _mover(int paso) => setState(() {
        if (!_porMes) {
          _anio += paso;
          return;
        }
        final f = DateTime(_anio, _mes + paso, 1);
        _anio = f.year;
        _mes = f.month;
      });

  /// Genera el informe del periodo que se está viendo y deja compartirlo, guardarlo o imprimirlo
  Future<void> _informe() async {
    final domingos = _domingos;
    if (domingos == null) return;
    final periodo = _periodo;
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Informe en PDF · ${periodo.nombre}', style: const TextStyle(fontWeight: FontWeight.w600))),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir o guardar'),
              subtitle: const Text('WhatsApp, correo, Drive, Archivos…'),
              onTap: () => Navigator.pop(context, 'compartir'),
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Ver e imprimir'),
              subtitle: const Text('También permite guardarlo como PDF'),
              onTap: () => Navigator.pop(context, 'imprimir'),
            ),
          ],
        ),
      ),
    );
    if (opcion == null || !mounted) return;
    final avisos = ScaffoldMessenger.of(context);
    try {
      final pdf = await informePdf(
        periodo: periodo,
        todos: domingos,
        saldoInicialCent: _saldoInicial,
        nombreDomingo: _nombreDomingo,
      );
      if (opcion == 'compartir') {
        await Printing.sharePdf(bytes: pdf, filename: periodo.archivo);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => pdf, name: periodo.archivo);
      }
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text('No se ha podido crear el informe: $e')));
    }
  }

  List<RegistroDomingo>? _domingos;
  int _saldoInicial = 0;
  Object? _error;
  late final StreamSubscription _subDomingos;
  late final StreamSubscription _subCaja;

  @override
  void initState() {
    super.initState();
    _subDomingos = _servicio.domingos().listen(
          (d) => setState(() => _domingos = d),
          onError: (e) => setState(() => _error = e),
        );
    _subCaja = _servicio.cajaInicial().listen(
          (c) => setState(() => _saldoInicial = c.saldoCent),
          onError: (e) => setState(() => _error = e),
        );
  }

  @override
  void dispose() {
    _subDomingos.cancel();
    _subCaja.cancel();
    super.dispose();
  }

  Future<void> _editarSaldoInicial() async {
    final ctrl = TextEditingController(text: _textoDeCent(_saldoInicial));
    final res = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saldo inicial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dinero que había en la caja antes del primer domingo apuntado.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(suffixText: '€'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final c = centimosDeTexto(ctrl.text);
              if (c != null) Navigator.pop(context, c);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (res != null) await _servicio.guardarCajaInicial(res);
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final domingos = _domingos;

    Widget cuerpo;
    if (_error != null) {
      cuerpo = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se han podido leer los datos.\n$_error', textAlign: TextAlign.center),
        ),
      );
    } else if (domingos == null) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else {
      final porId = {for (final r in domingos) idDeFecha(r.fecha): r};
      final hoy = DateTime.now();
      final limite = DateTime(hoy.year, hoy.month, hoy.day + 7); // hasta el próximo domingo
      final periodo = _periodo;
      bool dentro(DateTime d) => !d.isBefore(periodo.inicio) && !d.isAfter(periodo.fin);
      final fechas = domingosDelAnio(_anio).where((d) => dentro(d) && d.isBefore(limite)).toList().reversed.toList();
      final delPeriodo = domingos.where((r) => dentro(r.fecha)).toList();
      // Tras el último domingo apuntado (aunque se haya adelantado el próximo)
      final fondosHoy = fondosEnFecha(domingos, _saldoInicial, DateTime(9999));
      final hayFuturo = periodo.fin.isBefore(DateTime(hoy.year, hoy.month, hoy.day));

      cuerpo = ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Fondos actuales'),
                  const SizedBox(height: 4),
                  Text(euros(fondosHoy),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: fondosHoy < 0 ? colores.error : null,
                      )),
                  const Divider(height: 24),
                  _Resumen(
                    titulo: periodo.nombre,
                    domingos: delPeriodo,
                    fondosAlTerminar: fondosEnFecha(domingos, _saldoInicial, periodo.fin),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Por meses'), icon: Icon(Icons.calendar_view_month)),
                ButtonSegment(value: false, label: Text('Por años'), icon: Icon(Icons.calendar_today)),
              ],
              selected: {_porMes},
              onSelectionChanged: (s) => setState(() => _porMes = s.first),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _mover(-1)),
              Text(periodo.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              // No se pasa de hoy: más adelante no hay domingos que apuntar
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: hayFuturo ? () => _mover(1) : null),
            ],
          ),
          if (fechas.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No hay domingos.')),
          for (final (n, f) in fechas.indexed) ...[
            // En la vista por años, el nombre del mes separa los domingos
            if (!_porMes && (n == 0 || fechas[n - 1].month != f.month))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Text(
                  PeriodoInforme(f.year, f.month).nombre.split(' ').first,
                  style: TextStyle(fontWeight: FontWeight.w700, color: colores.primary),
                ),
              ),
            _FilaDomingo(
              fecha: f,
              registro: porId[idDeFecha(f)],
              fondos: fondosEnFecha(domingos, _saldoInicial, f),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _EditarDomingo(
                    fecha: f,
                    registro: porId[idDeFecha(f)],
                    // Fondos sin contar este domingo, para mostrar el resultado mientras se escribe
                    fondosPrevios: fondosEnFecha(
                      domingos.where((r) => idDeFecha(r.fecha) != idDeFecha(f)).toList(),
                      _saldoInicial,
                      f,
                    ),
                    servicio: _servicio,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro dominical'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Informe en PDF del periodo',
            onPressed: domingos == null ? null : _informe,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'saldo') _editarSaldoInicial();
              if (v == 'salir') FirebaseAuth.instance.signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'saldo', child: Text('Saldo inicial: ${euros(_saldoInicial)}')),
              const PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: cuerpo,
    );
  }
}

class _Resumen extends StatelessWidget {
  final String titulo;
  final List<RegistroDomingo> domingos;
  final int fondosAlTerminar;
  const _Resumen({required this.titulo, required this.domingos, required this.fondosAlTerminar});

  @override
  Widget build(BuildContext context) {
    final conAsist = domingos.where((r) => r.asistentes != null).toList();
    final conCom = domingos.where((r) => r.comulgantes != null).toList();
    final recibido = domingos.fold<int>(0, (s, r) => s + r.recibidoCent);
    final gastos = domingos.fold<int>(0, (s, r) => s + r.gastosCent);
    String media(List<int> v) => v.isEmpty ? '—' : (v.reduce((a, b) => a + b) / v.length).toStringAsFixed(0);

    Widget fila(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [Expanded(child: Text(a)), Text(b, style: const TextStyle(fontWeight: FontWeight.w600))]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$titulo (${domingos.length} ${domingos.length == 1 ? 'domingo apuntado' : 'domingos apuntados'})',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        fila('Media de asistentes', media(conAsist.map((r) => r.asistentes!).toList())),
        fila('Media de comulgantes', media(conCom.map((r) => r.comulgantes!).toList())),
        fila('Fondos recibidos', euros(recibido)),
        fila('Gastos', euros(gastos)),
        fila('Fondos al terminar', euros(fondosAlTerminar)),
      ],
    );
  }
}

class _FilaDomingo extends StatelessWidget {
  final DateTime fecha;
  final RegistroDomingo? registro;
  final int fondos;
  final VoidCallback onTap;
  const _FilaDomingo({required this.fecha, required this.registro, required this.fondos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final nombre = _nombreDomingo(fecha);
    final apagado = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return ListTile(
      onTap: onTap,
      title: Text(DateFormat("d 'de' MMMM", 'es').format(fecha) + (nombre == null ? '' : ' · $nombre')),
      subtitle: r == null
          ? Text('Sin datos', style: TextStyle(color: apagado))
          : Text('${r.asistentes ?? '—'} asistentes · ${r.comulgantes ?? '—'} comulgantes\n'
              '+${euros(r.recibidoCent)}  −${euros(r.gastosCent)}'
              '${r.ajusteCent != 0 ? '  ajuste ${euros(r.ajusteCent)}' : ''}'),
      isThreeLine: r != null,
      trailing: Text(euros(fondos), style: TextStyle(color: r == null ? apagado : null)),
    );
  }
}

// ---------------------------------------------------------------------------
// Apuntar o corregir un domingo
// ---------------------------------------------------------------------------

class _EditarDomingo extends StatefulWidget {
  final DateTime fecha;
  final RegistroDomingo? registro;
  final int fondosPrevios;
  final RegistroService servicio;
  const _EditarDomingo({
    required this.fecha,
    required this.registro,
    required this.fondosPrevios,
    required this.servicio,
  });

  @override
  State<_EditarDomingo> createState() => _EditarDomingoState();
}

class _EditarDomingoState extends State<_EditarDomingo> {
  late final _asistentes = TextEditingController(text: widget.registro?.asistentes?.toString() ?? '');
  late final _comulgantes = TextEditingController(text: widget.registro?.comulgantes?.toString() ?? '');
  late final _recibido = TextEditingController(text: _textoDeCent(widget.registro?.recibidoCent ?? 0));
  late final _gastos = TextEditingController(text: _textoDeCent(widget.registro?.gastosCent ?? 0));
  late final _ajuste = TextEditingController(text: _textoDeCent(widget.registro?.ajusteCent ?? 0));
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_asistentes, _comulgantes, _recibido, _gastos, _ajuste]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _entero(TextEditingController c) => c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

  Future<void> _guardar() async {
    final recibido = centimosDeTexto(_recibido.text);
    final gastos = centimosDeTexto(_gastos.text);
    final ajuste = centimosDeTexto(_ajuste.text);
    if (recibido == null || gastos == null || ajuste == null || recibido < 0 || gastos < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa los importes.')));
      return;
    }
    setState(() => _guardando = true);
    final r = RegistroDomingo(
      fecha: widget.fecha,
      asistentes: _entero(_asistentes),
      comulgantes: _entero(_comulgantes),
      recibidoCent: recibido,
      gastosCent: gastos,
      ajusteCent: ajuste,
    );
    // Sin conexión, Firestore lo guarda en el móvil y lo sube al volver la conexión:
    // no se espera a la respuesta del servidor para cerrar.
    final avisos = ScaffoldMessenger.of(context);
    unawaited(widget.servicio.guardar(r).catchError((Object e) {
      avisos.showSnackBar(SnackBar(content: Text('No se ha guardado: $e')));
    }));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _borrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar este domingo'),
        content: const Text('Se borrarán los datos de este domingo y se recalcularán los fondos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok == true) {
      unawaited(widget.servicio.borrar(widget.fecha));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombreDomingo(widget.fecha);
    final mov = (centimosDeTexto(_recibido.text) ?? 0) -
        (centimosDeTexto(_gastos.text) ?? 0) +
        (centimosDeTexto(_ajuste.text) ?? 0);
    final fondos = widget.fondosPrevios + mov;

    InputDecoration deco(String etiqueta, {String? sufijo, String? ayuda}) =>
        InputDecoration(labelText: etiqueta, suffixText: sufijo, helperText: ayuda);
    const numeros = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("d 'de' MMMM", 'es').format(widget.fecha)),
        actions: [
          if (widget.registro != null)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Borrar', onPressed: _borrar),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_fechaLarga(widget.fecha) + (nombre == null ? '' : '\n$nombre'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          TextField(
            controller: _asistentes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco('Asistentes'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comulgantes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco('Comulgantes'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recibido,
            keyboardType: numeros,
            decoration: deco('Fondos recibidos', sufijo: '€'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gastos,
            keyboardType: numeros,
            decoration: deco('Gastos de la semana', sufijo: '€'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ajuste,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: deco('Ajuste de caja (opcional)',
                sufijo: '€', ayuda: 'Para cuadrar con el dinero real. Puede ser negativo: -5'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Fondos tras este domingo: ${euros(fondos)}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
