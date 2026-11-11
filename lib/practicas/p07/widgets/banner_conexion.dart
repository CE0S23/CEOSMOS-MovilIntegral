import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class BannerConexion extends StatefulWidget {
  const BannerConexion({super.key});

  @override
  State<BannerConexion> createState() => _BannerConexionState();
}

class _BannerConexionState extends State<BannerConexion> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _sinRed = false;

  @override
  void initState() {
    super.initState();
    final conexion = Connectivity();
    conexion.checkConnectivity().then(_actualizar);
    _subscription = conexion.onConnectivityChanged.listen(_actualizar);
  }

  void _actualizar(List<ConnectivityResult> resultados) {
    if (mounted) {
      setState(() => _sinRed = resultados.contains(ConnectivityResult.none));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _sinRed
      ? Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.errorContainer,
          padding: const EdgeInsets.all(10),
          child: const Row(
            children: [
              Icon(Icons.wifi_off),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sin conexión. Los cambios pueden quedar pendientes.',
                ),
              ),
            ],
          ),
        )
      : const SizedBox.shrink();
}
