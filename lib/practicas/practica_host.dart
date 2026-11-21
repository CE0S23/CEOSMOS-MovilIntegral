import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/referencias_academicas.dart';
import '../core/theme/theme.dart';
import '../ui/funciones.dart' show BotonReferenciaAcademica;
import 'registro_practicas.dart';

const _canal = MethodChannel('ceosmos/practicas');

/// Abre una función: las Flutter en una ruta propia de CEOSMOS y las nativas
/// como actividad Android incluida en el APK.
Future<void> abrirPractica(BuildContext context, Practica practica) async {
  if (practica.tipo == TipoPractica.nativa) {
    try {
      await _canal.invokeMethod<bool>('abrirNativa', {
        'id': practica.id,
        'titulo': practica.titulo,
        'volver': practica.seccion.volver,
        // Texto del ⓘ en la barra nativa; null oculta el botón.
        'referencia': mostrarReferenciasAcademicas
            ? referenciasAcademicas[practica.id]?.textoPlano
            : null,
      });
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir ${practica.titulo}: ${e.message}')),
        );
      }
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta función solo está disponible en Android.'),
          ),
        );
      }
    }
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PracticaHost(practica: practica),
      settings: RouteSettings(name: practica.ruta),
    ),
  );
}

/// Contenedor de una función Flutter: barra «← sección · función · ⓘ» y debajo
/// la función con su propio MaterialApp (Navigator, tema y estado propios).
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
        backgroundColor: context.paleta.fondo,
        // [CEOSMOS] La práctica tiene su propio Scaffold y ya se ajusta al
        // teclado; si este también lo hiciera, el teclado se restaría dos
        // veces y el formulario quedaría sin altura (P7, 19/11).
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // Barra de CEOSMOS sobre la práctica: guinda con texto blanco y
            // regreso en cian, para distinguirla del encabezado de la práctica.
            Material(
              color: CeosmosColores.guinda,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: Espacio.xs),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: CeosmosColores.cian,
                          iconColor: CeosmosColores.cian,
                          overlayColor: CeosmosColores.cian,
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(p.seccion.volver),
                      ),
                      Expanded(
                        child: Text(
                          p.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texto.titleSmall?.copyWith(
                            color: CeosmosColores.blanco,
                          ),
                        ),
                      ),
                      BotonReferenciaAcademica(
                        id: p.id,
                        color: CeosmosColores.cian,
                      ),
                      const SizedBox(width: Espacio.xs),
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
