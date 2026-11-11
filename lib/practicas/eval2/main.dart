import 'package:flutter/material.dart';

import 'presentation/screens/screens.dart';

void main() => runApp(const MediConnectApp());

class MediConnectApp extends StatelessWidget {
  const MediConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
      ),
      home: const LoginScreen(),
    );
  }
}
