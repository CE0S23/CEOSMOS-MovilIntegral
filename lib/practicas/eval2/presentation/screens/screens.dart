import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/api_client.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../state/app_state.dart';

final _fmt = DateFormat('dd/MM/yyyy HH:mm');

// ---------------- Login ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final name = await AppState.auth.login(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(userName: name)));
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 48),
          Icon(Icons.local_hospital_outlined, size: 56, color: c.primary),
          const SizedBox(height: 12),
          Text('MediConnect', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const Text('Inicia sesión para consultar y agendar tus citas', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _pass, obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          if (_error != null)
            Card(color: c.errorContainer, child: Padding(padding: const EdgeInsets.all(12),
                child: Row(children: [Icon(Icons.error_outline, color: c.onErrorContainer), const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: c.onErrorContainer)))]))),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Iniciar sesión'),
          ),
        ]),
      ),
    );
  }
}

// ---------------- Home ----------------
class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const AppointmentsScreen(),
      const ScheduleScreen(),
      const HealthInfoScreen(),
      if (AppConfig.labMode) const LabScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Hola, ${widget.userName}'), actions: [
        IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () async {
          await AppState.auth.logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }),
      ]),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Mis citas'),
          const NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Agendar'),
          const NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Salud'),
          if (AppConfig.labMode) const NavigationDestination(icon: Icon(Icons.science_outlined), label: 'Laboratorio'),
        ],
      ),
    );
  }
}

// ---------------- Mis citas ----------------
class AppointmentsScreen extends StatefulWidget {
  final String? path; // solo el laboratorio la cambia (PV-05)
  final String? title;
  const AppointmentsScreen({super.key, this.path, this.title});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  ViewStatus _status = ViewStatus.loading;
  AppointmentPage? _page;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = ViewStatus.loading);
    try {
      final p = widget.path == null
          ? await AppState.appointments.myAppointments()
          : await AppState.appointments.myAppointments(path: widget.path!);
      setState(() { _page = p; _status = p.items.isEmpty ? ViewStatus.empty : ViewStatus.data; });
    } on AppFailure catch (e) {
      setState(() { _error = e.message; _status = ViewStatus.error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_status == ViewStatus.loading) const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
        if (_status == ViewStatus.empty) const _Message(Icons.event_busy, 'Aún no tienes citas registradas.'),
        if (_status == ViewStatus.error) _Message(Icons.cloud_off, _error!, onRetry: _load),
        if (_status == ViewStatus.data) ...[
          for (final a in _page!.items)
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
              title: Text(a.doctor),
              subtitle: Text('${a.specialty}\n${_fmt.format(a.date)} · ${a.id}'),
              isThreeLine: true,
              trailing: Chip(label: Text(a.status == 'CONFIRMED' ? 'Confirmada' : a.status)),
            )),
          if (_page!.omitted > 0)
            Padding(padding: const EdgeInsets.only(top: 8),
                child: Text('${_page!.omitted} registro(s) con formato inválido se omitieron.',
                    style: Theme.of(context).textTheme.bodySmall)),
        ],
      ]),
    );
    if (widget.title == null) return body;
    return Scaffold(appBar: AppBar(title: Text(widget.title!)), body: body);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _Message(this.icon, this.text, {this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      );
}

// ---------------- Agendar ----------------
const _slots = [
  '2026-11-15T10:30:00-06:00',
  '2026-11-18T09:00:00-06:00',
  '2026-11-18T12:00:00-06:00',
  '2026-11-25T16:30:00-06:00',
];

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  List<Doctor> _doctors = [];
  String? _doctor;
  String? _slot;
  bool _sending = false;
  String? _error;
  Map? _created;
  String? _replay;
  // Se genera al abrir el formulario y se reutiliza si el usuario reintenta.
  String _idempotencyKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    AppState.appointments.doctors().then((d) => setState(() => _doctors = d)).catchError((_) {});
  }

  Future<void> _submit({bool replay = false}) async {
    if (!replay && !_form.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });
    try {
      final r = await AppState.appointments.create(_doctor!, _slot!, _reason.text.trim(), _idempotencyKey);
      setState(() {
        if (replay) {
          _replay = 'Respuesta repetida: ${r['appointment_id']} (misma cita, no se duplicó).';
        } else {
          _created = r;
        }
      });
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _sending = false);
    }
  }

  void _reset() => setState(() {
        _created = null; _replay = null; _error = null; _idempotencyKey = const Uuid().v4();
      });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    if (_created != null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        Icon(Icons.check_circle, color: c.primary, size: 64),
        const SizedBox(height: 12),
        Text('Cita agendada', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Folio: ${_created!['appointment_id']}'),
          Text('Médico: ${_created!['doctor']}'),
          Text('Fecha: ${_fmt.format(DateTime.parse(_created!['date']).toLocal())}'),
          Text('Estado: ${_created!['status'] == 'CONFIRMED' ? 'Confirmada' : _created!['status']}'),
        ]))),
        const SizedBox(height: 8),
        Text('Idempotency-Key: $_idempotencyKey', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        if (AppConfig.labMode)
          OutlinedButton.icon(onPressed: _sending ? null : () => _submit(replay: true), icon: const Icon(Icons.replay),
              label: const Text('Volver a agendar con la misma Idempotency-Key')),
        if (_replay != null) Card(color: c.secondaryContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_replay!))),
        const SizedBox(height: 8),
        FilledButton(onPressed: _reset, child: const Text('Agendar otra cita')),
      ]);
    }
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Agendar cita', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _doctor,
          decoration: const InputDecoration(labelText: 'Médico', border: OutlineInputBorder()),
          items: [for (final d in _doctors) DropdownMenuItem(value: d.id, child: Text('${d.name} · ${d.specialty}'))],
          onChanged: (v) => setState(() => _doctor = v),
          validator: (v) => v == null ? 'Selecciona un médico' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _slot,
          decoration: const InputDecoration(labelText: 'Fecha y hora', border: OutlineInputBorder()),
          items: [for (final s in _slots) DropdownMenuItem(value: s, child: Text(_fmt.format(DateTime.parse(s).toLocal())))],
          onChanged: (v) => setState(() => _slot = v),
          validator: (v) => v == null ? 'Selecciona fecha y hora' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reason,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motivo de la consulta', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el motivo' : null,
        ),
        if (_error != null)
          Card(color: c.errorContainer, child: Padding(padding: const EdgeInsets.all(12),
              child: Row(children: [Icon(Icons.error_outline, color: c.onErrorContainer), const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: c.onErrorContainer)))]))),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Agendar'),
        ),
      ]),
    );
  }
}

// ---------------- Informacion de salud ----------------
class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});
  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  ViewStatus _status = ViewStatus.loading;
  HealthInfo? _info;
  int _ms = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = ViewStatus.loading);
    final sw = Stopwatch()..start();
    try {
      final i = await AppState.healthInfo.fetch();
      setState(() { _info = i; _status = i.degraded ? ViewStatus.degraded : ViewStatus.data; });
    } on AppFailure {
      setState(() => _status = ViewStatus.error);
    }
    _ms = sw.elapsedMilliseconds;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Información de salud', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_status == ViewStatus.loading) const Center(child: CircularProgressIndicator()),
        if (_status == ViewStatus.degraded || _status == ViewStatus.error)
          Card(color: c.surfaceContainerHighest, child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Información no disponible por el momento'),
            subtitle: Text(_info?.message ?? 'Tus citas siguen disponibles con normalidad.'),
          )),
        if (_info?.clinicStatus != null)
          Card(child: ListTile(leading: const Icon(Icons.store_mall_directory_outlined), title: Text(_info!.clinicStatus!),
              subtitle: _status == ViewStatus.degraded ? const Text('Último dato guardado') : null)),
        for (final t in _info?.tips ?? <MapEntry<String, String>>[])
          Card(child: ListTile(leading: const Icon(Icons.tips_and_updates_outlined), title: Text(t.key), subtitle: Text(t.value))),
        if (_status != ViewStatus.loading)
          Padding(padding: const EdgeInsets.only(top: 12),
              child: Text('Tiempo de respuesta: $_ms ms', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}

// ---------------- Laboratorio de pruebas ----------------
class LabScreen extends StatefulWidget {
  const LabScreen({super.key});
  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  String _title = 'Selecciona una prueba';
  String _result = '';
  bool _busy = false;

  Future<void> _run(String title, Future<String> Function() f) async {
    setState(() { _busy = true; _title = title; _result = 'Ejecutando…'; });
    final r = await f();
    setState(() { _busy = false; _result = r; });
  }

  LabRepository _withClient({String? baseUrl, String? pem, bool noToken = false}) {
    final api = ApiClient(AppState.storage, baseUrl: baseUrl, pinnedPem: pem);
    if (noToken) api.dio.options.headers['Authorization'] = 'Bearer ';
    return LabRepository(api);
  }

  @override
  Widget build(BuildContext context) {
    final lab = AppState.lab;
    Widget btn(String label, Future<String> Function() f) =>
        OutlinedButton(onPressed: _busy ? null : () => _run(label, f), child: Text(label));
    Widget section(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SelectableText(_result, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ])),
      ),
      section('PV-01 · Acceso a datos de otro paciente'),
      Wrap(spacing: 8, children: [
        btn('Pedir cita de otro paciente (APT-3001)', () => lab.raw('GET', '/appointments/APT-3001')),
        btn('Pedir mis citas sin token', () => _withClient(noToken: true).raw('GET', '/appointments/me')),
        btn('Ver auditoría', () => lab.raw('GET', '/lab/audit-log')),
      ]),
      section('PV-02 · Protección de la comunicación'),
      Wrap(spacing: 8, children: [
        btn('Intentar conexión por HTTP',
            () => _withClient(baseUrl: AppConfig.apiBaseUrl.replaceFirst('https://', 'http://')).raw('GET', '/appointments/me')),
        btn('Intentar con pin incorrecto', () => _withClient(pem: AppConfig.wrongCertPem).raw('GET', '/appointments/me')),
      ]),
      section('PV-04 · Caída de la API de terceros'),
      Wrap(spacing: 8, children: [
        btn('Proveedor lento', () => lab.raw('POST', '/lab/provider-mode', data: {'mode': 'slow'})),
        btn('Proveedor caído', () => lab.raw('POST', '/lab/provider-mode', data: {'mode': 'error'})),
        btn('Proveedor normal', () => lab.raw('POST', '/lab/provider-mode', data: {'mode': 'ok'})),
        btn('Consultar información de salud', () => lab.raw('GET', '/health-info')),
        btn('Ver estado del circuito', () => lab.raw('GET', '/lab/breaker-status')),
      ]),
      section('PV-05 · Respuestas con datos incorrectos'),
      Wrap(spacing: 8, children: [
        OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
            const AppointmentsScreen(path: '/lab/malformed-appointments?variant=string', title: 'PV-05 · Lista como texto'))),
            child: const Text('Lista como texto')),
        OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
            const AppointmentsScreen(path: '/lab/malformed-appointments?variant=missing-date', title: 'PV-05 · Cita sin fecha'))),
            child: const Text('Cita sin fecha')),
      ]),
    ]);
  }
}
