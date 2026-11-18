import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_state.dart';
import 'core/sound_controller.dart';
import 'domain/models.dart';
import 'ui/auth_screen.dart';
import 'ui/home_screen.dart';
import 'ui/explore_screen.dart';
import 'ui/session_screen.dart';
import 'ui/devices_screen.dart';
import 'ui/profile_screen.dart';
import 'practicas/practicas_screen.dart';
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
    theme: Cosmos.theme,
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
    'Prácticas',
    'Perfil',
  ];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.explore_outlined,
    Icons.timelapse_rounded,
    Icons.devices_other_outlined,
    Icons.science_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
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
    final aviso = widget.state.notice;
    // Si la sesión terminó, el aviso lo muestra la pantalla de acceso.
    if (aviso != null && mounted && widget.state.user != null) {
      widget.state.takeNotice();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
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
    var minutes = sessionMinutes.contains(widget.state.workspace.preferredMinutes)
        ? widget.state.workspace.preferredMinutes
        : 25;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Cosmos.surface,
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
                  const SizedBox(height: 22),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: const TextStyle(color: Cosmos.muted),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '¿Cuánto tiempo quieres dedicarte?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
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
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Al comenzar, tu sesión actual se guardará como finalizada.',
                        style: TextStyle(color: Cosmos.peach, fontSize: 12),
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
    final content = switch (_tab) {
      0 => HomeScreen(state: state, onExplore: _explore, onOpen: _open),
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
      4 => const PracticasScreen(),
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
                decoration: const BoxDecoration(
                  color: Cosmos.surface,
                  border: Border(right: BorderSide(color: Cosmos.border)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Brand(),
                    ),
                    const SizedBox(height: 48),
                    const Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 16),
                      child: Text(
                        'MI UNIVERSO',
                        style: TextStyle(
                          color: Cosmos.muted,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    ...List.generate(
                      _labels.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          selected: i == _tab,
                          selectedColor: Cosmos.lavender,
                          selectedTileColor: Cosmos.lavender.withValues(
                            alpha: .1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(_icons[i], size: 21),
                          title: Text(
                            _labels[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _navigate(i),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Panel(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.nightlight_outlined,
                            color: Cosmos.lavender,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Haz espacio para ti.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Un momento de calma también es un avance.',
                            style: TextStyle(fontSize: 12, color: Cosmos.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'MÓVIL INTEGRAL',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: Cosmos.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 38 : 22,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Cosmos.border)),
                    ),
                    child: Row(
                      children: [
                        if (!wide)
                          const Brand()
                        else
                          Text(
                            'Tu espacio / ${_labels[_tab]}',
                            style: const TextStyle(
                              color: Cosmos.muted,
                              fontSize: 13,
                            ),
                          ),
                        const Spacer(),
                        if (state.user!.isAdmin) ...[
                          const Tag('ADMIN', color: Cosmos.peach),
                          const SizedBox(width: 12),
                        ],
                        Tooltip(
                          message: 'Ver mi perfil',
                          child: InkWell(
                            onTap: () => _navigate(5),
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Cosmos.elevated,
                              foregroundColor: Cosmos.lavender,
                              child: Text(
                                state.user!.username.characters.first
                                    .toUpperCase(),
                                style: const TextStyle(fontSize: 14),
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
                          child: content,
                        ),
                      ),
                    ),
                  ),
                  if (state.hasSession && _tab != 2)
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
  Widget build(BuildContext context) => Material(
    color: Cosmos.elevated,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(modeIcon(state.currentMedia!.mode), color: Cosmos.lavender),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentMedia!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    state.running ? 'Sesión en curso' : 'En pausa',
                    style: const TextStyle(color: Cosmos.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            // P12-O2: solo este texto se redibuja con el tic de cada segundo.
            ListenableBuilder(
              listenable: state.reloj,
              builder: (context, _) => Text(
                clockLabel(state.remaining),
                style: const TextStyle(color: Cosmos.lavender),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onPause,
              tooltip: state.running ? 'Pausar sesión' : 'Continuar sesión',
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
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Brand(),
          SizedBox(height: 28),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Conectando con CEOSMOS…', style: TextStyle(color: Cosmos.muted)),
        ],
      ),
    ),
  );
}
