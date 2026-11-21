import '../atras_ceosmos.dart'; // [CEOSMOS]
import 'package:flutter/material.dart';

import 'presentation/screens/screens.dart';
import '../../core/theme/theme.dart';

void main() => runApp(const MediConnectApp());

class MediConnectApp extends StatelessWidget {
  const MediConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onNavigationNotification: atrasManejadoPorCeosmos, // [CEOSMOS] Atrás vuelve a «Prácticas»
      title: 'Citas de bienestar',
      debugShowCheckedModeBanner: false,
      // [CEOSMOS] Tema compartido del sistema de diseño (claro/oscuro).
      theme: CeosmosTema.claro,
      darkTheme: CeosmosTema.oscuro,
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}
