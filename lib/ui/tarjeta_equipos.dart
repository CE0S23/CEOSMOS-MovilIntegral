import 'dart:async';

import 'package:flutter/material.dart';

import '../core/alertas_salud.dart';
import '../core/app_state.dart';
import '../core/ble/ble_protocolo.dart';
import '../core/ble/ecosistema_ble.dart';
import 'theme.dart';
import 'widgets.dart';
import '../core/plural.dart';

/// Estado visible de un equipo en la tarjeta.
enum EstadoEquipo { conectado, reconectando, sinConexion }

EstadoEquipo estadoEquipo(EstadoEnlace e) => switch (e) {
  EstadoEnlace.conectado => EstadoEquipo.conectado,
  EstadoEnlace.buscando ||
  EstadoEnlace.conectando ||
  EstadoEnlace.autenticando ||
  EstadoEnlace.reconectando => EstadoEquipo.reconectando,
  EstadoEnlace.desconectado || EstadoEnlace.error => EstadoEquipo.sinConexion,
};

/// «hace 2 s», «hace 3 min», «hace 1 h».
String haceCuanto(DateTime instante, DateTime ahora) {
  final d = ahora.difference(instante);
  if (d.inSeconds < 1) return 'ahora';
  if (d.inSeconds < 60) return 'hace ${d.inSeconds} s';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  return 'hace ${d.inHours} h';
}

String _mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

/// Tarjeta «Tu Reloj y TV» de Inicio (1.4.0): estado de cada equipo, pulso (simulado),
/// pasos, actividad, última lectura, alerta activa y lo que proyecta la TV. Se
/// actualiza en vivo con el ecosistema BLE y un tic de 1 s para «hace N s».
class TarjetaEquipos extends StatefulWidget {
  const TarjetaEquipos({super.key, required this.state, required this.onEquipos, this.ahora});
  final AppState state;
  final VoidCallback onEquipos;

  /// Reloj inyectable para las pruebas.
  final DateTime Function()? ahora;

  @override
  State<TarjetaEquipos> createState() => _TarjetaEquiposState();
}

class _TarjetaEquiposState extends State<TarjetaEquipos> {
  Timer? _tic;
  final _conectando = <RolBle>{};

  @override
  void initState() {
    super.initState();
    _tic = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tic?.cancel();
    super.dispose();
  }

  bool _vinculado(RolBle r) =>
      widget.state.bleVinculado(r) != null || widget.state.ble[r].idCompanero != null;

  Future<void> _conectar(RolBle rol) async {
    setState(() => _conectando.add(rol));
    final r = await widget.state.connectBle(rol);
    if (!mounted) return;
    setState(() => _conectando.remove(rol));
    // Sin PIN guardado (o PIN nuevo en el equipo) se termina en Equipos.
    if (r == ResultadoConexion.requierePin || r == ResultadoConexion.pinIncorrecto) widget.onEquipos();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AnimatedBuilder(
      animation: Listenable.merge([state.ble, state]),
      builder: (context, _) {
        final ahora = (widget.ahora ?? DateTime.now)();
        final hayEquipos = RolBle.values.any(_vinculado);
        return Panel(
          key: const ValueKey('tarjeta-equipos'),
          padding: const EdgeInsets.all(Espacio.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.watch_outlined, color: context.paleta.enlace),
                  const SizedBox(width: Espacio.s),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Tu Reloj y TV', style: context.texto.titleLarge),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espacio.m),
              if (!hayEquipos)
                _Vacio(onEquipos: widget.onEquipos)
              else ...[
                if (state.alertaActiva case final a?) ...[
                  _AlertaActiva(alerta: a, onDescartar: state.descartarAlerta),
                  const SizedBox(height: Espacio.m),
                ],
                LayoutBuilder(
                  builder: (context, c) {
                    final ancho = c.maxWidth >= 640 ? (c.maxWidth - Espacio.l) / 2 : c.maxWidth;
                    return Wrap(
                      spacing: Espacio.l,
                      runSpacing: Espacio.l,
                      children: [
                        SizedBox(width: ancho, child: _bloqueReloj(context, ahora)),
                        SizedBox(width: ancho, child: _bloqueTv(context)),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _bloqueReloj(BuildContext context, DateTime ahora) {
    final state = widget.state;
    final enlace = state.ble[RolBle.reloj];
    final estado = estadoEquipo(enlace.estado);
    final l = state.ble.ultimaLectura;
    final hace = l == null ? null : haceCuanto(l.at, ahora);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cabecera(nombre: 'Reloj', estado: estado),
        const SizedBox(height: Espacio.s),
        if (l == null)
          Text(
            estado == EstadoEquipo.conectado ? 'Esperando la primera lectura…' : 'Sin lecturas todavía.',
            style: context.texto.bodyMedium?.copyWith(color: context.paleta.textoSecundario),
          )
        else
          Semantics(
            key: const ValueKey('lectura-reloj'),
            container: true,
            label: 'Pulso simulado ${l.heartRate} latidos por minuto'
                '${l.steps == null ? '' : ', ${contar(l.steps!, 'paso', 'pasos')}'}'
                ', actividad ${nombreActividad(l.actividad)}, última lectura $hace',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Espacio.s,
                  children: [
                    Icon(Icons.favorite_rounded, color: context.paleta.error, size: 32),
                    Text(
                      '${l.heartRate}',
                      style: context.texto.displaySmall?.copyWith(
                        color: context.paleta.marca,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text('bpm', style: context.texto.titleMedium),
                  ],
                ),
                Text(
                  'Pulso simulado · no es una medición médica',
                  style: context.texto.bodySmall?.copyWith(color: context.paleta.textoSecundario),
                ),
                const SizedBox(height: Espacio.xs),
                Wrap(
                  spacing: Espacio.l,
                  runSpacing: Espacio.xs,
                  children: [
                    _Dato(icono: Icons.directions_walk_rounded, texto: l.steps == null ? '— pasos' : contar(l.steps!, 'paso', 'pasos')),
                    _Dato(icono: Icons.directions_run_rounded, texto: nombreActividad(l.actividad)),
                    _Dato(
                      icono: Icons.schedule_rounded,
                      texto: estado == EstadoEquipo.conectado ? hace! : 'Último dato $hace',
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (estado == EstadoEquipo.sinConexion) ...[
          if (enlace.error case final err?) ...[
            const SizedBox(height: Espacio.s),
            Aviso(err, tipo: TipoAviso.advertencia),
          ],
          const SizedBox(height: Espacio.s),
          _BotonConectar(
            rol: RolBle.reloj,
            ocupado: _conectando.contains(RolBle.reloj),
            onPressed: () => _conectar(RolBle.reloj),
          ),
        ],
      ],
    );
  }

  Widget _bloqueTv(BuildContext context) {
    final state = widget.state;
    final estado = estadoEquipo(state.ble[RolBle.tv].estado);
    final media = state.currentMedia;
    final proyectando = estado == EstadoEquipo.conectado && media != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cabecera(nombre: 'TV', estado: estado),
        const SizedBox(height: Espacio.s),
        if (proyectando)
          ListenableBuilder(
            listenable: state.reloj,
            builder: (context, _) {
              final restante = _mmss(state.remaining.inSeconds);
              return Semantics(
                container: true,
                label: 'La TV proyecta ${media.title}, quedan $restante${state.running ? '' : ', en pausa'}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Dato(icono: Icons.tv_rounded, texto: 'Proyectando'),
                    Text(
                      media.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texto.titleMedium,
                    ),
                    Text(
                      '$restante restantes${state.running ? '' : ' · en pausa'}',
                      style: context.texto.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          Text(
            estado == EstadoEquipo.conectado
                ? 'Sin proyección: inicia una sesión para verla en la TV.'
                : 'La TV mostrará tu sesión cuando esté conectada.',
            style: context.texto.bodyMedium?.copyWith(color: context.paleta.textoSecundario),
          ),
        if (estado == EstadoEquipo.sinConexion) ...[
          if (state.ble[RolBle.tv].error case final err?) ...[
            const SizedBox(height: Espacio.s),
            Aviso(err, tipo: TipoAviso.advertencia),
          ],
          const SizedBox(height: Espacio.s),
          _BotonConectar(
            rol: RolBle.tv,
            ocupado: _conectando.contains(RolBle.tv),
            onPressed: () => _conectar(RolBle.tv),
          ),
        ],
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.nombre, required this.estado});
  final String nombre;
  final EstadoEquipo estado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (texto, color, icono) = switch (estado) {
      EstadoEquipo.conectado => ('Conectado', p.exito, Icons.check_circle_outline),
      EstadoEquipo.reconectando => ('Reconectando', p.advertencia, Icons.sync_rounded),
      EstadoEquipo.sinConexion => ('Sin conexión', p.textoSecundario, Icons.link_off_rounded),
    };
    return Semantics(
      container: true,
      label: '$nombre: $texto',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Espacio.s,
        runSpacing: Espacio.xs,
        children: [
          Text(nombre, style: context.texto.titleMedium),
          Tag(texto, color: color, icon: icono),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});
  final IconData icono;
  final String texto;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 18, color: context.paleta.enlace),
      const SizedBox(width: Espacio.xs),
      Flexible(child: Text(texto, style: context.texto.bodyMedium)),
    ],
  );
}

class _BotonConectar extends StatelessWidget {
  const _BotonConectar({required this.rol, required this.ocupado, required this.onPressed});
  final RolBle rol;
  final bool ocupado;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: ValueKey('conectar-${rol.etiqueta}'),
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    onPressed: ocupado ? null : onPressed,
    icon: ocupado
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.bluetooth_searching_rounded),
    label: Text(ocupado ? 'Conectando…' : 'Conectar', semanticsLabel: 'Conectar ${rol.nombre}'),
  );
}

class _AlertaActiva extends StatelessWidget {
  const _AlertaActiva({required this.alerta, required this.onDescartar});
  final AlertaSalud alerta;
  final VoidCallback onDescartar;
  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = alerta.urgente ? p.error : p.advertencia;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const ValueKey('alerta-activa'),
        padding: const EdgeInsets.all(Espacio.m),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: Radios.bordeL,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Aviso(alerta.texto, tipo: alerta.urgente ? TipoAviso.error : TipoAviso.advertencia),
            Text(
              AlertaSalud.avisoSimulado,
              style: context.texto.bodySmall?.copyWith(color: p.textoSecundario),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onDescartar,
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.onEquipos});
  final VoidCallback onEquipos;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Aún no vinculas tu Reloj ni tu TV. Conéctalos para ver tu pulso, tus pasos y tu sesión en pantalla grande.',
        style: context.texto.bodyMedium?.copyWith(color: context.paleta.textoSecundario),
      ),
      const SizedBox(height: Espacio.m),
      FilledButton.icon(
        key: const ValueKey('ir-equipos'),
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: onEquipos,
        icon: const Icon(Icons.devices_other_outlined),
        label: const Text('Ir a Equipos'),
      ),
    ],
  );
}
