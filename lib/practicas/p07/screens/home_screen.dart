import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/banner_conexion.dart';
import 'dispositivos_screen.dart';
import 'reportes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _vista = 0;

  @override
  Widget build(BuildContext context) {
    final actual = context.watch<AuthService>().actual!;
    final admin = actual.rol == 'admin';
    final titulo = admin
        ? const ['Asignados a mí', 'Todos los tickets', 'Dispositivos'][_vista]
        : actual.rol == 'agente'
        ? 'Tickets asignados'
        : 'Mis tickets';
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthService>().salir(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: admin
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    child: Center(child: Text('Administrador')),
                  ),
                  for (final (i, texto, icono) in [
                    (0, 'Asignados a mí', Icons.assignment_ind_outlined),
                    (1, 'Todos los tickets', Icons.list_alt),
                    (2, 'Dispositivos', Icons.devices),
                  ])
                    ListTile(
                      selected: _vista == i,
                      leading: Icon(icono),
                      title: Text(texto),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _vista = i);
                      },
                    ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          const BannerConexion(),
          Expanded(
            child: admin && _vista == 2
                ? const DispositivosScreen()
                : ReportesScreen(
                    key: ValueKey('${actual.rol}-$_vista'),
                    asignadoA: admin && _vista == 0 ? 'admin' : null,
                  ),
          ),
        ],
      ),
    );
  }
}
