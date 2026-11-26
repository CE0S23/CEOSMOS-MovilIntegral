import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_state.dart';
import 'core/sound_controller.dart';
import 'domain/models.dart';
import 'ui/alertas_ui.dart';
import 'ui/auth_screen.dart';
import 'ui/home_screen.dart';
import 'ui/explore_screen.dart';
import 'ui/session_screen.dart';
import 'ui/devices_screen.dart';
import 'ui/profile_screen.dart';
import 'ui/funciones.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class CeosmosApp extends StatefulWidget {
  const CeosmosApp({super.key, this.state});
  final AppState? state;
  @override
  State<CeosmosApp> createState() => _CeosmosAppState();
}

class _CeosmosAppState extends State<CeosmosApp> {
  late final AppState _state = widget.state ?? AppState.production();

  @override
  void initState() {
    super.initState();
    if (widget.state == null) _state.restore();
  }

  @override
  void dispose() {
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CEOSMOS · Tu espacio de enfoque',
    debugShowCheckedModeBanner: false,
    theme: CeosmosTema.claro,
    darkTheme: CeosmosTema.oscuro,
    themeMode: ThemeMode.system,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ListenableBuilder(
      listenable: _state,
      builder: (context, _) => switch (_state.status) {
        AuthStatus.restoring => const _Arranque(),
        AuthStatus.signedOut => AuthScreen(state: _state),
        AuthStatus.signedIn => AppShell(
          key: ValueKey(_state.user!.id),
          state: _state,
        ),
      },
    ),
  );
}

/// Pestaña inicial desde la URL de la PWA (atajos del manifiesto:
/// `?pestana=explorar`, `?pestana=equipos`). Fuera de la web o sin parámetro: Inicio.
int pestanaDesdeUrl(Uri? url) {
  const nombres = ['inicio', 'explorar', 'sesion', 'equipos', 'soporte', 'perfil'];
  final i = nombres.indexOf(url?.queryParameters['pestana']?.toLowerCase() ?? '');
  return i < 0 ? 0 : i;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final _sound = SoundController();
  final _scroll = ScrollController();
  int _tab = 0, _exploreVersion = 0;
  FocusMode? _mode;
  bool _favorites = false;
  bool _previousSession = false, _previousRunning = false;
  String? _previousMedia;
  static const _labels = [
    'Inicio',
    'Explorar',
    'Mi sesión',
    'Equipos', // «Dispositivos» no cabe con 6 pestañas en 360 dp
    'Soporte',
    'Perfil',
  ];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.explore_outlined,
    Icons.timelapse_rounded,
    Icons.devices_other_outlined,
    Icons.support_agent_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tab = pestanaDesdeUrl(kIsWeb ? Uri.base : null);
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    final s = widget.state;
    // También cubre la pausa, el fin o el cambio de ambiente pedidos desde el
    // reloj o la TV por BLE (no pasan por los botones de esta pantalla).
    if ((_previousSession && !s.hasSession) ||
        (_previousRunning && s.hasSession && !s.running) ||
        (_previousMedia != null && s.currentMedia?.id != _previousMedia)) {
      unawaited(_sound.stop());
    }
    _previousSession = s.hasSession;
    _previousRunning = s.running;
    _previousMedia = s.currentMedia?.id;
    final alerta = widget.state.tomarAlertaNueva();
    if (alerta != null && mounted && widget.state.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) mostrarAvisoAlerta(context, alerta);
      });
    }
    final aviso = widget.state.notice;
    // Si la sesión terminó, el aviso lo muestra la pantalla de acceso.
    if (aviso != null && mounted && widget.state.user != null) {
      widget.state.takeNotice();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(aviso)));
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Audio en segundo plano: la sesión y su ambiente siguen sonando con la
    // pantalla apagada; solo se detiene si el sistema cierra la app.
    if (state == AppLifecycleState.detached) unawaited(_sound.stop());
    if (state == AppLifecycleState.resumed) widget.state.tick();
  }

  @override
  void dispose() {
    widget.state.removeListener(_sessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _sound.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _navigate(int tab) {
    setState(() => _tab = tab);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _explore(FocusMode? mode, {bool favorites = false}) {
    setState(() {
      _mode = mode;
      _favorites = favorites;
      _exploreVersion++;
    });
    _navigate(1);
  }

  Future<void> _open(MediaItem item) async {
    var minutes =
        sessionMinutes.contains(widget.state.workspace.preferredMinutes)
        ? widget.state.workspace.preferredMinutes
        : 25;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CosmosScene(
                    scene: item.scene,
                    height: 160,
                    child: const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: Espacio.xl),
                  Text(
                    item.title,
                    style: context.texto.headlineMedium?.copyWith(
                      color: context.paleta.marca,
                    ),
                  ),
                  const SizedBox(height: Espacio.s - 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(color: context.paleta.textoSecundario),
                  ),
                  const SizedBox(height: Espacio.xl),
                  Text(
                    '¿Cuánto tiempo quieres dedicarte?',
                    style: context.texto.titleSmall,
                  ),
                  const SizedBox(height: Espacio.m),
                  Wrap(
                    spacing: Espacio.s + 2,
                    runSpacing: Espacio.s,
                    children: sessionMinutes
                        .map(
                          (value) => ChoiceChip(
                            label: Text('$value min'),
                            selected: value == minutes,
                            onSelected: (_) =>
                                setSheetState(() => minutes = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  if (widget.state.hasSession)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Espacio.m + 2),
                      child: Aviso(
                        'Al comenzar, tu sesión actual se guardará como finalizada.',
                        tipo: TipoAviso.advertencia,
                        style: context.texto.bodySmall,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, minutes),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Comenzar sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted || widget.state.user == null) return;
    await _sound.stop();
    if (!mounted || widget.state.user == null) return;
    widget.state.startSession(item, selected);
    _navigate(2);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final barraFija = MediaQuery.sizeOf(context).height >= 480;
    final content = switch (_tab) {
      0 => HomeScreen(state: state, onExplore: _explore, onOpen: _open, onEquipos: () => _navigate(3)),
      1 => ExploreScreen(
        key: ValueKey(_exploreVersion),
        state: state,
        onOpen: _open,
        initialMode: _mode,
        onlyFavorites: _favorites,
      ),
      2 => SessionScreen(
        state: state,
        sound: _sound,
        onExplore: () => _explore(null),
      ),
      3 => DevicesScreen(state: state),
      4 => const SoporteScreen(),
      _ => ProfileScreen(
        state: state,
        onFavorites: () => _explore(null, favorites: true),
        onLogout: () async {
          await _sound.stop();
          await state.signOut();
        },
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Container(
                width: 228,
                decoration: BoxDecoration(
                  color: context.paleta.superficie,
                  border: Border(
                    right: BorderSide(color: context.paleta.borde),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Espacio.l + 2,
                  vertical: Espacio.xxl - 2,
                ),
                // Ventanas anchas pero bajas (ventana flotante apaisada, pantalla
                // dividida): la barra lateral se desplaza en lugar de desbordarse.
                child: LayoutBuilder(
                  builder: (context, caja) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: caja.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: Espacio.s),
                              child: Brand(),
                            ),
                            const SizedBox(height: Espacio.xxl + Espacio.l),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: Espacio.l,
                                bottom: Espacio.l,
                              ),
                              child: Text(
                                'MI UNIVERSO',
                                style: context.texto.labelSmall?.copyWith(
                                  color: context.paleta.textoSecundario,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                            ...List.generate(
                              _labels.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Espacio.s,
                                ),
                                child: ListTile(
                                  selected: i == _tab,
                                  leading: Icon(_icons[i], size: 21),
                                  iconColor: context.paleta.textoSecundario,
                                  title: Text(
                                    _labels[i],
                                    style: context.texto.labelLarge?.copyWith(
                                      fontWeight: i == _tab
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () => _navigate(i),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Panel(
                              padding: const EdgeInsets.all(Espacio.l),
                              color: context.paleta.cianSuave,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.nightlight_outlined,
                                    color: context.paleta.enlace,
                                  ),
                                  const SizedBox(height: Espacio.m),
                                  Text(
                                    'Haz espacio para ti.',
                                    style: context.texto.titleSmall,
                                  ),
                                  const SizedBox(height: Espacio.s - 2),
                                  Text(
                                    'Un momento de calma también es un avance.',
                                    style: context.texto.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Espacio.xl),
                            Padding(
                              padding: const EdgeInsets.only(left: Espacio.s),
                              child: Text(
                                'MÓVIL INTEGRAL',
                                style: context.texto.labelSmall?.copyWith(
                                  color: context.paleta.textoSecundario,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 38 : 22,
                      vertical: Espacio.l,
                    ),
                    decoration: BoxDecoration(
                      color: context.paleta.fondo,
                      border: Border(
                        bottom: BorderSide(color: context.paleta.borde),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!wide)
                          // Ventanas angostas (< 340 dp, p. ej. ventana flotante):
                          // solo el ícono, para que el avatar siga visible.
                          // Flexible: con la fuente del sistema al 200 % la marca se encoge en lugar de desbordarse.
                          // Expanded + Align: el avatar queda siempre al borde derecho (con
                          // Flexible + Spacer quedaba a media barra en teléfonos anchos y tabletas).
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Brand(
                                compact: MediaQuery.sizeOf(context).width < 340,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Tu espacio / ${_labels[_tab]}',
                            style: context.texto.labelMedium?.copyWith(
                              color: context.paleta.textoSecundario,
                            ),
                          ),
                        if (wide) const Spacer(),
                        if (state.user!.isAdmin) ...[
                          // Insignia de rol: ámbar con texto guinda.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Espacio.m,
                              vertical: Espacio.xs + 1,
                            ),
                            decoration: BoxDecoration(
                              color: context.paleta.acento,
                              borderRadius: BorderRadius.circular(
                                Radios.pildora,
                              ),
                            ),
                            child: Text(
                              'ADMIN',
                              style: context.texto.labelSmall?.copyWith(
                                color: context.paleta.sobreAcento,
                              ),
                            ),
                          ),
                          const SizedBox(width: Espacio.m),
                        ],
                        Tooltip(
                          message: 'Ver mi perfil',
                          // Área táctil de 48 × 48 dp (accesibilidad); el avatar sigue de 36.
                          child: InkWell(
                            onTap: () => _navigate(5),
                            customBorder: const CircleBorder(),
                            child: SizedBox.square(
                              dimension: 48,
                              child: Center(
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: context.paleta.marca,
                                  foregroundColor: context.paleta.sobreMarca,
                                  child: Text(
                                    state.user!.username.characters.first
                                        .toUpperCase(),
                                    style: context.texto.titleSmall?.copyWith(
                                      color: context.paleta.sobreMarca,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: EdgeInsets.all(wide ? 38 : 22),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1060),
                          // 1.4.0: en ventanas muy bajas (< 480 dp, p. ej. ventana flotante)
                          // la barra de sesión fija no cabía junto a la cabecera y la
                          // navegación; ahí va dentro del área desplazable.
                          child: barraFija || !(state.hasSession && _tab != 2)
                              ? content
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _SessionBar(
                                      state: state,
                                      onTap: () => _navigate(2),
                                      onPause: () {
                                        state.togglePause();
                                        if (!state.running) _sound.stop();
                                      },
                                    ),
                                    const SizedBox(height: Espacio.l),
                                    content,
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (barraFija && state.hasSession && _tab != 2)
                    _SessionBar(
                      state: state,
                      onTap: () => _navigate(2),
                      onPause: () {
                        state.togglePause();
                        if (!state.running) _sound.stop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _navigate,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: List.generate(
                _labels.length,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i]),
                  label: _labels[i],
                ),
              ),
            ),
    );
  }
}

class _SessionBar extends StatelessWidget {
  const _SessionBar({
    required this.state,
    required this.onTap,
    required this.onPause,
  });
  final AppState state;
  final VoidCallback onTap, onPause;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // 1.4.0: en anchos muy chicos (ventana flotante) se omite el ícono del modo.
    builder: (context, c) => _barra(context, compacta: c.maxWidth < 300),
  );

  Widget _barra(BuildContext context, {required bool compacta}) => Material(
    // Barra de sesión en guinda: texto blanco y acentos cian.
    color: CeosmosColores.guinda,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compacta ? Espacio.s : Espacio.l + 4,
          vertical: Espacio.s,
        ),
        child: Row(
          children: [
            if (!compacta) ...[
              Icon(
                modeIcon(state.currentMedia!.mode),
                color: CeosmosColores.cian,
              ),
              const SizedBox(width: Espacio.m + 2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentMedia!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texto.titleSmall?.copyWith(
                      color: CeosmosColores.blanco,
                    ),
                  ),
                  Text(
                    state.running ? 'Sesión en curso' : 'En pausa',
                    style: context.texto.bodySmall?.copyWith(
                      color: CeosmosColores.guindaClaro,
                    ),
                  ),
                ],
              ),
            ),
            // P12-O2: solo este texto se redibuja con el tic de cada segundo.
            ListenableBuilder(
              listenable: state.reloj,
              builder: (context, _) => Text(
                clockLabel(state.remaining),
                style: context.texto.titleLarge?.copyWith(
                  color: CeosmosColores.cian,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(width: compacta ? Espacio.xs : Espacio.s + 2),
            IconButton(
              onPressed: onPause,
              tooltip: state.running ? 'Pausar sesión' : 'Continuar sesión',
              color: CeosmosColores.blanco,
              icon: Icon(state.running ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pantalla breve mientras se valida la sesión guardada con la API.
class _Arranque extends StatelessWidget {
  const _Arranque();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        // Splash: el patrón de curvas de la paleta, sin texto encima.
        const Expanded(child: CurvasCeosmos(radio: 0)),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Brand(),
                const SizedBox(height: Espacio.xxl - 4),
                const CircularProgressIndicator(),
                const SizedBox(height: Espacio.l),
                Text(
                  'Conectando con CEOSMOS…',
                  style: TextStyle(color: context.paleta.textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
