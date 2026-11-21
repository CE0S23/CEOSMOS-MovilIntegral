import 'package:flutter/material.dart';

import 'servicio_web.dart';
import '../../../ui/widgets.dart' show Aviso;

class ConsultaWebPage extends StatefulWidget {
  const ConsultaWebPage({super.key});

  @override
  State<ConsultaWebPage> createState() => _ConsultaWebPageState();
}

class _ConsultaWebPageState extends State<ConsultaWebPage> {
  final _servicio = ServicioWeb();
  bool _consultando = false;
  String? _resultado;
  String? _error;

  Future<void> _consultar() async {
    setState(() {
      _consultando = true;
      _resultado = null;
      _error = null;
    });
    try {
      final resultado = await _servicio.consultar();
      if (!mounted) return;
      setState(() => _resultado = resultado);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No fue posible obtener la información.');
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Consulta de información',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _consultando ? null : _consultar,
            child: const Text('CONSULTAR'),
          ),
          const SizedBox(height: 16),
          if (_consultando)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Consultando...'),
              ],
            ),
          if (_error != null)
            Aviso(_error!), // [CEOSMOS] ícono + texto
          if (_resultado != null)
            Expanded(
              child: SingleChildScrollView(child: SelectableText(_resultado!)),
            ),
        ],
      ),
    );
  }
}
