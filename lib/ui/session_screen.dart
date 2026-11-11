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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            color: Cosmos.background.withValues(alpha: .3),
            child: Column(
              children: [
                Tag(
                  item.mode.label,
                  color: modeColor(item.mode),
                  icon: modeIcon(item.mode),
                ),
                const SizedBox(height: 18),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: state.progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withValues(alpha: .14),
                          color: modeColor(item.mode),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            clockLabel(state.remaining),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.running
                                ? 'RESPIRA. ESTÁS AQUÍ.'
                                : 'A TU RITMO · EN PAUSA',
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
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
                              'El tiempo que dedicaste se guardará en tu historial local.',
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
                      child: const Text('Terminar sesión'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Objetivo: ${state.targetMinutes} minutos',
                  style: const TextStyle(color: Cosmos.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (item.audioAsset != null)
          ListenableBuilder(
            listenable: sound,
            builder: (context, _) => Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.headphones_outlined,
                        color: Cosmos.lavender,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu ambiente sonoro',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Audio local · Repetición continua',
                              style: TextStyle(
                                color: Cosmos.muted,
                                fontSize: 12,
                              ),
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
                      const Icon(
                        Icons.volume_down_outlined,
                        color: Cosmos.muted,
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
                        style: const TextStyle(
                          color: Cosmos.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (sound.error != null)
                    Text(
                      sound.error!,
                      style: const TextStyle(color: Cosmos.peach),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Si pausas la sesión, el audio se detiene. Puedes volver a activarlo al continuar.',
          style: TextStyle(color: Cosmos.muted, fontSize: 12),
        ),
      ],
    );
  }
}
