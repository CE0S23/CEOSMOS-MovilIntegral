import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/sound_controller.dart';
import 'theme.dart';
import 'widgets.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({
    super.key,
    required this.state,
    required this.sound,
    required this.onExplore,
  });
  final AppState state;
  final SoundController sound;
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) {
    final item = state.currentMedia;
    if (item == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading('Tu sesión', 'Un espacio para estar presente.'),
          EmptyState(
            icon: Icons.timelapse_rounded,
            title: 'Todo empieza con una pausa',
            message:
                'Elige un ambiente y dedica unos minutos a ti.\nTus sesiones terminadas aparecerán en tu perfil.',
            action: FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Elegir mi ambiente'),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Este momento es tuyo',
          'Deja que lo demás espere un poco.',
        ),
        CosmosScene(
          scene: item.scene,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Espacio.l + 4,
              vertical: Espacio.xxl,
            ),
            // Velo de tinta: todo el texto de la escena es claro.
            color: CeosmosColores.tinta.withValues(alpha: .35),
            child: Column(
              children: [
                Tag(
                  item.mode.label,
                  color: CeosmosColores.cian,
                  icon: modeIcon(item.mode),
                ),
                const SizedBox(height: Espacio.l + 2),
                Text(
                  item.title,
                  style: context.texto.headlineSmall?.copyWith(
                    color: CeosmosColores.blanco,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Espacio.xxl - 2),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // P12-O2: solo el anillo y el reloj escuchan el tic de cada segundo.
                      SizedBox.expand(
                        child: ListenableBuilder(
                          listenable: state.reloj,
                          builder: (context, _) => CircularProgressIndicator(
                            value: state.progress,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            backgroundColor: CeosmosColores.blanco.withValues(
                              alpha: .16,
                            ),
                            color: CeosmosColores.cian,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListenableBuilder(
                            listenable: state.reloj,
                            builder: (context, _) => Text(
                              clockLabel(state.remaining),
                              style: context.texto.displayLarge?.copyWith(
                                color: CeosmosColores.blanco,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: Espacio.s),
                          Text(
                            state.running
                                ? 'RESPIRA. ESTÁS AQUÍ.'
                                : 'A TU RITMO · EN PAUSA',
                            style: context.texto.labelSmall?.copyWith(
                              color: CeosmosColores.cianClaro,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espacio.xxl - 2),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Espacio.m,
                  runSpacing: Espacio.m,
                  children: [
                    FilledButton.icon(
                      // Sobre la escena: cian con texto guinda.
                      style: FilledButton.styleFrom(
                        backgroundColor: CeosmosColores.cian,
                        foregroundColor: CeosmosColores.guinda,
                      ),
                      onPressed: () {
                        state.togglePause();
                        if (!state.running) sound.stop();
                      },
                      icon: Icon(
                        state.running ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(
                        state.running ? 'Pausar sesión' : 'Continuar sesión',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final finish = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('¿Terminar esta sesión?'),
                            content: const Text(
                              'El tiempo que dedicaste se guardará en tu historial.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Seguir aquí'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Terminar'),
                              ),
                            ],
                          ),
                        );
                        if (finish == true && state.hasSession) {
                          await sound.stop();
                          state.finishSession();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: CeosmosColores.blanco,
                        side: BorderSide(
                          color: CeosmosColores.blanco.withValues(alpha: .6),
                        ),
                      ),
                      child: const Text('Terminar sesión'),
                    ),
                  ],
                ),
                const SizedBox(height: Espacio.l + 2),
                Text(
                  'Objetivo: ${state.targetMinutes} minutos',
                  style: context.texto.bodySmall?.copyWith(
                    color: CeosmosColores.guindaClaro,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espacio.l + 4),
        if (item.audioAsset != null)
          ListenableBuilder(
            listenable: sound,
            builder: (context, _) => Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.headphones_outlined,
                        color: context.paleta.enlace,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu ambiente sonoro',
                              style: context.texto.titleSmall,
                            ),
                            Text(
                              'Audio incluido · Sigue sonando en segundo plano',
                              style: context.texto.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: sound.busy || !state.running
                            ? null
                            : () => sound.toggle(item.audioAsset!),
                        tooltip: sound.playing
                            ? 'Silenciar ambiente'
                            : 'Reproducir ambiente',
                        icon: Icon(
                          sound.playing ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.volume_down_outlined,
                        color: context.paleta.textoSecundario,
                        size: 18,
                      ),
                      Expanded(
                        child: Slider(
                          value: sound.volume,
                          onChanged: (v) => sound.setVolume(v),
                          semanticFormatterCallback: (v) =>
                              'Volumen ${(v * 100).round()} por ciento',
                        ),
                      ),
                      Text(
                        '${(sound.volume * 100).round()}%',
                        style: context.texto.bodySmall,
                      ),
                    ],
                  ),
                  if (sound.error != null) Aviso(sound.error!),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Si pausas la sesión, el audio se detiene. Puedes volver a activarlo al continuar.',
          style: context.texto.bodySmall,
        ),
      ],
    );
  }
}
