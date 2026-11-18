import '../atras_ceosmos.dart'; // [CEOSMOS]
import 'package:flutter/material.dart';

import 'consulta_web/consulta_web_page.dart';
import 'usuarios/app_database.dart';
import 'usuarios/usuarios_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConsultaWebApp());
}

class ConsultaWebApp extends StatelessWidget {
  const ConsultaWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onNavigationNotification: atrasManejadoPorCeosmos, // [CEOSMOS] Atrás vuelve a «Prácticas»
      title: 'ConsultaWeb',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const InicioPage(),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int _indice = 0;
  late final Future<AppDatabase> _baseDeDatos;

  @override
  void initState() {
    super.initState();
    _baseDeDatos = $FloorAppDatabase.databaseBuilder('p03_04_usuarios.db')
        .addMigrations([migracion1a2]) // [CEOSMOS] Práctica 4, caso 4 (campo correo)
        .build(); // [CEOSMOS] archivo SQLite propio de la práctica
  }

  @override
  void dispose() {
    _baseDeDatos.then<void>(
      (base) => base.close(),
      onError: (Object error, StackTrace stack) {},
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _indice,
          children: [
            const ConsultaWebPage(),
            UsuariosPage(baseDeDatos: _baseDeDatos),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() => _indice = indice),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Consulta'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Usuarios'),
        ],
      ),
    );
  }
}
