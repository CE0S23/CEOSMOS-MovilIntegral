import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'registro_practicas.dart';

const _canal = MethodChannel('ceosmos/practicas');

/// Abre una práctica: las Flutter en una ruta propia de CEOSMOS y las nativas
/// como actividad Android incluida en el APK.
Future<void> abrirPractica(BuildContext context, Practica practica) async {
  if (practica.tipo == TipoPractica.nativa) {
    try {
      await _canal.invokeMethod<bool>('abrirNativa', {
        'id': practica.id,
        'titulo': '${practica.numero} · ${practica.titulo}',
      });
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir la práctica: ${e.message}')),
        );
      }
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta práctica nativa solo se ejecuta en Android.'),
          ),
        );
      }
    }
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PracticaHost(practica: practica),
      settings: RouteSettings(name: '/practicas/${practica.id}'),
    ),
  );
}

/// Contenedor de una práctica Flutter: barra «← Prácticas» y debajo la app de
/// la práctica con su propio MaterialApp (Navigator, tema y estado propios).
class PracticaHost extends StatefulWidget {
  const PracticaHost({super.key, required this.practica});
  final Practica practica;

  @override
  State<PracticaHost> createState() => _PracticaHostState();
}

class _PracticaHostState extends State<PracticaHost> {
  final _zona = GlobalKey();

  /// Navigator interno de la práctica (el del MaterialApp de la práctica).
  NavigatorState? _navegadorInterno() {
    NavigatorState? encontrado;
    void visitar(Element e) {
      if (encontrado != null) return;
      if (e is StatefulElement && e.state is NavigatorState) {
        encontrado = e.state as NavigatorState;
        return;
      }
      e.visitChildElements(visitar);
    }

    final raiz = _zona.currentContext as Element?;
    raiz?.visitChildElements(visitar);
    return encontrado;
  }

  /// El botón Atrás de Android llega primero al Navigator de CEOSMOS: se
  /// reenvía a la práctica y solo se sale cuando ella ya no puede retroceder.
  Future<void> _atras() async {
    final interno = _navegadorInterno();
    if (interno != null && await interno.maybePop()) return;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.practica;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF141725),
        body: Column(
          children: [
            Material(
              color: const Color(0xFF141725),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC2ADFF),
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text(
                          'Prácticas',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${p.numero} · ${p.titulo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF3F0FF)),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              // La barra ya ocupa el área de estado: la práctica no la repite.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: KeyedSubtree(
                  key: _zona,
                  child: p.construir!(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
